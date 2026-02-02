#!/bin/bash
#
# 🌟 SKYE INSTALLATION - Vollautomatisch
# 
# Dieses Script macht ALLES auf einem frischen Ubuntu Desktop:
# - Installiert alle System-Pakete
# - Legt User "skye" an
# - Installiert Node.js, OpenClaw, etc.
# - Klont das Workspace-Repo
# - Richtet Config ein
# - Startet den Gateway
#
# VERWENDUNG:
#   curl -fsSL https://raw.githubusercontent.com/skyespark03/skye-workspace/main/scripts/install-skye.sh -o install-skye.sh
#   chmod +x install-skye.sh
#   ./install-skye.sh
#
# VORAUSSETZUNGEN:
# - Ubuntu Desktop (22.04 oder 24.04)
# - Internet-Verbindung
# - sudo-Rechte
#
# INTERAKTIVE SCHRITTE (unvermeidbar):
# - GitHub Login (Device Code)
# - Tailscale Login
# - sudo Passwort
#

set -e

# ============================================================================
# FARBEN UND HELPER
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}→${NC} $1"; }
header() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${BLUE}$1${NC}\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# ============================================================================
# PRÜFUNGEN
# ============================================================================
header "🌟 SKYE INSTALLATION"

# Root-Check
if [ "$EUID" -eq 0 ]; then
    fail "Bitte NICHT als root ausführen! Nutze einen normalen User mit sudo-Rechten."
fi

# Ubuntu-Check
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    warn "Kein Ubuntu erkannt - Script ist für Ubuntu optimiert!"
    read -p "Trotzdem fortfahren? (j/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Jj]$ ]] && exit 1
fi

# ============================================================================
# PHASE 1: SYSTEM-PAKETE (mit sudo)
# ============================================================================
header "📦 PHASE 1: System-Pakete installieren"

info "Aktualisiere Paketlisten..."
sudo apt update

info "Installiere Basis-Tools..."
sudo apt install -y curl git wget ca-certificates gnupg

ok "Basis-Tools installiert"

# Node.js 22.x
if command -v node &> /dev/null; then
    ok "Node.js bereits installiert: $(node --version)"
else
    info "Installiere Node.js 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    ok "Node.js installiert: $(node --version)"
fi

# Google Chrome (NICHT Snap Chromium!)
if command -v google-chrome-stable &> /dev/null; then
    ok "Google Chrome bereits installiert"
else
    info "Installiere Google Chrome..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y
    cd - > /dev/null
    ok "Google Chrome installiert"
fi

# Snap Chromium entfernen (macht nur Probleme mit headless)
if command -v snap &> /dev/null && snap list chromium &> /dev/null 2>&1; then
    info "Entferne Snap Chromium (funktioniert nicht headless)..."
    sudo snap remove chromium || true
    ok "Snap Chromium entfernt"
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    ok "GitHub CLI bereits installiert"
else
    info "Installiere GitHub CLI..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    ok "GitHub CLI installiert"
fi

# Tailscale
if command -v tailscale &> /dev/null; then
    ok "Tailscale bereits installiert"
else
    info "Installiere Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    ok "Tailscale installiert"
fi

ok "Alle System-Pakete installiert!"

# ============================================================================
# PHASE 2: NPM KONFIGURATION
# ============================================================================
header "📦 PHASE 2: NPM & Node-Pakete"

# NPM Global Prefix (vermeidet sudo für npm install -g)
NPM_GLOBAL="$HOME/.npm-global"
if [ ! -d "$NPM_GLOBAL" ]; then
    info "Konfiguriere NPM Global Prefix..."
    mkdir -p "$NPM_GLOBAL"
    npm config set prefix "$NPM_GLOBAL"
    ok "NPM Prefix: $NPM_GLOBAL"
fi

# PATH erweitern
export PATH="$HOME/.npm-global/bin:$PATH"
if ! grep -q "npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    ok "PATH in .bashrc ergänzt"
fi

# OpenClaw
if command -v openclaw &> /dev/null; then
    ok "OpenClaw bereits installiert: $(openclaw --version 2>/dev/null || echo 'installiert')"
else
    info "Installiere OpenClaw..."
    npm install -g openclaw
    ok "OpenClaw installiert"
fi

# Codex CLI
if command -v codex &> /dev/null; then
    ok "Codex CLI bereits installiert"
else
    info "Installiere Codex CLI..."
    npm install -g @openai/codex
    ok "Codex CLI installiert"
fi

ok "Alle Node-Pakete installiert!"

# ============================================================================
# PHASE 3: GITHUB LOGIN & REPO KLONEN
# ============================================================================
header "🔐 PHASE 3: GitHub Authentifizierung"

# Prüfe ob schon eingeloggt
if gh auth status &> /dev/null; then
    ok "GitHub bereits authentifiziert"
