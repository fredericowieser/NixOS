# NixOS + Hyprland + Tokyo Night

A portable, one-command bootstrap system for NixOS with Hyprland window manager and Tokyo Night color scheme.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/fredericowieser/NixOS ~/NixOS

# Run the installer
cd ~/NixOS && ./install.sh
```

Or as a one-liner:

```bash
bash <(curl -s https://raw.githubusercontent.com/fredericowieser/NixOS/main/install.sh)
```

## Updating

After initial install, use `update.sh` to pull latest changes and update configs:

```bash
cd ~/NixOS && ./update.sh
```

This will:
1. Pull latest changes from git
2. Copy updated configs to `~/.config/`
3. Make scripts executable
4. Optionally update `/etc/nixos/configuration.nix` (preserves hostname/username)
5. Optionally run `nixos-rebuild switch`
6. Reload Hyprland and restart Waybar (no logout required)

## Prerequisites

- Fresh minimal NixOS installation
- Network connectivity
- User with sudo access

> **Note:** The installer will prompt you to set a password for your user account. If you skip this step, remember to run `sudo passwd <username>` before rebooting.

## Features

- **Tokyo Night** color scheme across all applications
- **Hyprland** tiling window manager with smooth animations
- **Waybar** with custom modules:
  - Weather (London, via wttr.in)
  - Pomodoro timer (50min work / 10min break)
  - CPU, RAM, Disk, Temperature monitoring
  - Battery with charging status
  - Network connectivity indicator
  - Notifications (Do Not Disturb toggle)
  - Caffeine mode (prevent sleep)
  - Power menu
- **Neovim** with lazy.nvim, neo-tree, telescope, treesitter
- **Kitty** terminal with Tokyo Night colors
- **Wofi** application launcher
- **8 workspaces** with descriptive icons

## Keybindings

| Key | Action |
|-----|--------|
| `Super+Space` | App launcher (Wofi) |
| `Super+T` | Terminal (Kitty) |
| `Super+Q` | Close window |
| `Super+B` | Browser (Vivaldi) |
| `Super+F` | File manager (Thunar) |
| `Super+M` | Music (Spotify) |
| `Super+V` | Neovim |
| `Super+N` | Notifications panel |
| `Super+1-8` | Switch to workspace 1-8 |
| `Super+Shift+1-8` | Move window to workspace 1-8 |
| `Super+Left/Right` | Cycle workspaces |
| `Super+Shift+Arrow` | Move focus |
| `Super+Shift+V` | Toggle floating |
| `Super+Shift+E` | Exit Hyprland |
| `Super+S` | Scratchpad |

### Media Keys

- Volume up/down/mute
- Brightness up/down
- Play/Pause, Next, Previous

## Included Packages

### Desktop
- Hyprland, Waybar, Wofi, Kitty, Thunar
- hyprpaper, hyprlock, wlsunset

### Browsers
- Vivaldi, Chromium

### Media
- VLC, mpv, Spotify, OBS Studio, GIMP, Inkscape

### Productivity
- LibreOffice, Obsidian, Zotero

### Communication
- Discord, Telegram, Signal, Thunderbird

### Development
- Neovim, VSCode, VSCodium, Claude Code, Git

### Terminal Utilities
- btop, yazi, fzf, yt-dlp, ani-cli, cmatrix, neofetch

### System
- NetworkManager, Bluetooth (blueman), PipeWire audio

## Workspaces

| # | Icon | Purpose |
|---|------|---------|
| 1 | 󰆍 | Terminal |
| 2 | 󰖟 | Browser |
| 3 | 󰍡 | Communication |
| 4 | 󰂺 | Notes |
| 5 | 󰎆 | Media |
| 6 | 󰅩 | Code |
| 7 | 󰐕 | Misc |
| 8 | 󰐕 | Misc |

## Customization

### Change Hostname

Edit `nixos/configuration.nix` and update the hostname, then run:

```bash
sudo nixos-rebuild switch
```

### Change Weather Location

Edit `~/.config/waybar/scripts/weather.sh` and change the `LOCATION` variable.

### Add/Remove Packages

Edit `nixos/configuration.nix` and modify the `environment.systemPackages` list.

### Adjust Keybindings

Edit `~/.config/hypr/hyprland.conf` in the keybindings section.

## Neovim Keybindings

| Key | Action |
|-----|--------|
| `Space+e` | Toggle file explorer |
| `Space+ff` | Find files |
| `Space+fg` | Live grep |
| `Space+fb` | Buffers |
| `Space+fr` | Recent files |
| `Ctrl+h/j/k/l` | Navigate windows |
| `Shift+h/l` | Previous/Next buffer |
| `Space+bd` | Delete buffer |
| `gcc` | Comment line |
| `gc` (visual) | Comment selection |

## File Structure

```
~/NixOS/
├── README.md
├── install.sh
├── nixos/
│   └── configuration.nix
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf
│   │   ├── hyprpaper.conf
│   │   └── scripts/
│   ├── waybar/
│   │   ├── config.jsonc
│   │   ├── style.css
│   │   └── scripts/
│   ├── nvim/
│   │   └── init.lua
│   ├── kitty/
│   │   └── kitty.conf
│   ├── wofi/
│   │   ├── config
│   │   └── style.css
│   └── gtk-3.0/
│       └── settings.ini
└── assets/
    └── wallpaper-black.png
```

## Troubleshooting

### Waybar scripts not working

Make sure scripts are executable:

```bash
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/hypr/scripts/*.sh
```

### Weather not showing

Check network connectivity and ensure `curl` and `jq` are installed.

### Neovim plugins not loading

Open Neovim and run `:Lazy sync` to install plugins.

### No sound

Ensure PipeWire is running:

```bash
systemctl --user status pipewire
```

## Credits

- [Tokyo Night](https://github.com/folke/tokyonight.nvim) color scheme by folke
- [Hyprland](https://hyprland.org/) window manager
- [lazy.nvim](https://github.com/folke/lazy.nvim) plugin manager

## License

MIT
