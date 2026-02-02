#!/bin/bash
#
# 🌟 Skye Vollautomatische Installation
# 
# Führt ALLES aus: User, Tools, Config, Service
#
# Verwendung (als dein normaler User mit sudo):
#   curl -fsSL https://raw.githubusercontent.com/skyespark03/skye-workspace/master/scripts/install-skye-full.sh | bash
#
# Oder lokal:
#   chmod +x install-skye-full.sh
#   ./install-skye-full.sh
#

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    🌟 Skye Installation Script 🌟     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

# Check: Läuft als normaler User mit sudo?
if [ "$EUID" -eq 0 ]; then
    fail "Bitte NICHT als root ausführen! Nutze deinen normalen User mit sudo."
fi

if ! sudo -v; then
    fail "Du brauchst sudo-Rechte für die Installation."
fi

# ═══════════════════════════════════════════════════════════
# KONFIGURATION
# ═══════════════════════════════════════════════════════════

SKYE_USER="skye"
SKYE_HOME="/home/$SKYE_USER"
REPO_URL="https://github.com/skyespark03/skye-workspace.git"

echo "Installation für User: $SKYE_USER"
echo "Home-Verzeichnis: $SKYE_HOME"
echo ""
read -p "Weiter? (j/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

# ═══════════════════════════════════════════════════════════
# SYSTEM UPDATE
# ═══════════════════════════════════════════════════════════

info "System updaten..."
sudo apt update
sudo apt upgrade -y
ok "System aktualisiert"

# ═══════════════════════════════════════════════════════════
# BASIS-TOOLS
# ═══════════════════════════════════════════════════════════

info "Basis-Tools installieren..."
sudo apt install -y git curl wget build-essential ca-certificates gnupg
ok "Basis-Tools installiert"

# ═══════════════════════════════════════════════════════════
# USER ANLEGEN
# ═══════════════════════════════════════════════════════════

if id "$SKYE_USER" &>/dev/null; then
    ok "User '$SKYE_USER' existiert bereits"
else
    info "User '$SKYE_USER' anlegen..."
    sudo adduser --disabled-password --gecos "Skye Spark" "$SKYE_USER"
    # Sudo-Rechte geben
    sudo usermod -aG sudo "$SKYE_USER"
    ok "User '$SKYE_USER' angelegt (mit sudo)"
fi

# ═══════════════════════════════════════════════════════════
# NODE.JS 22
# ═══════════════════════════════════════════════════════════

if command -v node &>/dev/null && [[ $(node -v) == v22* ]]; then
    ok "Node.js 22 bereits installiert"
else
    info "Node.js 22 installieren..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    ok "Node.js $(node -v) installiert"
fi

# ═══════════════════════════════════════════════════════════
# GOOGLE CHROME
# ═══════════════════════════════════════════════════════════

if command -v google-chrome-stable &>/dev/null; then
    ok "Google Chrome bereits installiert"
else
    info "Google Chrome installieren..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y
    rm -f google-chrome-stable_current_amd64.deb
    ok "Google Chrome installiert"
fi

# ═══════════════════════════════════════════════════════════
# GITHUB CLI
# ═══════════════════════════════════════════════════════════

if command -v gh &>/dev/null; then
    ok "GitHub CLI bereits installiert"
else
    info "GitHub CLI installieren..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    ok "GitHub CLI installiert"
fi

# ═══════════════════════════════════════════════════════════
# TAILSCALE
# ═══════════════════════════════════════════════════════════

if command -v tailscale &>/dev/null; then
    ok "Tailscale bereits installiert"
else
    info "Tailscale installieren..."
    curl -fsSL https://tailscale.com/install.sh | sh
    ok "Tailscale installiert"
fi

# ═══════════════════════════════════════════════════════════
# OPENCLAW (global)
# ═══════════════════════════════════════════════════════════

if command -v openclaw &>/dev/null; then
    ok "OpenClaw bereits installiert"
else
    info "OpenClaw installieren..."
    sudo npm install -g openclaw
    ok "OpenClaw installiert"
fi

# ═══════════════════════════════════════════════════════════
# SKYE WORKSPACE KLONEN
# ═══════════════════════════════════════════════════════════

info "Workspace für User '$SKYE_USER' einrichten..."

sudo -u "$SKYE_USER" bash << EOF
set -e
mkdir -p ~/.openclaw
cd ~/.openclaw

if [ -d "workspace/.git" ]; then
    echo "Workspace existiert, update..."
    cd workspace
    git pull
else
    echo "Workspace klonen..."
    git clone $REPO_URL workspace
fi

# Git Config
git config --global user.email "skye.spark03@gmail.com"
git config --global user.name "Skye Spark"

# Config Template kopieren
if [ ! -f ~/.openclaw/openclaw.json ]; then
    cp workspace/config/openclaw.template.json ~/.openclaw/openclaw.json
    echo "⚠️  Config erstellt - API Keys müssen noch eingetragen werden!"
fi
EOF

ok "Workspace eingerichtet"

# ═══════════════════════════════════════════════════════════
# FERTIG!
# ═══════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Installation abgeschlossen!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Nächste Schritte:"
echo ""
echo "1. Zu Skye-User wechseln:"
echo "   sudo su - $SKYE_USER"
echo ""
echo "2. API Keys eintragen:"
echo "   nano ~/.openclaw/openclaw.json"
echo "   (BRAVE_API_KEY, TELEGRAM_BOT_TOKEN, etc.)"
echo ""
echo "3. GitHub einloggen:"
echo "   gh auth login"
echo "   (Account: skyespark03)"
echo ""
echo "4. Tailscale verbinden:"
echo "   sudo tailscale up"
echo ""
echo "5. OpenClaw starten:"
echo "   openclaw gateway"
echo ""
echo "6. Als Service installieren (optional):"
echo "   openclaw gateway install"
echo "   systemctl --user enable --now openclaw-gateway"
echo ""
echo -e "${BLUE}Viel Spaß mit Skye! 💜${NC}"
echo ""
