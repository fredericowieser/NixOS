#!/usr/bin/env bash
# Detects Hyprland's auto-scale and configures XWayland DPI accordingly
# Handles multiple monitors by using the highest scale value

# Wait for Hyprland to initialize (skip if called after startup)
if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    sleep 1
fi

# Get the highest scale from all monitors (better for mixed HiDPI setups)
# XWayland apps look better at HiDPI and get scaled down on lower-DPI monitors
SCALE=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[].scale] | max // 1')

# Fallback if no monitors detected or jq fails
if [[ -z "$SCALE" || "$SCALE" == "null" ]]; then
    SCALE=1
fi

# Calculate DPI (base 96 * scale)
DPI=$(echo "$SCALE * 96" | bc 2>/dev/null | cut -d. -f1)
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

xrdb -merge ~/.Xresources 2>/dev/null
