#!/usr/bin/env bash
# Cycle through workspaces on the CURRENT monitor only
# Laptop (eDP-*): cycles 1-8
# External monitors: cycles their assigned range (9-12, 13-16, etc.)

LAPTOP_WORKSPACES=8
WORKSPACES_PER_EXTERNAL=4

# Get current workspace and monitor
current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
current_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')

# Determine workspace range for this monitor
if [[ "$current_monitor" == eDP* ]]; then
    # Laptop monitor: workspaces 1-8
    min_ws=1
    max_ws=$LAPTOP_WORKSPACES
else
    # External monitor: need to find its range
    # Get list of external monitors sorted
    externals=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | sort)

    # Find index of current monitor
    monitor_index=0
    for mon in $externals; do
        if [[ "$mon" == "$current_monitor" ]]; then
            break
        fi
        monitor_index=$((monitor_index + 1))
    done

    # Calculate workspace range
    min_ws=$((LAPTOP_WORKSPACES + 1 + monitor_index * WORKSPACES_PER_EXTERNAL))
    max_ws=$((min_ws + WORKSPACES_PER_EXTERNAL - 1))
fi

# Calculate next workspace
case "$1" in
    next)
        next_ws=$((current_ws + 1))
        if [[ $next_ws -gt $max_ws ]]; then
            next_ws=$min_ws
        fi
        ;;
    prev)
        next_ws=$((current_ws - 1))
        if [[ $next_ws -lt $min_ws ]]; then
            next_ws=$max_ws
        fi
        ;;
    *)
        echo "Usage: $0 [next|prev]"
        exit 1
        ;;
esac

hyprctl dispatch workspace "$next_ws"
