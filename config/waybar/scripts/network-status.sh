#!/usr/bin/env bash
# Network status with connectivity check
# Green: connected with internet
# Amber: connected but no internet
# Red: disconnected

# Check connection type
ethernet=$(ip link show 2>/dev/null | grep -E "^[0-9]+: (eth|enp)" | grep "state UP" | head -1)
wifi=$(iwgetid -r 2>/dev/null)

# Determine connection type and interface
if [[ -n "$ethernet" ]]; then
    conn_type="ethernet"
    icon_connected="󰈀"
    interface=$(echo "$ethernet" | cut -d: -f2 | tr -d ' ')
elif [[ -n "$wifi" ]]; then
    conn_type="wifi"
    icon_connected="󰤨"
else
    # No connection
    echo '{"text": "󰤭", "tooltip": "No network connection", "class": "disconnected"}'
    exit 0
fi

# Check for internet connectivity
if ping -c 1 -W 2 1.1.1.1 &>/dev/null || ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    # Connected with internet
    if [[ "$conn_type" == "wifi" ]]; then
        tooltip="WiFi: $wifi (Online)"
    else
        tooltip="Ethernet: $interface (Online)"
    fi
    echo "{\"text\": \"$icon_connected\", \"tooltip\": \"$tooltip\", \"class\": \"connected\"}"
else
    # Connected but no internet
    if [[ "$conn_type" == "wifi" ]]; then
        tooltip="WiFi: $wifi (No Internet)"
        icon="󰤫"
    else
        tooltip="Ethernet: $interface (No Internet)"
        icon="󰈂"
    fi
    echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\", \"class\": \"no-internet\"}"
fi
