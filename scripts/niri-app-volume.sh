#!/usr/bin/env bash
# niri-app-volume.sh
# Zmienia głośność konkretnego okna/karty w fokusie (nie całej appki naraz)
# i pokazuje/aktualizuje jeden dymek powiadomienia (replaces_id).
#
# Dopasowanie okna: `pactl -f json` ma bug z serializacją nie-ASCII (np.
# cyrylica w tytule) — potrafi zwrócić "(null)" albo uciąć media.name.
# Dlatego tytuły bierzemy z `pw-dump` (surowe, nieuszkodzone dane
# PipeWire) i łączymy po object.serial == index z pactl.
#
# Użycie:
#   niri-app-volume.sh <+N|-N> [nazwa-aplikacji]
# Przykład:
#   niri-app-volume.sh +5            # auto: okno w fokusie w niri
#   niri-app-volume.sh -5            # auto: okno w fokusie w niri
#   niri-app-volume.sh +5 zen        # wymuś appkę, zmień WSZYSTKIE jej strumienie razem

set -euo pipefail

DELTA="${1:?podaj zmianę, np. +5 albo -5}"
FORCED_APP="${2:-}"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# stderr wyciszony: pactl -f json sypie "Invalid non-ASCII character" na
# właściwościach z cyrylicą/emoji itp. — nieszkodliwe, ale głośne.
PACTL_JSON=$(pactl -f json list sink-inputs 2>/dev/null)

FOCUSED_TITLE=""
if [[ -n "$FORCED_APP" ]]; then
    APP_MATCH="$FORCED_APP"
else
    FOCUSED_JSON=$(niri msg -j focused-window 2>/dev/null || echo '{}')
    APP_MATCH=$(jq -r '.app_id // empty' <<<"$FOCUSED_JSON")
    FOCUSED_TITLE=$(jq -r '.title // empty' <<<"$FOCUSED_JSON")
fi

if [[ -z "$APP_MATCH" ]]; then
    echo "Nie udało się ustalić aplikacji (brak fokusu z niri i nie podano appki ręcznie)." >&2
    exit 1
fi

CANDIDATES_JSON=$(jq -c --arg app "$APP_MATCH" \
    '[.[] | select(.properties["application.name"] | ascii_downcase == ($app | ascii_downcase))]' \
    <<<"$PACTL_JSON")

CANDIDATE_COUNT=$(jq 'length' <<<"$CANDIDATES_JSON")

if [[ "$CANDIDATE_COUNT" -eq 0 ]]; then
    echo "Brak aktywnych strumieni audio dla: $APP_MATCH" >&2
    exit 1
fi

TARGET_JSON="$CANDIDATES_JSON"
DISPLAY_TITLE="$APP_MATCH"

# Dopasuj po tytule tylko jeśli mamy >1 kandydata, wiemy jaki tytuł ma okno
# w fokusie, i pw-dump jest dostępny.
if [[ "$CANDIDATE_COUNT" -gt 1 && -n "$FOCUSED_TITLE" ]] && command -v pw-dump >/dev/null 2>&1; then
    PW_MAP_JSON=$(pw-dump | jq -c --arg app "$APP_MATCH" '
        [.[] | select(.info.props["media.class"]? == "Stream/Output/Audio"
            and ((.info.props["application.name"]? // "") | ascii_downcase) == ($app | ascii_downcase))]
        | map({(.info.props["object.serial"] | tostring): .info.props["media.name"]})
        | add // {}
    ')

    MATCHED_JSON=$(jq -c --arg title "$FOCUSED_TITLE" --argjson pwmap "$PW_MAP_JSON" '
        [.[] | . as $c | ($pwmap[($c.index | tostring)] // null) as $mn
         | select($mn != null and ($title | startswith($mn)))
         | $c + {media_name: $mn}]
    ' <<<"$CANDIDATES_JSON")

    MATCHED_COUNT=$(jq 'length' <<<"$MATCHED_JSON")

    if [[ "$MATCHED_COUNT" -ge 1 ]]; then
        TARGET_JSON="$MATCHED_JSON"
        DISPLAY_TITLE=$(jq -r '.[0].media_name' <<<"$MATCHED_JSON")
    fi
    # jeśli MATCHED_COUNT == 0 (żaden tytuł nie pasuje) — zostajemy przy
    # wszystkich kandydatach z CANDIDATES_JSON (bezpieczny fallback,
    # zamiast milczącej odmowy).
fi

mapfile -t TARGET_INDICES < <(jq -r '.[].index' <<<"$TARGET_JSON")

CURRENT_PERCENT=$(jq -r '.[0].volume | to_entries[0].value.value_percent' <<<"$TARGET_JSON" | tr -d '%')

NEW_PERCENT=$(( CURRENT_PERCENT + DELTA ))
if (( NEW_PERCENT < 0 )); then
    NEW_PERCENT=0
elif (( NEW_PERCENT > 150 )); then
    NEW_PERCENT=150
fi

for idx in "${TARGET_INDICES[@]}"; do
    pactl set-sink-input-volume "$idx" "${NEW_PERCENT}%"
done

if (( NEW_PERCENT == 0 )); then
    ICON="audio-volume-muted"
elif (( NEW_PERCENT < 34 )); then
    ICON="audio-volume-low"
elif (( NEW_PERCENT < 67 )); then
    ICON="audio-volume-medium"
else
    ICON="audio-volume-high"
fi

SHORT_TITLE="$DISPLAY_TITLE"
if [[ "${#DISPLAY_TITLE}" -gt 40 ]]; then
    SHORT_TITLE="${DISPLAY_TITLE:0:40}…"
fi

ID_FILE="$STATE_DIR/niri-app-volume-notif-id-${APP_MATCH}"
PREV_ID=0
if [[ -f "$ID_FILE" ]]; then
    PREV_ID=$(cat "$ID_FILE")
fi

REPLY=$(gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    "niri-app-volume" "$PREV_ID" "$ICON" "$SHORT_TITLE" "${NEW_PERCENT}%" "[]" \
    "{'value': <int32 ${NEW_PERCENT}>}" 3000)

NEW_ID=$(grep -oP '(?<=uint32 )[0-9]+' <<<"$REPLY")
echo "$NEW_ID" > "$ID_FILE"

echo "Ustawiono [$SHORT_TITLE] na ${NEW_PERCENT}% (indeksy: ${TARGET_INDICES[*]}, notif id $NEW_ID)"