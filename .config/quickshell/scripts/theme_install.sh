#!/bin/bash
# Install atau update satu tema dari repo dotfiles bergaya nested

set -uo pipefail

NAME="${1:?nama tema wajib diisi}"
REPO="${2:?repo url wajib diisi}"
BRANCH="${3:-main}"

STAGING_DIR="$HOME/.cache/quickshell/staging"
STAGING="$STAGING_DIR/$NAME"
THEMES_DIR="$HOME/.local/share/quickshell-themes"
DEST="$THEMES_DIR/$NAME"
HYPR_DIR="$HOME/.config/hypr"
HYPR_DEST="$HYPR_DIR/$NAME.lua"

mkdir -p "$STAGING_DIR" "$THEMES_DIR" "$HYPR_DIR"

# 1. Clone / update repo penuh ke staging (sementara, boleh besar & nested)
if [ -d "$STAGING/.git" ]; then
  if ! git -C "$STAGING" fetch origin "$BRANCH" --depth 1 >/dev/null 2>&1; then
    echo "ERROR: gagal fetch update"
    exit 1
  fi
  git -C "$STAGING" reset --hard "origin/$BRANCH" >/dev/null 2>&1
else
  rm -rf "$STAGING"
  if ! git clone --depth 1 --branch "$BRANCH" "$REPO" "$STAGING" >/dev/null 2>&1; then
    rm -rf "$STAGING"
    echo "ERROR: gagal clone repo"
    exit 1
  fi
fi

# 2. Cari folder quickshell di dalam hasil clone (coba beberapa pola umum)
QS_SRC=""
for candidate in ".config/quickshell" "quickshell" "."; do
  if [ -f "$STAGING/$candidate/shell.qml" ]; then
    QS_SRC="$STAGING/$candidate"
    break
  fi
done

if [ -z "$QS_SRC" ]; then
  echo "ERROR: shell.qml tidak ditemukan di repo (cek struktur folder)"
  exit 1
fi

rm -rf "$DEST"
cp -r "$QS_SRC" "$DEST"

# 3. Cari hyprland.lua (opsional, nggak wajib ada)
HYPR_SRC=""
for candidate in ".config/hypr/hyprland.lua" "hypr/hyprland.lua"; do
  if [ -f "$STAGING/$candidate" ]; then
    HYPR_SRC="$STAGING/$candidate"
    break
  fi
done

if [ -n "$HYPR_SRC" ]; then
  cp "$HYPR_SRC" "$HYPR_DEST"
fi

echo "DONE"
