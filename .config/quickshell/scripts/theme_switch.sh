#!/bin/bash
#   ~/.config/quickshell -> ~/.local/share/quickshell-themes/<name>
#   ~/.config/hypr/active-ricing.lua -> ~/.config/hypr/<name>.lua
# Usage: theme_switch.sh <name>

set -uo pipefail

NAME="${1:?nama tema wajib diisi}"

STATE_DIR="$HOME/.cache/quickshell"
STATE_FILE="$STATE_DIR/current-theme"

THEMES_DIR="$HOME/.local/share/quickshell-themes"
THEME_SRC="$THEMES_DIR/$NAME"
QS_LINK="$HOME/.config/quickshell"

HYPR_DIR="$HOME/.config/hypr"
HYPR_SRC="$HYPR_DIR/$NAME.lua"           # per-tema, ditulis oleh theme_install.sh
HYPR_LINK="$HYPR_DIR/active-ricing.lua"  # nama tetap, ini yang di-source hyprland.lua

mkdir -p "$STATE_DIR"

if [ ! -d "$THEME_SRC" ]; then
  echo "ERROR: tema belum terinstall, install dulu"
  exit 1
fi

# 1. Matikan instance quickshell (default) yang lagi jalan
pkill -f "^qs$" >/dev/null 2>&1 || true
sleep 0.3

# 2. Ganti symlink hyprland ke config milik tema ini (kalau ada), lalu reload
if [ -f "$HYPR_SRC" ]; then
  ln -sfn "$HYPR_SRC" "$HYPR_LINK"
  hyprctl reload >/dev/null 2>&1 || true
fi

# 3. Ganti symlink ~/.config/quickshell supaya isinya jadi tema ini.
#    Kalau lokasi itu masih folder fisik asli (bukan symlink), hapus dulu
#    supaya ln -sfn bisa menggantikannya, bukan nyelip di dalamnya.
if [ -e "$QS_LINK" ] && [ ! -L "$QS_LINK" ]; then
  rm -rf "$QS_LINK"
fi
ln -sfn "$THEME_SRC" "$QS_LINK"

echo "$NAME" > "$STATE_FILE"

# 4. Jalankan instance baru (default, tanpa -c) sebagai proses lepas
setsid qs >/dev/null 2>&1 &
disown

echo "SWITCHED"
