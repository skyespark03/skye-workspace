# 📦 Skye Umzug: Server → Proxmox (Laptop)

## Übersicht

```
AKTUELL                          ZIEL
┌──────────────┐                ┌─────────────────────────────────┐
│ Hetzner VPS  │                │     Proxmox (Laptop)            │
│ srv1308186   │   ────────►    │  ┌───────────┐ ┌───────────┐   │
│ (headless)   │                │  │ Skye-Prod │ │ Skye-Test │   │
└──────────────┘                │  │ (Ubuntu)  │ │ (Ubuntu)  │   │
                                │  └───────────┘ └───────────┘   │
                                └─────────────────────────────────┘
```

## Phase 1: Proxmox Zugang wiederherstellen

### 1.1 IP-Adresse finden
Am Laptop (mit Monitor/Tastatur):
```bash
ip addr show | grep "inet "
# Oder: Nach dem Boot wird die IP oft angezeigt
```

### 1.2 Web-Interface öffnen
```
https://<LAPTOP-IP>:8006
```
- Sicherheitswarnung akzeptieren (selbstsigniertes Zertifikat)
- Login: `root` / `Linux PAM authentication`

### 1.3 Falls Passwort vergessen
Am Laptop direkt einloggen und:
```bash
passwd root
```

---

## Phase 2: VM erstellen (Skye-Prod)

### 2.1 Ubuntu ISO hochladen
1. Proxmox Web UI → `local` Storage → `ISO Images`
2. Download from URL:
   ```
   https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso
   ```

### 2.2 VM erstellen
1. `Create VM` (oben rechts)
2. **General:**
   - Name: `skye-prod`
   - VM ID: 100
3. **OS:**
   - ISO: ubuntu-24.04-desktop-amd64.iso
4. **System:**
   - BIOS: OVMF (UEFI)
   - Machine: q35
   - Qemu Agent: ✓
5. **Disks:**
   - Disk size: 50GB (oder mehr)
   - SSD emulation: ✓
6. **CPU:**
   - Cores: 4 (oder mehr)
7. **Memory:**
   - 8192 MB (8GB) oder mehr
8. **Network:**
   - Bridge: vmbr0

### 2.3 Ubuntu installieren
1. VM starten → Console öffnen
2. Ubuntu Desktop installieren
3. User erstellen: `skye`
4. Nach Installation: Qemu Guest Agent installieren:
   ```bash
   sudo apt install qemu-guest-agent
   sudo systemctl enable qemu-guest-agent
   ```

---

## Phase 3: OpenClaw auf neuer VM einrichten

### 3.1 Basis-Setup
```bash
# Node.js installieren
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# OpenClaw installieren
npm install -g openclaw

# Git
sudo apt install -y git
```

### 3.2 Meine Daten klonen
```bash
mkdir -p ~/.openclaw
cd ~/.openclaw
git clone https://github.com/skyespark03/skye-workspace.git workspace
```

### 3.3 Setup-Skript ausführen
```bash
cd ~/.openclaw/workspace
chmod +x scripts/setup-skye.sh
./scripts/setup-skye.sh
```

### 3.4 Config wiederherstellen
1. `config/openclaw.template.json` kopieren nach `~/.openclaw/openclaw.json`
2. API Keys eintragen (aus SECRETS - hat Dennis)
3. Port ggf. anpassen

### 3.5 GitHub einloggen
```bash
gh auth login
# Device flow → Account: skyespark03
```

### 3.6 Tailscale einrichten
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### 3.7 OpenClaw starten
```bash
# Einmalig testen:
openclaw gateway

# Als Service:
openclaw gateway install
systemctl --user enable --now openclaw-gateway
```

---

## Phase 4: Test-VM erstellen (Skye-Test)

### 4.1 Option A: VM klonen
1. Proxmox → `skye-prod` → `More` → `Clone`
2. Name: `skye-test`
3. Mode: `Full Clone`
4. VM ID: 101

### 4.2 Option B: Snapshot-basiert
1. `skye-prod` → `Snapshots` → `Take Snapshot`
2. Name: `before-test-DATUM`
3. Für Tests: Snapshot wiederherstellen wenn was kaputt geht

### 4.3 Test-VM anpassen
- Anderer Telegram Bot (oder Test-Channel)
- Anderer Gateway Port
- Eigenes Git Branch für Tests

---

## Phase 5: Alten Server abschalten

### 5.1 Checkliste vor Abschaltung
- [ ] Neue VM läuft stabil
- [ ] Telegram Bot antwortet
- [ ] GitHub Push funktioniert
- [ ] Tailscale verbunden
- [ ] Gmail funktioniert (mit Desktop!)
- [ ] Backup gemacht

### 5.2 Server kündigen
- Hetzner/Provider kündigen
- Keine wichtigen Daten mehr drauf? Alles in Git!

---

## Vorteile nach Umzug

| Vorher (Server) | Nachher (Proxmox) |
|-----------------|-------------------|
| Headless, Browser-Probleme | Desktop, alles easy |
| Session läuft ab | Normaler Browser |
| Monatliche Kosten | Nur Strom |
| Eine Instanz | Prod + Test getrennt |
| Kein Snapshot | VM Snapshots! |

---

## Notfall-Recovery

Falls alles kaputt geht:
1. Git Repo ist sicher: `github.com/skyespark03/skye-workspace`
2. `RESTORE.md` folgen
3. API Keys hat Dennis separat

---

*Erstellt: 2026-02-02*
