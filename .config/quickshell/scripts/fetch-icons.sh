#!/usr/bin/env bash
# Unduh ikon Lucide (ISC license) ke assets/icons/ dan ubah currentColor -> putih.
# Pakai: bash scripts/fetch-icons.sh   (dijalankan dari root shell)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/icons
icons="wifi wifi-high wifi-low wifi-zero wifi-off
bluetooth bluetooth-connected bluetooth-off
battery battery-low battery-medium battery-full battery-charging battery-warning
sun sun-medium sun-dim moon volume volume-1 volume-2 volume-x
cloud cloud-sun cloud-moon cloud-rain cloud-drizzle cloud-snow cloud-lightning cloud-fog wind"
for n in $icons; do
  curl -fsSL "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/$n.svg" \
    | sed 's/currentColor/#ffffff/g' > "assets/icons/$n.svg"
done
echo "OK: $(ls assets/icons | wc -l) ikon"
