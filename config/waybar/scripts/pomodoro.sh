#!/usr/bin/env bash
# Pomodoro timer for Waybar
# Click: Start/Pause
# Right-click: Reset
# 50min work / 10min break

STATE_FILE="/tmp/waybar-pomodoro-state"
WORK_DURATION=3000    # 50 minutes in seconds
BREAK_DURATION=600    # 10 minutes in seconds

# Initialize state file if needed
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "idle:0:0" > "$STATE_FILE"
    fi
}

get_state() {
    init_state
    cat "$STATE_FILE"
}

set_state() {
    echo "$1:$2:$3" > "$STATE_FILE"
}

format_time() {
    local seconds=$1
    printf "%02d:%02d" $((seconds / 60)) $((seconds % 60))
}

toggle() {
    IFS=':' read -r state remaining start_time <<< "$(get_state)"
    now=$(date +%s)

    case "$state" in
        idle)
            # Start work session
            set_state "work" "$WORK_DURATION" "$now"
            notify-send -u low "Pomodoro" "Work session started (50 min)"
            ;;
        work)
            # Pause work
            elapsed=$((now - start_time))
            new_remaining=$((remaining - elapsed))
            [[ $new_remaining -lt 0 ]] && new_remaining=0
            set_state "paused_work" "$new_remaining" "0"
            ;;
        break)
            # Pause break
            elapsed=$((now - start_time))
            new_remaining=$((remaining - elapsed))
            [[ $new_remaining -lt 0 ]] && new_remaining=0
            set_state "paused_break" "$new_remaining" "0"
            ;;
        paused_work)
            # Resume work
            set_state "work" "$remaining" "$now"
            ;;
        paused_break)
            # Resume break
            set_state "break" "$remaining" "$now"
            ;;
    esac
}

reset() {
    set_state "idle" "0" "0"
    notify-send -u low "Pomodoro" "Timer reset"
}

status() {
    IFS=':' read -r state remaining start_time <<< "$(get_state)"
    now=$(date +%s)

    case "$state" in
        idle)
            echo '{"text": "󰔟 Start", "tooltip": "Pomodoro: Click to start (50min work)", "class": "idle"}'
            ;;
        work)
            elapsed=$((now - start_time))
            left=$((remaining - elapsed))
            if [[ $left -le 0 ]]; then
                # Work done, start break
                set_state "break" "$BREAK_DURATION" "$now"
                notify-send -u normal "Pomodoro" "Work session complete! Take a 10 min break."
                echo "{\"text\": \"󰔟 Break $(format_time $BREAK_DURATION)\", \"tooltip\": \"Break time!\", \"class\": \"break\"}"
            else
                echo "{\"text\": \"󰔟 $(format_time $left)\", \"tooltip\": \"Working... $(format_time $left) remaining\", \"class\": \"work\"}"
            fi
            ;;
        break)
            elapsed=$((now - start_time))
            left=$((remaining - elapsed))
            if [[ $left -le 0 ]]; then
                # Break done, back to idle
                set_state "idle" "0" "0"
                notify-send -u normal "Pomodoro" "Break over! Ready for next session."
                echo '{"text": "󰔟 Start", "tooltip": "Break complete! Click to start new session", "class": "idle"}'
            else
                echo "{\"text\": \"󰾆 $(format_time $left)\", \"tooltip\": \"Break... $(format_time $left) remaining\", \"class\": \"break\"}"
            fi
            ;;
        paused_work)
            echo "{\"text\": \"󰏤 $(format_time $remaining)\", \"tooltip\": \"Work paused - Click to resume\", \"class\": \"paused\"}"
            ;;
        paused_break)
            echo "{\"text\": \"󰏤 $(format_time $remaining)\", \"tooltip\": \"Break paused - Click to resume\", \"class\": \"paused\"}"
            ;;
        *)
            set_state "idle" "0" "0"
            echo '{"text": "󰔟 Start", "tooltip": "Pomodoro: Click to start", "class": "idle"}'
            ;;
    esac
}

case "$1" in
    toggle) toggle ;;
    reset) reset ;;
    *) status ;;
esac
