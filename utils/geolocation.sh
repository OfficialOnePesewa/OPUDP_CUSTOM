#!/bin/bash
get_geolocation() {
    local ip="$1"
    local data=$(curl -s "https://ipapi.co/$ip/json/")
    if command -v jq &>/dev/null; then
        city=$(echo "$data" | jq -r '.city // "Unknown"')
        country=$(echo "$data" | jq -r '.country_name // "Unknown"')
        echo "$city, $country"
    else
        echo "Unknown"
    fi
}

get_server_location() {
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    get_geolocation "$ip"
}
