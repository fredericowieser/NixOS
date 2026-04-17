#!/usr/bin/env bash
# Network status with connectivity check
# Green: connected with internet
# Amber: connected but no internet
# Red: disconnected

# Use nmcli to get connection info (more reliable than iwgetid)
connection_info=$(nmcli -t -f TYPE,NAME,DEVICE connection show --active 2>/dev/null | head -1)

if [[ -z "$connection_info" ]]; then
    # No active connection
    echo '{"text": "󰤭", "tooltip": "No network connection", "class": "disconnected"}'
    exit 0
fi

# Parse connection type and name
conn_type=$(echo "$connection_info" | cut -d: -f1)
conn_name=$(echo "$connection_info" | cut -d: -f2)

# Determine icon based on connection type
case "$conn_type" in
    *wireless*|*wifi*|802-11-wireless)
        icon_connected="󰤨"
        conn_display="WiFi: $conn_name"
        icon_no_internet="󰤫"
        ;;
    *ethernet*|802-3-ethernet)
        icon_connected="󰈀"
        conn_display="Ethernet: $conn_name"
        icon_no_internet="󰈂"
        ;;
    *)
        icon_connected="󰛳"
        conn_display="Connected: $conn_name"
        icon_no_internet="󰲛"
        ;;
esac

# Check for internet connectivity
if ping -c 1 -W 2 1.1.1.1 &>/dev/null || ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    # Connected with internet
    echo "{\"text\": \"$icon_connected\", \"tooltip\": \"$conn_display (Online)\", \"class\": \"connected\"}"
else
    # Connected but no internet
    echo "{\"text\": \"$icon_no_internet\", \"tooltip\": \"$conn_display (No Internet)\", \"class\": \"no-internet\"}"
fi
