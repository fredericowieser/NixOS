#!/usr/bin/env bash
# Caffeine toggle - prevents system from sleeping

LOCK_FILE="/tmp/caffeine.lock"
INHIBIT_PID_FILE="/tmp/caffeine.pid"

toggle() {
    if [[ -f "$LOCK_FILE" ]]; then
        # Disable caffeine
        rm -f "$LOCK_FILE"
        if [[ -f "$INHIBIT_PID_FILE" ]]; then
            kill "$(cat "$INHIBIT_PID_FILE")" 2>/dev/null
            rm -f "$INHIBIT_PID_FILE"
        fi
    else
        # Enable caffeine
        touch "$LOCK_FILE"
        systemd-inhibit --what=idle:sleep:handle-lid-switch \
            --who="Caffeine" \
            --why="User requested stay awake" \
            --mode=block \
            sleep infinity &
        echo $! > "$INHIBIT_PID_FILE"
    fi
}

status() {
    if [[ -f "$LOCK_FILE" ]]; then
        echo '{"text": "󰅶", "tooltip": "Caffeine: ON - System will stay awake", "class": "active"}'
    else
        echo '{"text": "󰛊", "tooltip": "Caffeine: OFF - Normal sleep behavior", "class": "inactive"}'
    fi
}

case "$1" in
    toggle) toggle ;;
    *) status ;;
esac
