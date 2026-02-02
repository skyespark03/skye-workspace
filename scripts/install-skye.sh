#!/bin/bash
#
# 🌟 SKYE INSTALLATION - Vollautomatisch
# 
# Führt ALLES aus auf frischem Ubuntu Desktop:
# 1. Legt User "skye" an mit sudo-Rechten
# 2. Installiert alle Pakete
# 3. Klont das private Repo (nach GitHub Login)
# 4. Startet den Gateway
#
# VERWENDUNG (als root oder mit sudo):
#   curl -fsSL https://raw.githubusercontent.com/skyespark03/skye-workspace/main/scripts/install-skye.sh | sudo bash
#
# ODER nach manuellem Download:
#   sudo ./install-skye.sh
#
# INTERAKTIVE SCHRITTE (unvermeidbar):
# - GitHub Login (Device Code) - weil Repo privat ist
# - Tailscale Login
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
header() { 
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# ROOT CHECK
# ============================================================================
header "🌟 SKYE INSTALLATION"

if [ "$EUID" -ne 0 ]; then
    fail "Bitte als root ausführen: sudo ./install-skye.sh"
fi

# ============================================================================
# PHASE 1: USER ANLEGEN
# ============================================================================
header "👤 PHASE 1: User 'skye' anlegen"

if id "skye" &>/dev/null; then
    ok "User 'skye' existiert bereits"
else
    info "Lege User 'skye' an..."
    adduser --disabled-password --gecos "Skye Spark" skye
    ok "User 'skye' angelegt"
fi

# sudo ohne Passwort
if [ -f /etc/sudoers.d/skye ]; then
    ok "sudo-Rechte bereits konfiguriert"
else
    info "Konfiguriere sudo-Rechte..."
    echo 'skye ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/skye
    chmod 0440 /etc/sudoers.d/skye
    visudo -cf /etc/sudoers.d/skye || fail "sudoers Syntax-Fehler!"
    ok "sudo ohne Passwort für 'skye' eingerichtet"
fi

# ============================================================================
# PHASE 2: SYSTEM-PAKETE (als root)
# ============================================================================
header "📦 PHASE 2: System-Pakete installieren"

info "Aktualisiere Paketlisten..."
apt update

info "Installiere Basis-Tools..."
apt install -y curl git wget ca-certificates gnupg build-essential

ok "Basis-Tools installiert"

# Node.js 22.x
if command -v node &> /dev/null; then
    ok "Node.js bereits installiert: $(node --version)"
else
    info "Installiere Node.js 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt install -y nodejs
    ok "Node.js installiert: $(node --version)"
fi

# Google Chrome (NICHT Snap!)
if command -v google-chrome-stable &> /dev/null; then
    ok "Google Chrome bereits installiert"
else
    info "Installiere Google Chrome..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg -i google-chrome-stable_current_amd64.deb || apt --fix-broken install -y
    cd - > /dev/null
    ok "Google Chrome installiert"
fi

# Snap Chromium entfernen
if command -v snap &> /dev/null && snap list chromium &> /dev/null 2>&1; then
    info "Entferne Snap Chromium..."
    snap remove chromium || true
    ok "Snap Chromium entfernt"
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    ok "GitHub CLI bereits installiert"
else
    info "Installiere GitHub CLI..."
    mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt update
    apt install -y gh
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
# PHASE 3-7: ALS USER SKYE AUSFÜHREN
# ============================================================================
header "🔄 Wechsle zu User 'skye' für weitere Installation..."

# Erstelle temporäres Script für User skye
SKYE_SCRIPT=$(mktemp)
cat > "$SKYE_SCRIPT" << 'SKYE_SETUP_SCRIPT'
#!/bin/bash
set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}→${NC} $1"; }
header() { 
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# NPM KONFIGURATION
# ============================================================================
header "📦 PHASE 3: NPM konfigurieren"

NPM_GLOBAL="$HOME/.npm-global"
if [ ! -d "$NPM_GLOBAL" ]; then
    info "Konfiguriere NPM Global Prefix..."
    mkdir -p "$NPM_GLOBAL"
    npm config set prefix "$NPM_GLOBAL"
    ok "NPM Prefix: $NPM_GLOBAL"
else
    ok "NPM Global Prefix bereits konfiguriert"
fi

# PATH erweitern
export PATH="$HOME/.npm-global/bin:$PATH"
if ! grep -q "npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    ok "PATH in .bashrc ergänzt"
fi

# OpenClaw
if command -v openclaw &> /dev/null; then
    ok "OpenClaw bereits installiert"
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

# ============================================================================
# GITHUB LOGIN
# ============================================================================
header "🔐 PHASE 4: GitHub Login"

if gh auth status &> /dev/null; then
    ok "GitHub bereits authentifiziert"
else
    info "GitHub Login erforderlich (Repo ist privat!)"
    echo ""
    echo "  Account: skyespark03"
    echo "  Es öffnet sich ein Browser oder du bekommst einen Code."
    echo ""
    read -p "  Enter drücken zum Fortfahren..."
    gh auth login -h github.com -p https -w
    ok "GitHub authentifiziert"
fi

# ============================================================================
# WORKSPACE KLONEN
# ============================================================================
header "📂 PHASE 5: Workspace klonen"

WORKSPACE_DIR="$HOME/.openclaw/workspace"

if [ -d "$WORKSPACE_DIR/.git" ]; then
    ok "Workspace bereits vorhanden"
    info "Aktualisiere..."
    cd "$WORKSPACE_DIR"
    git pull || warn "Git pull fehlgeschlagen"
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
# OPENCLAW KONFIGURATION
# ============================================================================
header "⚙️ PHASE 6: OpenClaw konfigurieren"

# Config kopieren
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    warn "openclaw.json existiert bereits"
else
    if [ -f "$WORKSPACE_DIR/config/openclaw.json" ]; then
        cp "$WORKSPACE_DIR/config/openclaw.json" "$HOME/.openclaw/openclaw.json"
        ok "Config kopiert"
    else
        fail "config/openclaw.json nicht im Repo gefunden!"
    fi
fi

# IPv4 Workaround für Telegram
SYSTEMD_DIR="$HOME/.config/systemd/user/openclaw-gateway.service.d"
if [ ! -f "$SYSTEMD_DIR/ipv4.conf" ]; then
    info "Konfiguriere IPv4 Workaround für Telegram..."
    mkdir -p "$SYSTEMD_DIR"
    cat > "$SYSTEMD_DIR/ipv4.conf" << 'IPVCONF'
[Service]
Environment="NODE_OPTIONS=--dns-result-order=ipv4first"
IPVCONF
    ok "IPv4 Workaround eingerichtet"
else
    ok "IPv4 Workaround bereits vorhanden"
fi

# ============================================================================
# TAILSCALE
# ============================================================================
header "🔗 PHASE 7: Tailscale verbinden"

if tailscale status &> /dev/null; then
    ok "Tailscale bereits verbunden"
else
    info "Tailscale Login erforderlich..."
    echo ""
    read -p "  Enter drücken zum Fortfahren..."
    sudo tailscale up
    ok "Tailscale verbunden"
fi

# ============================================================================
# GATEWAY STARTEN
# ============================================================================
header "🚀 PHASE 8: Gateway starten"

info "Installiere Gateway als systemd Service..."
openclaw gateway install 2>/dev/null || true

systemctl --user daemon-reload
systemctl --user enable openclaw-gateway 2>/dev/null || true
systemctl --user restart openclaw-gateway

sleep 3

if systemctl --user is-active --quiet openclaw-gateway; then
    ok "Gateway läuft!"
else
    warn "Gateway Status unklar"
fi

# ============================================================================
# FERTIG
# ============================================================================
header "🎉 INSTALLATION ABGESCHLOSSEN!"

echo ""
echo "  Skye ist eingerichtet!"
echo ""
echo "  Prüfen:  openclaw status"
echo "  Logs:    journalctl --user -u openclaw-gateway -f"
echo "  Neustart: systemctl --user restart openclaw-gateway"
echo ""
echo "  Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'nicht verfügbar')"
echo ""

ok "Fertig! ✨"
SKYE_SETUP_SCRIPT

chmod +x "$SKYE_SCRIPT"
chown skye:skye "$SKYE_SCRIPT"

# Als User skye ausführen
su - skye -c "bash $SKYE_SCRIPT"

# Cleanup
rm -f "$SKYE_SCRIPT"

header "✅ ALLES ERLEDIGT!"
echo ""
echo "  Du kannst dich jetzt als 'skye' einloggen:"
echo "    su - skye"
echo ""
echo "  Oder in einem neuen Terminal als skye arbeiten."
echo ""
