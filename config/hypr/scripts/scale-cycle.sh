#!/usr/bin/env bash
# Cycles through scaling ratios on the focused monitor
# Keybind: SUPER + /

# Get the monitor that currently has focus
FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

if [[ -z "$FOCUSED_MONITOR" ]]; then
    notify-send "Scale Cycle" "No focused monitor found"
    exit 1
fi

# Get current scale
CURRENT_SCALE=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$FOCUSED_MONITOR\") | .scale")

# Cycle through scales: 1 -> 1.5 -> 2 -> 1
case "$CURRENT_SCALE" in
    1|1.0|1.00*)
        NEW_SCALE=1.5
        ;;
    1.5|1.50*)
        NEW_SCALE=2
        ;;
    2|2.0|2.00*)
        NEW_SCALE=1
        ;;
    *)
        # Default to 1 if current scale is unusual
        NEW_SCALE=1
        ;;
esac

# Apply new scale
hyprctl keyword monitor "$FOCUSED_MONITOR,preferred,auto,$NEW_SCALE"

# Update XWayland DPI
~/.config/hypr/scripts/detect-scaling.sh &

# Notify user
notify-send "Scale: ${NEW_SCALE}x" "Monitor: $FOCUSED_MONITOR" -t 1500
