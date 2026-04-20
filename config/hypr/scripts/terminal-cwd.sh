#!/usr/bin/env bash
# Open a new terminal in the same directory as the active terminal window
# Falls back to $HOME if not in a terminal or directory cannot be determined

# Get active window info
active_window=$(hyprctl activewindow -j)

# Check if the active window is a terminal
window_class=$(echo "$active_window" | jq -r '.class // empty')

# List of terminal emulator classes
case "$window_class" in
    kitty|Alacritty|foot|wezterm|gnome-terminal|konsole|xterm|urxvt|terminator)
        # Get the PID of the terminal window
        window_pid=$(echo "$active_window" | jq -r '.pid // empty')

        if [[ -n "$window_pid" ]]; then
            # Find child shell process (bash, zsh, fish, etc.)
            for child_pid in $(pgrep -P "$window_pid"); do
                child_name=$(ps -p "$child_pid" -o comm= 2>/dev/null)
                case "$child_name" in
                    bash|zsh|fish|sh|dash|ksh|tcsh)
                        cwd=$(readlink -f "/proc/$child_pid/cwd" 2>/dev/null)
                        if [[ -n "$cwd" && -d "$cwd" ]]; then
                            exec kitty --directory "$cwd"
                        fi
                        ;;
                esac
            done
        fi
        ;;
esac

# Default: open in home directory
exec kitty --directory "$HOME"
