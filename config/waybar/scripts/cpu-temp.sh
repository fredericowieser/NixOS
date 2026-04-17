#!/usr/bin/env bash
# Combined CPU usage and temperature display for waybar

# Get CPU usage from /proc/stat
get_cpu_usage() {
    # Read first line of /proc/stat
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    # Calculate totals
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle1=$idle

    # Wait briefly and read again
    sleep 0.1

    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle2=$idle

    # Calculate usage percentage
    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))

    if [[ $total_diff -gt 0 ]]; then
        usage=$(( (total_diff - idle_diff) * 100 / total_diff ))
        echo "$usage"
    else
        echo "0"
    fi
}

# Get CPU temperature from available thermal zones
get_temp() {
    # First pass: actual CPU sensors only (exclude acpitz which is ambient temp)
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            type_file="${zone%temp}type"
            if [[ -f "$type_file" ]]; then
                type=$(cat "$type_file")
                # Prioritize real CPU sensors
                if [[ "$type" =~ ^(x86_pkg_temp|coretemp|k10temp|zenpower)$ ]]; then
                    temp=$(cat "$zone")
                    echo $((temp / 1000))
                    return
                fi
            fi
        fi
    done

    # Second pass: try pch_cannonlake (chipset, close to CPU)
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            type_file="${zone%temp}type"
            if [[ -f "$type_file" ]]; then
                type=$(cat "$type_file")
                if [[ "$type" == "pch_cannonlake" ]]; then
                    temp=$(cat "$zone")
                    echo $((temp / 1000))
                    return
                fi
            fi
        fi
    done

    # Third pass: fallback to acpitz only if nothing else found
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            type_file="${zone%temp}type"
            if [[ -f "$type_file" ]]; then
                type=$(cat "$type_file")
                if [[ "$type" == "acpitz" ]]; then
                    temp=$(cat "$zone")
                    echo $((temp / 1000))
                    return
                fi
            fi
        fi
    done

    # Fallback: just use first thermal zone
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo $((temp / 1000))
        return
    fi

    # Try hwmon as fallback
    for hwmon in /sys/class/hwmon/hwmon*/temp1_input; do
        if [[ -f "$hwmon" ]]; then
            temp=$(cat "$hwmon")
            echo $((temp / 1000))
            return
        fi
    done

    echo "N/A"
}

# Get values
cpu_usage=$(get_cpu_usage)
temp=$(get_temp)

# Colors (Tokyo Night theme)
color_cpu="#7aa2f7"      # Blue for CPU
color_sep="#565f89"      # Muted for separator
color_temp="#bb9af7"     # Purple for temperature
color_warning="#e0af68"  # Orange for warning
color_critical="#f7768e" # Red for critical

# Determine temperature color and class based on thresholds
if [[ "$temp" == "N/A" ]]; then
    temp_color="$color_temp"
    temp_class="normal"
elif [[ "$temp" -ge 80 ]]; then
    temp_color="$color_critical"
    temp_class="critical"
elif [[ "$temp" -ge 60 ]]; then
    temp_color="$color_warning"
    temp_class="warning"
else
    temp_color="$color_temp"
    temp_class="normal"
fi

# Format temperature display
if [[ "$temp" == "N/A" ]]; then
    temp_display="N/A"
else
    temp_display="${temp}°C"
fi

# Build the text with Pango markup for independent coloring
text="<span color='${color_cpu}'>CPU: ${cpu_usage}%</span> <span color='${color_sep}'>/</span> <span color='${temp_color}'>&lt;${temp_display}&gt;</span>"

# Build tooltip
tooltip="CPU Usage: ${cpu_usage}%\nTemperature: ${temp_display}"

# Output JSON
echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\", \"class\": \"${temp_class}\"}"
