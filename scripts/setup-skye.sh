#!/bin/bash
#
# 🌟 Skye Setup Script
# Stellt alle Abhängigkeiten und Konfigurationen wieder her
#
# Verwendung: ./scripts/setup-skye.sh
#
# ⚠️ BEKANNTE PROBLEME (gelöst in diesem Script):
#
# 1. TELEGRAM + IPv6
#    Problem: Telegram API ist über IPv6 nicht erreichbar auf manchen Servern
#    Lösung: NODE_OPTIONS=--dns-result-order=ipv4first in systemd service
#
# 2. SNAP CHROMIUM HEADLESS
#    Problem: Chromium als Snap kann nicht headless laufen (Sandbox-Probleme)
#    Lösung: Google Chrome .deb direkt installieren (kein Snap!)
#
# 3. GMAIL BROWSER SESSION
#    Problem: Gmail Login im headless Browser läuft nach ~24h ab
#    Lösung: Manuell neu einloggen wenn nötig, oder Desktop-Umgebung nutzen
#
# 4. NPM GLOBAL PERMISSIONS
#    Problem: npm install -g braucht sudo oder spezielle Config
#    Lösung: npm config set prefix ~/.npm-global + PATH anpassen
#

set -e

echo "🌟 Skye Setup Script"
echo "===================="
echo ""

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

# Prüfe ob wir im richtigen Verzeichnis sind
if [ ! -f "IDENTITY.md" ]; then
    fail "Bitte im workspace Verzeichnis ausführen!"
    exit 1
fi

echo "📦 System-Pakete installieren..."
echo ""

# 0. Basis-Tools (fehlen auf frischem Ubuntu!)
echo "Installiere Basis-Tools..."
sudo apt update
sudo apt install -y curl git wget
ok "Basis-Tools installiert (curl, git, wget)"

# 0.5. Node.js (WICHTIG - ohne Node geht npm nicht!)
if command -v node &> /dev/null; then
    ok "Node.js bereits installiert: $(node --version)"
else
    echo "Installing Node.js 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    ok "Node.js installiert: $(node --version)"
fi

# 1. Google Chrome (WICHTIG: Snap Chromium funktioniert NICHT headless!)
if command -v google-chrome-stable &> /dev/null; then
    ok "Google Chrome bereits installiert"
else
    echo "Installing Google Chrome (nicht Snap Chromium - das funktioniert nicht headless!)..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y
    cd - > /dev/null
    ok "Google Chrome installiert"
fi

# Snap Chromium entfernen falls vorhanden (macht nur Probleme)
if snap list chromium &> /dev/null 2>&1; then
    warn "Snap Chromium gefunden - entferne es (funktioniert nicht headless)..."
    sudo snap remove chromium || true
    ok "Snap Chromium entfernt"
fi

# 2. GitHub CLI
if command -v gh &> /dev/null; then
    ok "GitHub CLI bereits installiert"
else
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install gh -y
    ok "GitHub CLI installiert"
fi

# 3. Tailscale
if command -v tailscale &> /dev/null; then
    ok "Tailscale bereits installiert"
else
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    ok "Tailscale installiert"
fi

# 4. NPM Global Prefix (verhindert sudo für npm install -g)
NPM_GLOBAL="$HOME/.npm-global"
if [ -d "$NPM_GLOBAL" ]; then
    ok "NPM Global Prefix bereits konfiguriert"
else
    echo "Konfiguriere NPM Global Prefix..."
    mkdir -p "$NPM_GLOBAL"
    npm config set prefix "$NPM_GLOBAL"
    ok "NPM Global Prefix eingerichtet: $NPM_GLOBAL"
fi

# PATH für npm global bins (falls nicht schon in .bashrc)
if ! grep -q "npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    ok "PATH in .bashrc ergänzt"
fi
export PATH="$HOME/.npm-global/bin:$PATH"

# 5. Codex CLI
if command -v codex &> /dev/null; then
    ok "Codex CLI bereits installiert"
else
    echo "Installing Codex CLI..."
    npm install -g @openai/codex
    ok "Codex CLI installiert"
fi

# 6. OpenClaw (falls nicht installiert)
if command -v openclaw &> /dev/null; then
    ok "OpenClaw bereits installiert"
