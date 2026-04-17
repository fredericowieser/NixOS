#!/usr/bin/env bash
# Toggle swaync notifications (Do Not Disturb)

toggle() {
    swaync-client -t -sw
}

status() {
    dnd=$(swaync-client -D 2>/dev/null)
    count=$(swaync-client -c 2>/dev/null)

    if [[ "$dnd" == "true" ]]; then
        echo '{"text": "󰂛", "tooltip": "Notifications: OFF (Do Not Disturb)", "class": "dnd"}'
    elif [[ "$count" -gt 0 ]]; then
        echo "{\"text\": \"󰂚 $count\", \"tooltip\": \"Notifications: $count unread\", \"class\": \"active\"}"
    else
        echo '{"text": "󰂚", "tooltip": "Notifications: ON", "class": "active"}'
    fi
}

case "$1" in
    toggle) toggle ;;
    *) status ;;
esac
