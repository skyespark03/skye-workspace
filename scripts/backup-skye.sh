#!/bin/bash
# Backup Script für Skye 🌟
# Erstellt ein vollständiges Backup des OpenClaw-Zustands

set -e

BACKUP_NAME="skye-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/tmp/${BACKUP_NAME}"
OPENCLAW_DIR="${HOME}/.openclaw"

echo "🌟 Skye Backup wird erstellt..."
echo ""

# Backup-Verzeichnis erstellen
mkdir -p "${BACKUP_DIR}"

# Wichtige Dateien/Ordner kopieren
echo "📦 Kopiere Config..."
cp "${OPENCLAW_DIR}/openclaw.json" "${BACKUP_DIR}/"

echo "📦 Kopiere Workspace..."
cp -r "${OPENCLAW_DIR}/workspace" "${BACKUP_DIR}/"

echo "📦 Kopiere Agents (Sessions & State)..."
cp -r "${OPENCLAW_DIR}/agents" "${BACKUP_DIR}/"

echo "📦 Kopiere Credentials..."
cp -r "${OPENCLAW_DIR}/credentials" "${BACKUP_DIR}/" 2>/dev/null || echo "   (keine Credentials)"

echo "📦 Kopiere Devices..."
cp -r "${OPENCLAW_DIR}/devices" "${BACKUP_DIR}/" 2>/dev/null || echo "   (keine Devices)"

echo "📦 Kopiere Memory Index..."
cp -r "${OPENCLAW_DIR}/memory" "${BACKUP_DIR}/" 2>/dev/null || echo "   (kein Memory Index)"

# Systemd Override kopieren (IPv4 Fix)
if [ -d "${HOME}/.config/systemd/user/openclaw-gateway.service.d" ]; then
    echo "📦 Kopiere Systemd Overrides..."
    mkdir -p "${BACKUP_DIR}/systemd-overrides"
    cp -r "${HOME}/.config/systemd/user/openclaw-gateway.service.d" "${BACKUP_DIR}/systemd-overrides/"
fi

# Manifest erstellen
echo "📝 Erstelle Manifest..."
cat > "${BACKUP_DIR}/MANIFEST.md" << EOF
# Skye Backup
**Erstellt:** $(date)
**Host:** $(hostname)
**OpenClaw Version:** $(openclaw --version 2>/dev/null || echo "unbekannt")

## Inhalt
- openclaw.json (Hauptconfig)
- workspace/ (Persönlichkeit, Memory, User-Infos)
- agents/ (Sessions, Agent-State)
- credentials/ (Auth-Daten)
- devices/ (Gepaarte Geräte)
- memory/ (Embedding-Index)
- systemd-overrides/ (Service-Konfiguration)

## Restore
\`\`\`bash
# Auf neuem Server:
# 1. OpenClaw installieren
npm install -g openclaw

# 2. Backup entpacken
tar -xzf ${BACKUP_NAME}.tar.gz -C /tmp/

# 3. Dateien kopieren
cp /tmp/${BACKUP_NAME}/openclaw.json ~/.openclaw/
cp -r /tmp/${BACKUP_NAME}/workspace ~/.openclaw/
cp -r /tmp/${BACKUP_NAME}/agents ~/.openclaw/
cp -r /tmp/${BACKUP_NAME}/credentials ~/.openclaw/
cp -r /tmp/${BACKUP_NAME}/devices ~/.openclaw/

# 4. Systemd Override (falls vorhanden)
cp -r /tmp/${BACKUP_NAME}/systemd-overrides/* ~/.config/systemd/user/

# 5. Gateway starten
openclaw gateway start
\`\`\`

## Hinweise
- API Keys sind im Backup enthalten (sicher aufbewahren!)
- Telegram Bot Token muss ggf. angepasst werden
- Tailscale muss neu eingerichtet werden
EOF

# Archiv erstellen
echo ""
echo "🗜️  Erstelle Archiv..."
cd /tmp
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

# Aufräumen
rm -rf "${BACKUP_DIR}"

# Ergebnis
BACKUP_PATH="/tmp/${BACKUP_NAME}.tar.gz"
BACKUP_SIZE=$(du -h "${BACKUP_PATH}" | cut -f1)

echo ""
echo "✅ Backup fertig!"
echo ""
echo "📁 Datei: ${BACKUP_PATH}"
echo "📊 Größe: ${BACKUP_SIZE}"
echo ""
echo "💡 Zum Download (z.B. via scp):"
echo "   scp user@server:${BACKUP_PATH} ."
