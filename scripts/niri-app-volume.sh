#!/usr/bin/env bash
#
# niri-app-volume — zmienia głośność aplikacji w aktualnie aktywnym
# oknie w niri, korzystając z PipeWire/WirePlumber.
# PAMIĘTA głośność per okno (niri window id) — nawet gdy zmieni się
# tytuł filmu/piosenki i pojawi się nowy strumień audio.
#
# Wymaga: niri, jq, wpctl (wireplumber), pw-dump (pipewire)
#
# Użycie:
#   niri-app-volume up    [krok%]     np. niri-app-volume up 5
#   niri-app-volume down  [krok%]     np. niri-app-volume down 5
#   niri-app-volume mute
#   niri-app-volume set   <procent>   np. niri-app-volume set 40
#   niri-app-volume +5
#   niri-app-volume -5

set -euo pipefail

ACTION="${1:-}"
ARG="${2:-5}"

# --- normalizacja +/- na up/down z absolutnym przeliczeniem ---
ABSOLUTE=false
if [[ "$ACTION" == +* ]]; then
    ABSOLUTE=true
    DELTA="${ACTION#+}"
    ACTION="up"
elif [[ "$ACTION" == -* ]]; then
    ABSOLUTE=true
    DELTA="${ACTION#-}"
    ACTION="down"
fi

command -v jq      >/dev/null || { echo "Brak jq" >&2;      exit 1; }
command -v wpctl   >/dev/null || { echo "Brak wpctl (wireplumber)" >&2; exit 1; }
command -v pw-dump >/dev/null || { echo "Brak pw-dump (pipewire)" >&2;  exit 1; }

if [ -z "$ACTION" ]; then
    echo "Użycie: $0 {up|down|mute|set} [wartość]   lub   $0 +5 / -5" >&2
    exit 1
fi

