#!/usr/bin/env bash
set -euo pipefail

# Detect the real desktop user even if running via sudo
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "[install] Installing dependencies…"
sudo apt update
sudo apt install -y mpv

echo "[install] Preparing autostart…"
AUTOSTART_DIR="$TARGET_HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Write the .desktop file with absolute paths for the target user
DESKTOP_FILE="$AUTOSTART_DIR/video-loop.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Video Loop
Comment=Start mpv video loop on login
Exec=$TARGET_HOME/video-looper/video-loop.sh
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
X-MATE-Autostart-Phase=Application
EOF

# Ensure scripts are executable
chmod +x "$TARGET_HOME/video-looper/video-loop.sh"

# Make sure user owns everything
chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME/video-looper" "$AUTOSTART_DIR"

echo "[install] Done.
- Put a video on a USB stick (e.g., /media/$TARGET_USER/YourUSB/yourvideo.mp4), or in $TARGET_HOME/Videos
- Enable desktop auto-login so this launches at boot.
"
