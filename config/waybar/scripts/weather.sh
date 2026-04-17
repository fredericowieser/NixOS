#!/usr/bin/env bash
# Weather module using wttr.in API
# Location: London
# Cache: 15 minutes

CACHE_FILE="/tmp/waybar-weather-cache"
CACHE_MAX_AGE=900  # 15 minutes in seconds
LOCATION="London"

# Tokyo Night colors
COLOR_YELLOW="#e0af68"
COLOR_WHITE="#c0caf5"
COLOR_BLUE="#7dcfff"
COLOR_RED="#f7768e"

get_weather() {
    # Check cache
    if [[ -f "$CACHE_FILE" ]]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
            cat "$CACHE_FILE"
            return
        fi
    fi

    # Fetch weather data
    weather_data=$(curl -sf "wttr.in/${LOCATION}?format=j1" 2>/dev/null)

    if [[ -z "$weather_data" ]]; then
        echo '{"text": "󰅤 N/A", "tooltip": "Weather unavailable", "class": "error"}'
        return
    fi

    # Parse data
    temp=$(echo "$weather_data" | jq -r '.current_condition[0].temp_C')
    feels_like=$(echo "$weather_data" | jq -r '.current_condition[0].FeelsLikeC')
    desc=$(echo "$weather_data" | jq -r '.current_condition[0].weatherDesc[0].value')
    humidity=$(echo "$weather_data" | jq -r '.current_condition[0].humidity')
    wind=$(echo "$weather_data" | jq -r '.current_condition[0].windspeedKmph')
    code=$(echo "$weather_data" | jq -r '.current_condition[0].weatherCode')

    # Weather icon based on condition code
    case "$code" in
        113) icon="󰖙"; icon_class="sunny" ;;  # Sunny/Clear
        116) icon="󰖐"; icon_class="cloudy" ;;  # Partly cloudy
        119|122) icon="󰖐"; icon_class="cloudy" ;;  # Cloudy/Overcast
        143|248|260) icon="󰖑"; icon_class="cloudy" ;;  # Fog/Mist
        176|263|266|293|296|299|302|305|308|311|314|317|353|356|359)
            icon="󰖗"; icon_class="rain" ;;  # Rain
        179|182|185|281|284|320|323|326|329|332|335|338|350|362|365|368|371|374|377)
            icon="󰖘"; icon_class="rain" ;;  # Snow/Sleet
        200|386|389|392|395) icon="󰖓"; icon_class="rain" ;;  # Thunder
        227|230) icon="󰼶"; icon_class="rain" ;;  # Blizzard
        *) icon="󰖐"; icon_class="cloudy" ;;  # Default
    esac

    # Temperature class
    if [[ "$temp" -gt 25 ]]; then
        temp_class="hot"
    elif [[ "$temp" -lt 10 ]]; then
        temp_class="cold"
    else
        temp_class="normal"
    fi

    # Build tooltip
    tooltip="${desc}\\nTemperature: ${temp}°C (feels like ${feels_like}°C)\\nHumidity: ${humidity}%\\nWind: ${wind} km/h"

    # Output JSON (compact format: icon + temp only, full description in tooltip)
    output="{\"text\": \"$icon ${temp}°C\", \"tooltip\": \"$tooltip\", \"class\": \"$icon_class $temp_class\"}"

    # Cache result
    echo "$output" > "$CACHE_FILE"
    echo "$output"
}

get_weather
