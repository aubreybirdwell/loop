#!/usr/bin/env bash
set -euo pipefail

# Detect the real desktop user even if running via sudo
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
PROJECT_DIR="$TARGET_HOME/loop"
AUTOSTART_DIR="$TARGET_HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/video-loop.desktop"

echo "[install] User: $TARGET_USER"
echo "[install] Home: $TARGET_HOME"
echo "[install] Project: $PROJECT_DIR"

echo "[install] Installing dependencies…"
sudo apt update
sudo apt install -y mpv exfatprogs ntfs-3g

echo "[install] Ensuring execute bits…"
chmod +x "$PROJECT_DIR/video-loop.sh"

echo "[install] Creating autostart…"
mkdir -p "$AUTOSTART_DIR"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Video Loop
Comment=Start mpv video loop on login
Exec=$PROJECT_DIR/video-loop.sh
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
X-MATE-Autostart-Phase=Application
EOF

echo "[install] Ownership…"
chown -R "$TARGET_USER":"$TARGET_USER" "$PROJECT_DIR" "$AUTOSTART_DIR"

cat <<EOF

[install] Done.

NEXT:
1) Put your video(s) on a USB stick (root or subfolder), or in $TARGET_HOME/Videos
2) Enable Desktop Autologin + disable screen blanking:
   - Raspberry Pi Configuration → System → Login: "To Desktop – Autologin"
   - Raspberry Pi Configuration → Display → Screen Blanking: Disabled
3) Reboot: sudo reboot

Manual test (without reboot):
  bash -x $PROJECT_DIR/video-loop.sh
EOF
