#!/usr/bin/env bash
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

temp=$(get_temp)

if [[ "$temp" == "N/A" ]]; then
    echo '{"text": "TEMP: N/A", "tooltip": "Temperature unavailable"}'
elif [[ "$temp" -ge 80 ]]; then
    echo "{\"text\": \"TEMP: ${temp}°C\", \"tooltip\": \"CPU Temperature: ${temp}°C\", \"class\": \"critical\"}"
elif [[ "$temp" -ge 60 ]]; then
    echo "{\"text\": \"TEMP: ${temp}°C\", \"tooltip\": \"CPU Temperature: ${temp}°C\", \"class\": \"warning\"}"
else
    echo "{\"text\": \"TEMP: ${temp}°C\", \"tooltip\": \"CPU Temperature: ${temp}°C\", \"class\": \"normal\"}"
fi
