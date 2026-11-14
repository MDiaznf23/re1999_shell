#!/bin/bash
# Pulihkan wallpaper + color engine terakhir saat niri start (gambar, GIF, atau video).
# Dipanggil dari niri: spawn-sh-at-startup "~/.config/m3-colors/restore-wallpaper.sh"

CFG="$HOME/.config/m3-colors"
SHELL_CFG="$HOME/.config/bagja-shell/config.conf"
DEFAULT="$HOME/Pictures/Wallpapers/caelestia.png"

# ── Color engine terakhir (sama dengan yang dipakai WallpaperPicker) ─────────
ENGINE=$(awk -F= '/^[[:space:]]*color_engine[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2; exit}' \
         "$SHELL_CFG" 2>/dev/null)
case "$ENGINE" in
  m3wal|warnaza) ;;      # hanya engine yang dikenal
  *) ENGINE="m3wal" ;;   # config kosong/aneh -> default
esac
command -v "$ENGINE" >/dev/null || { echo "[restore] $ENGINE tidak ditemukan di PATH" >&2; exit 1; }

# ── Tunggu awww-daemon siap (maksimal ~5 detik), bukan sleep 1 buta ─────────
for _ in $(seq 1 50); do
  awww query >/dev/null 2>&1 && break
  sleep 0.1
done

# ── Wallpaper terakhir ──────────────────────────────────────────────────────
# 1) File ASLI yang terakhir dipakai (symlink current_wallpaper).
#    Untuk video, ini video aslinya, bukan frame diam.
WALL=$(readlink -f "$CFG/current_wallpaper" 2>/dev/null)

# 2) Cadangan: yang sedang ditampilkan awww (hanya gambar/frame diam)
if [ ! -f "$WALL" ]; then
  WALL=$(awww query 2>/dev/null | awk -F': ' '{print $NF}' | head -1)
fi

# 3) Terakhir: wallpaper bawaan
[ -f "$WALL" ] || WALL="$DEFAULT"

exec "$ENGINE" "$WALL"