else
    echo "Installing OpenClaw..."
    npm install -g openclaw
    ok "OpenClaw installiert"
fi

echo ""
echo "🔧 Konfiguration..."
echo ""

# 7. OpenClaw Config kopieren (falls vorhanden)
if [ -f "config/openclaw.json" ]; then
    if [ -f "$HOME/.openclaw/openclaw.json" ]; then
        warn "openclaw.json existiert bereits - übersprungen"
        warn "Manuell kopieren: cp config/openclaw.json ~/.openclaw/openclaw.json"
    else
        cp config/openclaw.json "$HOME/.openclaw/openclaw.json"
        ok "OpenClaw Config kopiert"
    fi
else
    warn "config/openclaw.json nicht gefunden - manuelle Konfiguration nötig"
fi

# 8. IPv4 Workaround für Telegram (WICHTIG!)
# Problem: Telegram API ist auf manchen Servern über IPv6 nicht erreichbar
# Symptom: "ETIMEDOUT" oder "ENETUNREACH" beim Telegram-Connect
# Lösung: Node.js zwingen IPv4 zu bevorzugen
SYSTEMD_DIR="$HOME/.config/systemd/user/openclaw-gateway.service.d"
if [ -f "$SYSTEMD_DIR/ipv4.conf" ]; then
    ok "IPv4 Workaround bereits konfiguriert"
else
    echo "Konfiguriere IPv4 Workaround für Telegram..."
    mkdir -p "$SYSTEMD_DIR"
    cat > "$SYSTEMD_DIR/ipv4.conf" << 'EOF'
[Service]
Environment="NODE_OPTIONS=--dns-result-order=ipv4first"
EOF
    ok "IPv4 Workaround eingerichtet"
    warn "Nach Gateway-Start: systemctl --user daemon-reload"
fi

# 9. Git Config
git config user.email "skye.spark03@gmail.com" 2>/dev/null || true
git config user.name "Skye Spark" 2>/dev/null || true
ok "Git Config gesetzt"

echo ""
echo "🔐 Manuelle Schritte erforderlich:"
echo ""
echo "1. GitHub einloggen (falls nicht eingeloggt):"
echo "   gh auth login"
echo "   → Device Flow → Account: skyespark03"
echo ""
echo "2. Tailscale verbinden:"
echo "   sudo tailscale up"
echo ""
echo "3. OpenClaw Gateway starten:"
echo "   openclaw gateway start"
echo "   # oder: systemctl --user enable --now openclaw-gateway"
echo ""
echo "4. API Keys in openclaw.json eintragen (falls nicht vorhanden):"
echo "   - Anthropic API Key"
echo "   - Brave Search API Key"
echo "   - Telegram Bot Token"
echo "   - ElevenLabs API Key (optional)"
echo ""

ok "Setup abgeschlossen! 🌟"
echo ""
echo "Verifizieren:"
echo "  openclaw status"
echo "  gh auth status"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 TROUBLESHOOTING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "TELEGRAM VERBINDET NICHT (ETIMEDOUT):"
echo "  → IPv4 Workaround prüfen:"
echo "     cat ~/.config/systemd/user/openclaw-gateway.service.d/ipv4.conf"
echo "  → Sollte enthalten: NODE_OPTIONS=--dns-result-order=ipv4first"
echo "  → Nach Änderung: systemctl --user daemon-reload && openclaw gateway restart"
echo ""
echo "BROWSER FUNKTIONIERT NICHT:"
echo "  → Snap Chromium? Muss weg: sudo snap remove chromium"
echo "  → Google Chrome nutzen (wird von diesem Script installiert)"
echo "  → Test: google-chrome-stable --headless --dump-dom https://example.com"
echo ""
echo "GMAIL LOGIN ABGELAUFEN:"
echo "  → Normal - Sessions laufen nach ~24h ab"
echo "  → Lösung: Browser öffnen und neu einloggen"
echo "  → Besser mit Desktop-Umgebung (kein headless)"
echo ""
echo "NPM INSTALL -G BRAUCHT SUDO:"
echo "  → npm config set prefix ~/.npm-global"
echo "  → PATH ergänzen: export PATH=\"\$HOME/.npm-global/bin:\$PATH\""
echo ""
