#!/usr/bin/env bash
#
# NixOS + Hyprland + Tokyo Night Bootstrap Script
# One-command setup for a beautiful, productive desktop
#
# Usage:
#   git clone https://github.com/fredericowieser/NixOS ~/NixOS
#   cd ~/NixOS && ./install.sh
#
# Or one-liner:
#   bash <(curl -s https://raw.githubusercontent.com/fredericowieser/NixOS/main/install.sh)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository URL
REPO_URL="https://github.com/fredericowieser/NixOS.git"
REPO_DIR="$HOME/NixOS"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Check if we're running from a proper clone or via curl pipe
ensure_repo_cloned() {
    # If SCRIPT_DIR is empty, /dev, or doesn't contain our files, we need to clone
    if [[ -z "$SCRIPT_DIR" ]] || [[ "$SCRIPT_DIR" == "/dev"* ]] || [[ ! -f "$SCRIPT_DIR/nixos/configuration.nix" ]]; then

        # Ensure git is available (fresh NixOS minimal installs don't have git)
        if ! command -v git &>/dev/null; then
            echo -e "${BLUE}[INFO]${NC} Git not found. Installing git temporarily..."
            nix-shell -p git --run "$(cat <<'INNERSCRIPT'
                set -e
                REPO_URL="https://github.com/fredericowieser/NixOS.git"
                REPO_DIR="$HOME/NixOS"

                echo -e "\033[0;34m[INFO]\033[0m Cloning repository to $REPO_DIR..."
                if [[ -d "$REPO_DIR" ]]; then
                    echo -e "\033[1;33m[WARN]\033[0m $REPO_DIR already exists. Updating..."
                    cd "$REPO_DIR" && git pull
                else
                    git clone "$REPO_URL" "$REPO_DIR"
                fi
INNERSCRIPT
            )"
            # Re-execute from the cloned repo
            echo -e "${BLUE}[INFO]${NC} Running installer from cloned repository..."
            exec "$REPO_DIR/install.sh" "$@"
        fi

        echo -e "${BLUE}[INFO]${NC} Cloning repository to $REPO_DIR..."

        if [[ -d "$REPO_DIR" ]]; then
            echo -e "${YELLOW}[WARN]${NC} $REPO_DIR already exists. Updating..."
            cd "$REPO_DIR" && git pull
        else
            git clone "$REPO_URL" "$REPO_DIR"
        fi

        # Re-execute from the cloned repo
        echo -e "${BLUE}[INFO]${NC} Running installer from cloned repository..."
        exec "$REPO_DIR/install.sh" "$@"
    fi
}

# Run the repo check early
ensure_repo_cloned "$@"

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     NixOS + Hyprland + Tokyo Night Bootstrap                 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running on NixOS
check_nixos() {
    if [[ ! -f /etc/NIXOS ]]; then
        error "This script must be run on NixOS. Exiting."
    fi
    success "Running on NixOS"
}

