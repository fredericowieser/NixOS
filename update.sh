#!/usr/bin/env bash
# Update script for NixOS dotfiles
# Pulls latest changes and updates configs without full reinstall
# Can be run via: bash <(curl -s https://raw.githubusercontent.com/fredericowieser/NixOS/main/update.sh)

set -e

REPO_URL="https://github.com/fredericowieser/NixOS"
REPO_DIR="$HOME/NixOS"
CONFIG_DIR="$HOME/.config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}     NixOS Dotfiles Update Script       ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Clone or pull repo
if git -C "$REPO_DIR" rev-parse --git-dir &>/dev/null; then
    print_status "Pulling latest changes from git..."
    cd "$REPO_DIR"
    if git pull; then
        print_success "Git pull complete"
    else
        print_error "Git pull failed - do you have local changes?"
        print_warning "Run 'git stash' to save local changes, then try again"
        exit 1
    fi
else
    if [[ -d "$REPO_DIR" ]]; then
        print_warning "$REPO_DIR exists but is not a git repo, removing..."
        rm -rf "$REPO_DIR"
    fi
    print_status "Cloning repository..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    print_success "Repository cloned to $REPO_DIR"
fi

# Step 2: Copy config files
print_status "Copying config files to ~/.config/..."

# Hyprland
if [[ -d "$REPO_DIR/config/hypr" ]]; then
    cp -r "$REPO_DIR/config/hypr/"* "$CONFIG_DIR/hypr/"
    print_success "Updated Hyprland config"
fi

# Waybar
if [[ -d "$REPO_DIR/config/waybar" ]]; then
    cp -r "$REPO_DIR/config/waybar/"* "$CONFIG_DIR/waybar/"
    print_success "Updated Waybar config"
fi

# Kitty
if [[ -d "$REPO_DIR/config/kitty" ]]; then
    cp -r "$REPO_DIR/config/kitty/"* "$CONFIG_DIR/kitty/"
    print_success "Updated Kitty config"
fi

# Wofi
if [[ -d "$REPO_DIR/config/wofi" ]]; then
    cp -r "$REPO_DIR/config/wofi/"* "$CONFIG_DIR/wofi/"
    print_success "Updated Wofi config"
fi

# Neovim
if [[ -d "$REPO_DIR/config/nvim" ]]; then
    cp -r "$REPO_DIR/config/nvim/"* "$CONFIG_DIR/nvim/"
    print_success "Updated Neovim config"
fi

# GTK
if [[ -d "$REPO_DIR/config/gtk-3.0" ]]; then
    cp -r "$REPO_DIR/config/gtk-3.0/"* "$CONFIG_DIR/gtk-3.0/"
    print_success "Updated GTK config"
fi

# Swaync
if [[ -d "$REPO_DIR/config/swaync" ]]; then
    mkdir -p "$CONFIG_DIR/swaync"
    cp -r "$REPO_DIR/config/swaync/"* "$CONFIG_DIR/swaync/"
    print_success "Updated Swaync config"
fi

# Step 3: Make scripts executable
print_status "Making scripts executable..."
chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true
print_success "Scripts are executable"

# Step 3.5: Clear waybar caches for fresh output
print_status "Clearing waybar caches..."
rm -f /tmp/waybar-weather-cache 2>/dev/null || true
print_success "Caches cleared"

# Step 4: Ask about NixOS config update
echo ""
read -p "$(echo -e "${YELLOW}Update /etc/nixos/configuration.nix? [y/N]:${NC} ")" update_nixos
if [[ "$update_nixos" =~ ^[Yy]$ ]]; then
    print_status "Updating NixOS configuration..."

    # Preserve hostname and username from current config
    current_hostname=$(grep -oP "hostName = \"\K[^\"]*" /etc/nixos/configuration.nix 2>/dev/null || echo "nixos")
    current_username=$(grep -oP "users\.users\.\K[a-zA-Z0-9_-]+" /etc/nixos/configuration.nix 2>/dev/null | head -1 || echo "")

    if [[ -n "$current_username" ]]; then
        print_status "Preserving hostname: $current_hostname"
        print_status "Preserving username: $current_username"

        # Copy new config
        sudo cp "$REPO_DIR/nixos/configuration.nix" /etc/nixos/configuration.nix

        # Update hostname
        sudo sed -i "s/hostName = \"[^\"]*\"/hostName = \"$current_hostname\"/" /etc/nixos/configuration.nix

        # Update username (replace template username with current)
        template_user=$(grep -oP "users\.users\.\K[a-zA-Z0-9_-]+" "$REPO_DIR/nixos/configuration.nix" | head -1)
        if [[ -n "$template_user" && "$template_user" != "$current_username" ]]; then
            sudo sed -i "s/$template_user/$current_username/g" /etc/nixos/configuration.nix
        fi

        print_success "NixOS configuration updated"
    else
        print_warning "Could not detect current username, skipping NixOS config update"
    fi
fi

# Step 5: Ask about rebuild
echo ""
read -p "$(echo -e "${YELLOW}Run nixos-rebuild switch? [y/N]:${NC} ")" rebuild
if [[ "$rebuild" =~ ^[Yy]$ ]]; then
    print_status "Rebuilding NixOS (this may take a while)..."
    if sudo nixos-rebuild switch; then
        print_success "NixOS rebuild complete"
    else
        print_error "NixOS rebuild failed"
        exit 1
    fi
fi

# Step 6: Reload Hyprland and Waybar
echo ""
print_status "Reloading Hyprland and Waybar..."

# Reload Hyprland config (doesn't require logout)
if command -v hyprctl &>/dev/null; then
    hyprctl reload 2>/dev/null && print_success "Hyprland config reloaded" || print_warning "Hyprland reload skipped (not running?)"
fi

# Restart Waybar
if pgrep waybar &>/dev/null; then
    pkill waybar
    sleep 0.5
    waybar &>/dev/null &
    disown
    print_success "Waybar restarted"
else
    print_warning "Waybar not running, skipping restart"
fi

echo ""
print_success "Update complete!"
echo ""