# --- plik stanu: niri window id -> volume ------------------------------
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-state.json"
[ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"

# --- 1. aktywne okno z niri --------------------------------------------
focused="$(niri msg --json focused-window)"
if [ -z "$focused" ] || [ "$focused" = "null" ]; then
    echo "Brak aktywnego okna" >&2
    exit 1
fi

win_id="$(jq -r '.id // empty' <<<"$focused")"
win_pid="$(jq -r '.pid // empty' <<<"$focused")"
win_app="$(jq -r '.app_id // empty' <<<"$focused")"
win_title="$(jq -r '.title // empty' <<<"$focused")"

if [ -z "$win_app" ] || [ -z "$win_id" ]; then
    echo "Niri nie podało app_id lub id aktywnego okna" >&2
    exit 1
fi

# --- 2. wszystkie strumienie audio z pw-dump ---------------------------
PW_ALL="$(pw-dump | jq -c --arg app "$win_app" '
    [ .[] | select(.info.props["media.class"]? == "Stream/Output/Audio"
        and ((.info.props["application.name"]? // "") | ascii_downcase) == ($app | ascii_downcase)) ]
')"

PW_COUNT="$(jq 'length' <<<"$PW_ALL")"
if [ "$PW_COUNT" -eq 0 ]; then
    echo "Brak strumieni audio dla: $win_app" >&2
    exit 1
fi

# --- 3. dopasuj po tytule okna (media.name / title / artist) ----------
MATCHED="[]"
if [ -n "$win_title" ]; then
    MATCHED="$(jq -c --arg title "$win_title" '
        [ .[] | . as $s
          | ($s.info.props["media.name"]  // null) as $mn
          | ($s.info.props["media.title"] // null) as $mt
          | ($s.info.props["media.artist"]// null) as $ma
          | [
              (if $mn != null and ($title | startswith($mn)) then {f: $mn, m: "media.name"}  else empty end),
              (if $mt != null and ($title | startswith($mt)) then {f: $mt, m: "media.title"} else empty end),
              (if $ma != null and ($title | startswith($ma)) then {f: $ma, m: "media.artist"}else empty end)
            ] as $hits
          | select($hits | length > 0)
          | $s + {match_field: $hits[0].f, match_method: $hits[0].m} ]
    ' <<<"$PW_ALL")"
fi

MATCH_COUNT="$(jq 'length' <<<"$MATCHED")"
TARGET_JSON="$PW_ALL"
DISPLAY_TITLE="$win_app"

if [ "$MATCH_COUNT" -ge 1 ]; then
    if [ "$MATCH_COUNT" -gt 1 ]; then
        MATCHED="$(jq -c 'sort_by(.info.props["object.serial"] | tonumber) | reverse | .[0:1]' <<<"$MATCHED")"
    fi
    TARGET_JSON="$MATCHED"
    DISPLAY_TITLE="$(jq -r '.[0].match_field' <<<"$MATCHED")"
fi
# jeśli MATCH_COUNT == 0 — zostajemy przy wszystkich (fallback)

# --- 4. zbierz ID strumieni --------------------------------------------
ids=()
while IFS= read -r row; do
    [ -z "$row" ] && continue
    id="$(jq -r '.id' <<<"$row")"
    ids+=("$id")
done < <(jq -c '.[]' <<<"$TARGET_JSON")

if [ "${#ids[@]}" -eq 0 ]; then
    echo "Nie znaleziono strumienia audio dla: $win_app" >&2
    exit 1
fi

# --- 5. odczytaj zapisaną głośność dla tego okna -----------------------
SAVED_VOL="$(jq -r --arg wid "$win_id" '.[$wid] // empty' "$STATE_FILE")"

# --- 6. zmień głośność -------------------------------------------------
last_pct=""
for id in "${ids[@]}"; do
    # odczytaj aktualną głośność tego strumienia
    cur_raw="$(wpctl get-volume "$id")"
    cur_vol="$(awk '{print $2}' <<<"$cur_raw")"
    cur_pct="$(awk "BEGIN {printf \"%d\", $cur_vol * 100}")"

    # jeśli mamy zapisaną głośność i strumień ma inną -> przywróć
    if [ -n "$SAVED_VOL" ] && [ "$cur_pct" != "$SAVED_VOL" ]; then
        wpctl set-volume "$id" "${SAVED_VOL}%"
        cur_pct="$SAVED_VOL"
    fi

    case "$ACTION" in
        up)
            if [ "$ABSOLUTE" = true ]; then
                new_pct="$(( cur_pct + DELTA ))"
                [ "$new_pct" -gt 150 ] && new_pct=150
                wpctl set-volume "$id" "${new_pct}%"
            else
                wpctl set-volume "$id" "${ARG}%+"
            fi
            ;;
        down)
            if [ "$ABSOLUTE" = true ]; then
                new_pct="$(( cur_pct - DELTA ))"
                [ "$new_pct" -lt 0 ] && new_pct=0
                wpctl set-volume "$id" "${new_pct}%"
            else
                wpctl set-volume "$id" "${ARG}%-"
            fi
            ;;
        mute)
            wpctl set-mute "$id" toggle
            ;;
        set)
            wpctl set-volume "$id" "${ARG}%"
            ;;
        *)
            echo "Nieznana akcja: $ACTION" >&2
            exit 1
            ;;
    esac
    last_pct="$(wpctl get-volume "$id" | awk '{printf "%.0f", $2*100}')"
done

# --- 7. zapisz nową głośność pod id okna -------------------------------
if [ -n "$last_pct" ]; then
    jq --arg wid "$win_id" --argjson vol "$last_pct" \
        '. + {($wid): $vol}' "$STATE_FILE" > "${STATE_FILE}.tmp" && \
        mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

echo "$win_app → ${DISPLAY_TITLE}: głośność -> ${last_pct:-?}%"

# --- 8. OSD (1:1 z twojego pliku) -------------------------------------
NOTIF_ID_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume.notif-id"

show_osd() {
    local pct="$1" label="${2:-Głośność aplikacji}"

    if command -v noctalia >/dev/null 2>&1; then
        noctalia msg volume-osd "$pct" 2>/dev/null && return
    fi

    command -v gdbus >/dev/null 2>&1 || return 0

    if [ -f "$NOTIF_ID_FILE" ]; then
        local prev_id
        prev_id="$(cat "$NOTIF_ID_FILE" 2>/dev/null || echo 0)"
        if [[ "$prev_id" =~ ^[0-9]+$ ]] && [ "$prev_id" != "0" ]; then
            gdbus call --session \
                --dest org.freedesktop.Notifications \
                --object-path /org/freedesktop/Notifications \
                --method org.freedesktop.Notifications.CloseNotification \
                "$prev_id" >/dev/null 2>&1
        fi
    fi

    local reply new_id
    reply="$(gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "niri-app-volume" 0 "audio-volume-high" \
        "$label" "${pct}%" "[]" "{'value': <int32 ${pct}>}" 3000 2>/dev/null)"

    new_id="$(grep -oP '(?<=uint32 )[0-9]+' <<<"$reply" | head -n1)"
    [ -n "$new_id" ] && echo "$new_id" > "$NOTIF_ID_FILE"
}

[ -n "$last_pct" ] && show_osd "$last_pct" "$DISPLAY_TITLE"