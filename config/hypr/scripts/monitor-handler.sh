#!/usr/bin/env bash
# Handles monitor connect/disconnect events via Hyprland IPC
# Dynamically assigns workspaces: laptop gets 1-8, external monitors get 9-12, 13-16, etc.

WORKSPACES_PER_EXTERNAL=4
LAPTOP_WORKSPACES=8

# Assign workspaces to all connected monitors
assign_workspaces() {
    # Get all monitors
    local monitors=$(hyprctl monitors -j)

    # Laptop monitor (eDP-*) always gets workspaces 1-8
    local laptop=$(echo "$monitors" | jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -1)

    if [[ -n "$laptop" ]]; then
        for ws in $(seq 1 $LAPTOP_WORKSPACES); do
            hyprctl keyword workspace "$ws, monitor:$laptop" 2>/dev/null
        done
        # Set default workspace
        hyprctl keyword workspace "1, monitor:$laptop, default:true" 2>/dev/null
    fi

    # Get external monitors (non-eDP), sorted by name for consistency
    local externals=$(echo "$monitors" | jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | sort)

    # Assign workspaces to each external monitor
    local monitor_index=0
    for monitor in $externals; do
        local start_ws=$((LAPTOP_WORKSPACES + 1 + monitor_index * WORKSPACES_PER_EXTERNAL))
        local end_ws=$((start_ws + WORKSPACES_PER_EXTERNAL - 1))

        # Assign workspace range to this monitor
        for ws in $(seq $start_ws $end_ws); do
            hyprctl keyword workspace "$ws, monitor:$monitor" 2>/dev/null
        done

        # Set default workspace for this monitor
        hyprctl keyword workspace "$start_ws, monitor:$monitor, default:true" 2>/dev/null

        # Create all workspaces so they appear in waybar (even when empty)
        for ws in $(seq $start_ws $end_ws); do
            hyprctl dispatch workspace "$ws" 2>/dev/null
        done
        # Return to the default workspace
        hyprctl dispatch workspace "$start_ws" 2>/dev/null

        monitor_index=$((monitor_index + 1))
    done

    # Update waybar config with current monitor workspace assignments
    update_waybar_persistent_workspaces "$laptop" "$externals"
}

# Update waybar persistent-workspaces to match current monitor assignments
update_waybar_persistent_workspaces() {
    local laptop="$1"
    local externals="$2"
    local waybar_config="$HOME/.config/waybar/config.jsonc"

    [[ ! -f "$waybar_config" ]] && return

    # Build new persistent-workspaces content
    local content='"persistent-workspaces": {'
    local first=true

    # Laptop workspaces
    if [[ -n "$laptop" ]]; then
        content+="\"$laptop\": [1, 2, 3, 4, 5, 6, 7, 8]"
        first=false
    fi

    # External monitor workspaces
    local monitor_index=0
    for monitor in $externals; do
        local start_ws=$((LAPTOP_WORKSPACES + 1 + monitor_index * WORKSPACES_PER_EXTERNAL))
        local end_ws=$((start_ws + WORKSPACES_PER_EXTERNAL - 1))

        # Build workspace array
        local ws_array="["
        for ws in $(seq $start_ws $end_ws); do
            [[ "$ws" != "$start_ws" ]] && ws_array+=", "
            ws_array+="$ws"
        done
        ws_array+="]"

        [[ "$first" == "false" ]] && content+=", "
        content+="\"$monitor\": $ws_array"
        first=false

        monitor_index=$((monitor_index + 1))
    done

    content+='}'

    # Replace the persistent-workspaces line in waybar config
    # Use a temp file to avoid sed issues
    local tmpfile=$(mktemp)
    awk -v new_content="        $content," '
        /"persistent-workspaces"/ {
            print new_content
            in_block = 1
            brace_count = 1
            next
        }
        in_block {
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                if (c == "{") brace_count++
                if (c == "}") brace_count--
                if (brace_count == 0) {
                    in_block = 0
                    break
                }
            }
            next
        }
        { print }
    ' "$waybar_config" > "$tmpfile"

    mv "$tmpfile" "$waybar_config"
}

handle_monitor_event() {
    local event="$1"

    case "$event" in
        monitoradded*)
            local monitor_name="${event#monitoradded>>}"
            sleep 0.5

            # Reassign all workspaces
            assign_workspaces

            # Re-run scaling detection
            ~/.config/hypr/scripts/detect-scaling.sh &

            # Restart waybar to pick up new config
            pkill waybar 2>/dev/null
            sleep 0.3
            waybar &>/dev/null &

            notify-send "Monitor Connected" "$monitor_name" -t 2000
            ;;

        monitorremoved*)
            local monitor_name="${event#monitorremoved>>}"
            sleep 0.3

            # Reassign workspaces for remaining monitors
            assign_workspaces

            # Restart waybar
            pkill waybar 2>/dev/null
            sleep 0.3
            waybar &>/dev/null &

            notify-send "Monitor Disconnected" "$monitor_name" -t 2000
            ;;
    esac
}

# Initial workspace assignment on startup
sleep 1
assign_workspaces

# Listen to Hyprland socket for events
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    handle_monitor_event "$line"
done
