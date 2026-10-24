# re1999_shell

Reverse: 1999 themed Arch Linux rice, built with Hyprland and Quickshell.

![preview](preview.png)

## Showcase

Soonnnnn

## Components

| | |
|---|---|
| WM | Hyprland |
| Shell | Quickshell |
| Terminal | Kitty |
| CLI shell | Fish |
| File manager | Dolphin |
| Colors | m3wal, warnaza |
| Audio | PipeWire |

## Installation

Requires a working Arch Linux install and an internet connection.

```bash
git clone https://github.com/MDiaznf23/re1999_shell.git
cd re1999_shell
./install.sh
```

Log out and back in, then start `Hyprland`.

## What install.sh does

- Installs `yay` if missing
- Installs pacman and AUR packages
- Sets fish as the default shell
- Copies configs to `~/.config` (backup at `~/.config.bak`)
- Copies wallpapers, cursor theme and fonts
- Registers the theme with the Theme Switcher
- Generates a color scheme with m3wal
- Enables PipeWire and NetworkManager services

## Structure

```
.config/     configs (hypr, quickshell, etc.)
.icons/      cursor theme
.local/      local data
Fonts/       extra fonts
Wallpapers/  wallpapers
```

## Notes

- `install.sh` overwrites `~/.config`. The previous backup is replaced on every run.
- Change wallpaper and colors: `m3wal <path/to/wallpaper>`
