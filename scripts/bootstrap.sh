#!/bin/bash
#
# 🚀 Skye Bootstrap - Einmal kopieren, alles automatisch!
#
# ANLEITUNG:
# 1. Terminal öffnen
# 2. Diesen EINEN Befehl eingeben:
#    nano bootstrap.sh
# 3. Dieses ganze Script reinkopieren, speichern (Ctrl+O, Enter, Ctrl+X)
# 4. Ausführen:
#    chmod +x bootstrap.sh && ./bootstrap.sh
#

set -e

echo ""
echo "🚀 Skye Bootstrap"
echo "================="
echo ""

# Git installieren
echo "📦 Git installieren..."
sudo apt update
sudo apt install -y git curl

# GitHub CLI installieren
echo "📦 GitHub CLI installieren..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

# GitHub Login
echo ""
echo "🔐 GitHub Login (Account: skyespark03)"
echo ""
gh auth login

# Repo klonen
echo ""
echo "📥 Skye Workspace klonen..."
cd ~
if [ -d "skye-workspace" ]; then
    echo "Ordner existiert, update..."
    cd skye-workspace
    git pull
else
    git clone https://github.com/skyespark03/skye-workspace.git
    cd skye-workspace
fi

# Hauptskript ausführen
echo ""
echo "🌟 Hauptinstallation starten..."
chmod +x scripts/install-skye-full.sh
./scripts/install-skye-full.sh

echo ""
echo "🎉 Bootstrap fertig!"