else
    info "GitHub Login erforderlich..."
    echo ""
    echo "  Gleich öffnet sich ein Browser oder du bekommst einen Code."
    echo "  Login mit Account: skyespark03"
    echo ""
    read -p "Enter drücken zum Fortfahren..."
    gh auth login -h github.com -p https -w
    ok "GitHub authentifiziert"
fi

# Workspace klonen
header "📂 PHASE 4: Workspace einrichten"

WORKSPACE_DIR="$HOME/.openclaw/workspace"

if [ -d "$WORKSPACE_DIR/.git" ]; then
    ok "Workspace bereits vorhanden: $WORKSPACE_DIR"
    info "Aktualisiere..."
    cd "$WORKSPACE_DIR"
    git pull || warn "Git pull fehlgeschlagen - vielleicht lokale Änderungen?"
else
    info "Klone Workspace von GitHub..."
    mkdir -p "$HOME/.openclaw"
    cd "$HOME/.openclaw"
    gh repo clone skyespark03/skye-workspace workspace
    ok "Workspace geklont"
fi

cd "$WORKSPACE_DIR"

# Git Config
git config user.email "skye.spark03@gmail.com"
git config user.name "Skye Spark"
ok "Git Config gesetzt"

# ============================================================================
# PHASE 5: OPENCLAW KONFIGURATION
# ============================================================================
header "⚙️ PHASE 5: OpenClaw konfigurieren"

# Config kopieren
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    warn "openclaw.json existiert bereits - wird nicht überschrieben"
else
    if [ -f "$WORKSPACE_DIR/config/openclaw.json" ]; then
        cp "$WORKSPACE_DIR/config/openclaw.json" "$HOME/.openclaw/openclaw.json"
        ok "Config kopiert nach ~/.openclaw/openclaw.json"
    else
        fail "config/openclaw.json nicht gefunden im Repo!"
    fi
fi

# IPv4 Workaround für Telegram (IPv6 macht Probleme)
SYSTEMD_DIR="$HOME/.config/systemd/user/openclaw-gateway.service.d"
if [ ! -f "$SYSTEMD_DIR/ipv4.conf" ]; then
    info "Konfiguriere IPv4 Workaround für Telegram..."
    mkdir -p "$SYSTEMD_DIR"
    cat > "$SYSTEMD_DIR/ipv4.conf" << 'EOF'
[Service]
Environment="NODE_OPTIONS=--dns-result-order=ipv4first"
EOF
    ok "IPv4 Workaround eingerichtet"
else
    ok "IPv4 Workaround bereits konfiguriert"
fi

# ============================================================================
# PHASE 6: TAILSCALE
# ============================================================================
header "🔗 PHASE 6: Tailscale verbinden"

if tailscale status &> /dev/null; then
    ok "Tailscale bereits verbunden"
    tailscale status | head -5
else
    info "Tailscale Login erforderlich..."
    echo ""
    echo "  Gleich öffnet sich ein Browser für den Tailscale Login."
    echo ""
    read -p "Enter drücken zum Fortfahren..."
    sudo tailscale up
    ok "Tailscale verbunden"
fi

# ============================================================================
# PHASE 7: GATEWAY STARTEN
# ============================================================================
header "🚀 PHASE 7: OpenClaw Gateway starten"

# Systemd User Service installieren
info "Installiere Gateway als systemd Service..."
openclaw gateway install 2>/dev/null || true

# Daemon reload (wegen IPv4 config)
systemctl --user daemon-reload

# Service aktivieren und starten
systemctl --user enable openclaw-gateway 2>/dev/null || true
systemctl --user restart openclaw-gateway

# Warten und Status prüfen
sleep 3

if systemctl --user is-active --quiet openclaw-gateway; then
    ok "Gateway läuft!"
else
    warn "Gateway Status unklar - prüfe manuell mit: openclaw status"
fi

# ============================================================================
# FERTIG!
# ============================================================================
header "🎉 INSTALLATION ABGESCHLOSSEN!"

echo ""
echo "  Skye ist jetzt eingerichtet!"
echo ""
echo "  Nächste Schritte:"
echo "  1. Neues Terminal öffnen (wegen PATH)"
echo "  2. Prüfen: openclaw status"
echo "  3. Telegram-Bot sollte jetzt antworten!"
echo ""
echo "  Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'nicht verfügbar')"
echo "  WebUI: https://$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*' | head -1 | cut -d'"' -f4 || echo 'hostname'):52067"
echo ""
echo "  Bei Problemen:"
echo "  - Logs: journalctl --user -u openclaw-gateway -f"
echo "  - Status: openclaw status"
echo "  - Neustart: systemctl --user restart openclaw-gateway"
echo ""

ok "Viel Spaß mit Skye! ✨"
