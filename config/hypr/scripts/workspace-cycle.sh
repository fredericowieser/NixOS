#!/usr/bin/env bash
# Cycle through all 10 workspaces with wrap-around
# 1→2→3→4→5→6→7→8→9→10→1 (next)
# 1→10→9→8→7→6→5→4→3→2→1 (prev)

MAX_WS=8
current=$(hyprctl activeworkspace | grep -oP 'workspace ID \K[0-9]+')

# Fallback if grep -P not available
if [[ -z "$current" ]]; then
    current=$(hyprctl activeworkspace | head -1 | awk '{print $3}')
fi

# Default to 1 if still empty
if [[ -z "$current" || ! "$current" =~ ^[0-9]+$ ]]; then
    current=1
fi

case "$1" in
    next)
        next=$((current + 1))
        if [[ $next -gt $MAX_WS ]]; then
            next=1
        fi
        ;;
    prev)
        next=$((current - 1))
        if [[ $next -lt 1 ]]; then
            next=$MAX_WS
        fi
        ;;
    *)
        exit 1
        ;;
esac

hyprctl dispatch workspace "$next"
