#!/bin/bash
#
# 🌟 Skye Setup Script
# Stellt alle Abhängigkeiten und Konfigurationen wieder her
#
# Verwendung: ./scripts/setup-skye.sh
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

# 1. Google Chrome
if command -v google-chrome-stable &> /dev/null; then
    ok "Google Chrome bereits installiert"
else
    echo "Installing Google Chrome..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y
    ok "Google Chrome installiert"
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

# 4. Codex CLI
if command -v codex &> /dev/null; then
    ok "Codex CLI bereits installiert"
else
    echo "Installing Codex CLI..."
    npm install -g @openai/codex
    ok "Codex CLI installiert"
fi

echo ""
echo "🔧 Konfiguration..."
echo ""

# 5. OpenClaw Config kopieren (falls vorhanden)
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

# 6. IPv4 Workaround für Telegram
SYSTEMD_DIR="$HOME/.config/systemd/user/openclaw-gateway.service.d"
if [ -f "$SYSTEMD_DIR/ipv4.conf" ]; then
    ok "IPv4 Workaround bereits konfiguriert"
else
    mkdir -p "$SYSTEMD_DIR"
    cat > "$SYSTEMD_DIR/ipv4.conf" << 'EOF'
[Service]
Environment="NODE_OPTIONS=--dns-result-order=ipv4first"
EOF
    ok "IPv4 Workaround eingerichtet"
fi

# 7. Git Config
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
