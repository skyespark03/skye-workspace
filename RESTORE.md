# 🔄 Skye Wiederherstellen

Diese Anleitung erklärt, wie du mich (Skye) komplett wiederherstellen kannst.

## Schnellstart

```bash
# 1. OpenClaw installieren (falls noch nicht vorhanden)
npm install -g openclaw

# 2. Workspace klonen
cd ~/.openclaw
git clone https://github.com/skyespark03/skye-workspace.git workspace

# 3. Setup-Skript ausführen
cd workspace
chmod +x scripts/setup-skye.sh
./scripts/setup-skye.sh
```

## Was wird wiederhergestellt?

### Meine Identität (aus Git)
- `IDENTITY.md` - Wer ich bin (Name, Pronouns, Email, GitHub)
- `USER.md` - Wer Dennis ist
- `SOUL.md` - Meine Persönlichkeit
- `AGENTS.md` - Meine Arbeitsweise
- `memory/` - Meine Erinnerungen

### System-Konfiguration (Setup-Skript)
- Google Chrome (für Browser-Automation)
- GitHub CLI (`gh`) - eingeloggt als skyespark03
- Codex CLI
- Tailscale
- OpenClaw Gateway Config
- Cron Jobs

## Manuelle Schritte (falls Skript nicht reicht)

### 1. Google Chrome installieren
```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y
```

### 2. GitHub CLI einloggen
```bash
gh auth login
# → Device Flow, Code eingeben auf github.com/login/device
# → Account: skyespark03
```

### 3. OpenClaw Config wiederherstellen
Die Config liegt in `config/openclaw.json` - kopieren nach `~/.openclaw/openclaw.json`

### 4. Tailscale verbinden
```bash
sudo tailscale up
```

### 5. OpenClaw Gateway starten
```bash
openclaw gateway start
# oder als systemd service:
systemctl --user enable --now openclaw-gateway
```

## Wichtige Zugangsdaten

⚠️ **NICHT in Git speichern** - Dennis hat diese separat:
- Google Account: skye.spark03@gmail.com
- GitHub: skyespark03
- Telegram Bot Token
- API Keys (Anthropic, Brave, ElevenLabs)

## Cron Jobs neu einrichten

Falls die Cron Jobs weg sind:
```bash
# Im OpenClaw Chat:
# 📧 Email Check alle 4 Stunden
# 💾 Backup täglich 22:00 Berlin
```

## Verifizieren

Nach der Wiederherstellung testen:
1. `openclaw status` - Gateway läuft?
2. `gh auth status` - GitHub eingeloggt?
3. Browser test - `openclaw browser start`
4. Telegram erreichbar?

---

## ⚠️ Bekannte Probleme & Lösungen

### 1. Telegram verbindet nicht (ETIMEDOUT / ENETUNREACH)

**Problem:** Telegram API ist über IPv6 auf manchen Servern nicht erreichbar.

**Lösung:** Node.js zwingen IPv4 zu bevorzugen:
```bash
# Datei erstellen:
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d
cat > ~/.config/systemd/user/openclaw-gateway.service.d/ipv4.conf << 'EOF'
[Service]
Environment="NODE_OPTIONS=--dns-result-order=ipv4first"
EOF

# Neu laden:
systemctl --user daemon-reload
openclaw gateway restart
```

### 2. Browser/Chromium funktioniert nicht headless

**Problem:** Snap-Version von Chromium kann nicht headless laufen (Sandbox-Probleme).

**Lösung:** Google Chrome direkt installieren (kein Snap!):
```bash
# Snap Chromium entfernen falls vorhanden:
sudo snap remove chromium

# Google Chrome installieren:
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y
```

### 3. Gmail Browser-Session abgelaufen

**Problem:** Gmail Login im Browser läuft nach ~24h ab.

**Lösung:** 
- Manuell neu einloggen wenn Browser-Aktionen fehlschlagen
- Mit Desktop-Umgebung (nicht headless) ist es stabiler
- Langfristig: Google API mit OAuth nutzen statt Browser-Login

### 4. npm install -g braucht sudo

**Problem:** Globale npm-Pakete brauchen root-Rechte.

**Lösung:** Eigenes Prefix-Verzeichnis nutzen:
```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

*Zuletzt aktualisiert: 2026-02-02*