# Check if script directory contains required files
check_files() {
    local required_files=(
        "nixos/configuration.nix"
        "config/hypr/hyprland.conf"
        "config/waybar/config.jsonc"
        "config/kitty/kitty.conf"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            error "Missing required file: $file"
        fi
    done
    success "All required files present"
}

# Get user information
get_user_info() {
    # Get hostname
    echo ""
    read -p "Enter hostname for this machine [default: nixos]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-nixos}

    # Get username
    CURRENT_USER=$(whoami)
    read -p "Enter username [default: $CURRENT_USER]: " USERNAME
    USERNAME=${USERNAME:-$CURRENT_USER}

    echo ""
    info "Configuration:"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo ""
    read -p "Continue with these settings? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-Y}

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        error "Installation cancelled by user"
    fi
}

# Backup existing configurations
backup_configs() {
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    local backed_up=false

    for dir in hypr waybar nvim kitty wofi gtk-3.0; do
        if [[ -d "$HOME/.config/$dir" ]]; then
            if [[ "$backed_up" == false ]]; then
                info "Backing up existing configs to $BACKUP_DIR"
                mkdir -p "$BACKUP_DIR"
                backed_up=true
            fi
            cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
            success "Backed up ~/.config/$dir"
        fi
    done

    if [[ "$backed_up" == false ]]; then
        info "No existing configs to backup"
    fi
}

# Install NixOS configuration
install_nixos_config() {
    info "Installing NixOS configuration..."

    # Create temporary file with replacements
    local temp_config=$(mktemp)
    sed -e "s/HOSTNAME/$HOSTNAME/g" \
        -e "s/USERNAME/$USERNAME/g" \
        "$SCRIPT_DIR/nixos/configuration.nix" > "$temp_config"

    # Copy to /etc/nixos/ (requires sudo)
    sudo cp "$temp_config" /etc/nixos/configuration.nix
    rm "$temp_config"

    success "NixOS configuration installed to /etc/nixos/configuration.nix"
}

# Install user dotfiles
install_dotfiles() {
    info "Installing dotfiles to ~/.config/..."

    # Create config directories
    mkdir -p ~/.config/{hypr/scripts,waybar/scripts,nvim,kitty,wofi,gtk-3.0}

    # Copy Hyprland configs
    cp "$SCRIPT_DIR/config/hypr/hyprland.conf" ~/.config/hypr/
    cp "$SCRIPT_DIR/config/hypr/hyprpaper.conf" ~/.config/hypr/
    cp "$SCRIPT_DIR/config/hypr/scripts/"*.sh ~/.config/hypr/scripts/
    success "Hyprland configuration installed"

    # Copy wallpaper
    cp "$SCRIPT_DIR/assets/wallpaper-black.png" ~/.config/hypr/
    success "Wallpaper installed"

    # Copy Waybar configs
    cp "$SCRIPT_DIR/config/waybar/config.jsonc" ~/.config/waybar/
    cp "$SCRIPT_DIR/config/waybar/style.css" ~/.config/waybar/
    cp "$SCRIPT_DIR/config/waybar/scripts/"*.sh ~/.config/waybar/scripts/
    success "Waybar configuration installed"

    # Copy Neovim config
    cp "$SCRIPT_DIR/config/nvim/init.lua" ~/.config/nvim/
    success "Neovim configuration installed"

    # Copy Kitty config
    cp "$SCRIPT_DIR/config/kitty/kitty.conf" ~/.config/kitty/
    success "Kitty configuration installed"

    # Copy Wofi configs
    cp "$SCRIPT_DIR/config/wofi/config" ~/.config/wofi/
    cp "$SCRIPT_DIR/config/wofi/style.css" ~/.config/wofi/
    success "Wofi configuration installed"

    # Copy GTK settings
    cp "$SCRIPT_DIR/config/gtk-3.0/settings.ini" ~/.config/gtk-3.0/
    success "GTK settings installed"
}

# Make scripts executable
make_scripts_executable() {
    info "Making scripts executable..."
    chmod +x ~/.config/hypr/scripts/*.sh
    chmod +x ~/.config/waybar/scripts/*.sh
    success "All scripts are now executable"
}

# Rebuild NixOS
rebuild_nixos() {
    echo ""
    read -p "Run 'sudo nixos-rebuild switch' now? [Y/n]: " REBUILD
    REBUILD=${REBUILD:-Y}

    if [[ "$REBUILD" =~ ^[Yy]$ ]]; then
        info "Running nixos-rebuild switch..."
        echo ""
        sudo nixos-rebuild switch
        success "NixOS rebuild complete!"
    else
        warn "Skipping nixos-rebuild. Run 'sudo nixos-rebuild switch' manually."
    fi
}

# Optional: Install yt-x
install_ytx() {
    echo ""
    read -p "Install yt-x (YouTube downloader)? [y/N]: " INSTALL_YTX
    INSTALL_YTX=${INSTALL_YTX:-N}

    if [[ "$INSTALL_YTX" =~ ^[Yy]$ ]]; then
        info "Installing yt-x via nix profile..."
        nix profile install github:fredericowieser/yt-x
        success "yt-x installed!"
    fi
}

# Set user password
set_user_password() {
    echo ""
    warn "Your user account needs a password to log in."
    read -p "Set password for '$USERNAME' now? [Y/n]: " SET_PASS
    SET_PASS=${SET_PASS:-Y}

    if [[ "$SET_PASS" =~ ^[Yy]$ ]]; then
        sudo passwd "$USERNAME"
        success "Password set for $USERNAME"
    else
        warn "Remember to set a password before rebooting: sudo passwd $USERNAME"
    fi
}

# Print final message
print_success() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     Installation Complete!                                   ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Reboot your system to start Hyprland"
    echo "  2. Log in via SDDM with your username and password"
    echo ""
    echo "Keybindings (Super = Windows key):"
    echo "  Super+Space    App launcher"
    echo "  Super+T        Terminal"
    echo "  Super+Q        Close window"
    echo "  Super+B        Browser"
    echo "  Super+F        File manager"
    echo "  Super+V        Neovim"
    echo "  Super+1-8      Switch workspace"
    echo ""
    echo "For more keybindings, see ~/.config/hypr/hyprland.conf"
    echo ""
}

# Main execution
main() {
    print_banner
    check_nixos
    check_files
    get_user_info
    backup_configs
    install_nixos_config
    install_dotfiles
    make_scripts_executable
    rebuild_nixos
    set_user_password
    install_ytx
    print_success
}

main "$@"
