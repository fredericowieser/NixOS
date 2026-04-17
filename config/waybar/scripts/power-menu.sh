#!/usr/bin/env bash
# Power menu using wofi

OPTIONS="󰐥  Shutdown\n󰜉  Reboot\n󰤄  Sleep\n󰍃  Logout\n󰌾  Lock"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power" --width 200 --height 250 --cache-file /dev/null)

case "$CHOICE" in
    *"Shutdown"*)
        systemctl poweroff
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Sleep"*)
        systemctl suspend
        ;;
    *"Logout"*)
        hyprctl dispatch exit
        ;;
    *"Lock"*)
        hyprlock || swaylock || loginctl lock-session
        ;;
esac
