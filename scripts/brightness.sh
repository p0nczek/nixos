#!/usr/bin/env bash
CACHE="$HOME/.cache/monitor_brightness"
STEP=10
BUS=2
ID_FILE="$HOME/.cache/brightness_id"

[ ! -f "$CACHE" ] && echo "50" > "$CACHE"
CURRENT=$(cat "$CACHE")

case "$1" in
    up)   NEW=$((CURRENT + STEP)); [ $NEW -gt 100 ] && NEW=100 ;;
    down) NEW=$((CURRENT - STEP)); [ $NEW -lt 0 ] && NEW=0 ;;
    set)  NEW=$2 ;;
    *)    echo "Użycie: $0 up|down|set <wartość>"; exit 1 ;;
esac

ddcutil --bus $BUS --noverify setvcp 10 $NEW 2>/dev/null
echo $NEW > "$CACHE"

ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)
ID=$(notify-send --replace-id="$ID" --print-id -t 800 "Jasność" "$NEW%")
echo "$ID" > "$ID_FILE"
