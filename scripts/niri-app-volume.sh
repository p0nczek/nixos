#!/usr/bin/env bash
#
# niri-app-volume — zmienia głośność aplikacji w aktualnie aktywnym
# (focused) oknie w niri, korzystając z PipeWire/WirePlumber.
# Opcjonalnie pokazuje OSD w Noctalii (jeśli jest zainstalowana).
#
# Wymaga: niri, jq, wpctl (wireplumber), pw-dump (pipewire)
#
# Użycie:
#   niri-app-volume up    [krok%]     np. niri-app-volume up 5
#   niri-app-volume down  [krok%]     np. niri-app-volume down 5
#   niri-app-volume mute
#   niri-app-volume set   <procent>   np. niri-app-volume set 40

set -euo pipefail

ACTION="${1:-}"
ARG="${2:-5}"

command -v jq    >/dev/null || { echo "Brak jq" >&2; exit 1; }
command -v wpctl >/dev/null || { echo "Brak wpctl (wireplumber)" >&2; exit 1; }
command -v pw-dump >/dev/null || { echo "Brak pw-dump (pipewire)" >&2; exit 1; }

if [ -z "$ACTION" ]; then
    echo "Użycie: $0 {up|down|mute|set} [wartość]" >&2
    exit 1
fi

# --- 1. aktywne okno z niri --------------------------------------------
focused="$(niri msg --json focused-window)"
if [ -z "$focused" ] || [ "$focused" = "null" ]; then
    echo "Brak aktywnego okna" >&2
    exit 1
fi

win_pid="$(jq -r '.pid // empty' <<<"$focused")"
win_app="$(jq -r '.app_id // empty' <<<"$focused")"

if [ -z "$win_pid" ]; then
    echo "Niri nie podało PID aktywnego okna" >&2
    exit 1
fi

# --- 2. czy dany pid to nasze okno albo jego potomek --------------------
is_related() {
    local pid="$1"
    while [ -n "$pid" ] && [ "$pid" != "0" ]; do
        [ "$pid" = "$win_pid" ] && return 0
        pid="$(awk '/^PPid:/{print $2; exit}' "/proc/$pid/status" 2>/dev/null || true)"
    done
    return 1
}

# --- 3. dopasuj strumienie audio (Stream/Output/Audio) w pw-dump -------
streams="$(pw-dump | jq -c '
  [ .[] | select(.info.props["media.class"]? == "Stream/Output/Audio")
    | { id,
        pid:  (.info.props["application.process.id"] // empty),
        name: (.info.props["application.name"] // empty) } ]')"

ids=()
while IFS= read -r row; do
    [ -z "$row" ] && continue
    rid="$(jq -r '.id'   <<<"$row")"
    rpid="$(jq -r '.pid' <<<"$row")"
    rname="$(jq -r '.name' <<<"$row")"

    matched=false
    if [ -n "$rpid" ] && [ "$rpid" != "null" ] && is_related "$rpid"; then
        matched=true
    elif [ -n "$win_app" ] && [ -n "$rname" ] && [ "$rname" != "null" ] &&
         { [[ "${rname,,}" == *"${win_app,,}"* ]] || [[ "${win_app,,}" == *"${rname,,}"* ]]; }; then
        matched=true
    fi
    $matched && ids+=("$rid")
done < <(jq -c '.[]' <<<"$streams")

if [ "${#ids[@]}" -eq 0 ]; then
    echo "Nie znaleziono strumienia audio dla: ${win_app:-?} (pid $win_pid)" >&2
    exit 1
fi

# --- 4. zmień głośność ---------------------------------------------------
last_pct=""
for id in "${ids[@]}"; do
    case "$ACTION" in
        up)   wpctl set-volume "$id" "${ARG}%+" ;;
        down) wpctl set-volume "$id" "${ARG}%-" ;;
        mute) wpctl set-mute   "$id" toggle ;;
        set)  wpctl set-volume "$id" "${ARG}%" ;;
        *) echo "Nieznana akcja: $ACTION" >&2; exit 1 ;;
    esac
    last_pct="$(wpctl get-volume "$id" | awk '{printf "%.0f", $2*100}')"
done

echo "${win_app:-?} (pid $win_pid): głośność -> ${last_pct:-?}%"

# --- 5. pokaż OSD: najpierw Noctalia (jeśli jest), inaczej powiadomienie
#        z paskiem postępu przez surowe D-Bus (gdbus). Zamiast liczyć na
#        replaces_id (niektóre demony ignorują je, gdy stare powiadomienie
#        już zniknęło), jawnie zamykamy poprzednie i zawsze tworzymy nowe --
NOTIF_ID_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume.notif-id"

show_osd() {
    local pct="$1" label="${2:-Głośność aplikacji}"

    if command -v noctalia >/dev/null 2>&1; then
        noctalia msg volume-osd "$pct" 2>/dev/null && return
    fi

    command -v gdbus >/dev/null 2>&1 || return 0

    # zamknij poprzedni dymek, jeśli jeszcze wisi (no-op, gdy już zniknął)
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

[ -n "$last_pct" ] && show_osd "$last_pct" "${win_app:-Aplikacja}"
