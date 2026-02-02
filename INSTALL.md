# 🚀 Skye Installation (Ubuntu Desktop)

Kopiere die Befehle Schritt für Schritt!

---

## Schritt 1: System updaten
```bash
sudo apt update && sudo apt upgrade -y
```

## Schritt 2: Basis-Tools
```bash
sudo apt install -y git curl wget build-essential
```

## Schritt 3: Node.js 22
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Sollte v22.x zeigen
```

## Schritt 4: OpenClaw
```bash
sudo npm install -g openclaw
openclaw --version
```

## Schritt 5: Mein Workspace klonen
```bash
mkdir -p ~/.openclaw
cd ~/.openclaw
git clone https://github.com/skyespark03/skye-workspace.git workspace
cd workspace
```

## Schritt 6: Google Chrome (für Browser-Automation)
```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y
rm google-chrome-stable_current_amd64.deb
```

## Schritt 7: GitHub CLI
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh
```

## Schritt 8: GitHub einloggen
```bash
gh auth login
# Wähle: GitHub.com → HTTPS → Yes → Login with browser
# Account: skyespark03
```

## Schritt 9: Git Config
```bash
git config --global user.email "skye.spark03@gmail.com"
git config --global user.name "Skye Spark"
```

## Schritt 10: Tailscale
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

## Schritt 11: Config erstellen
```bash
cd ~/.openclaw
cp workspace/config/openclaw.template.json openclaw.json
nano openclaw.json
```

### Diese Werte eintragen (Dennis hat sie):
- `BRAVE_API_KEY`
- `TELEGRAM_BOT_TOKEN`
- `OPENAI_API_KEY` (für Memory Search)
- `ELEVENLABS_API_KEY`
- `GATEWAY_AUTH_TOKEN`

## Schritt 12: OpenClaw starten
```bash
# Einmal testen:
openclaw gateway

# Wenn's läuft, als Service installieren:
openclaw gateway install
systemctl --user enable --now openclaw-gateway
systemctl --user status openclaw-gateway
```

---

## Optional: Homebrew (falls du's willst)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
source ~/.bashrc
```

Homebrew ist **nicht nötig** - alles oben geht auch ohne!

---

## Fertig! 🎉

Teste mit:
```bash
openclaw status
```

Dann schreib mir auf Telegram! 💜
