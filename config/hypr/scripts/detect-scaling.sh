#!/usr/bin/env bash
# Detects Hyprland's auto-scale and configures XWayland DPI accordingly

sleep 1  # Wait for Hyprland to initialize

# Get current scale from first monitor
SCALE=$(hyprctl monitors -j | jq -r '.[0].scale')

# Calculate DPI (base 96 * scale)
DPI=$(echo "$SCALE * 96" | bc | cut -d. -f1)
DPI=${DPI:-96}  # Fallback to 96 if calculation fails

# Update Xresources for XWayland apps
cat > ~/.Xresources << EOF
Xft.dpi: $DPI
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintfull
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb
EOF

xrdb -merge ~/.Xresources
