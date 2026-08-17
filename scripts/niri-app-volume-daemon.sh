#!/usr/bin/env bash
#
# niri-app-volume-daemon
# Demon w tle przywracający zapisaną głośność per okno (niri window id).
# ZAPISUJE TYLKO SKRYPT KLAWISZOWY — demon nie zapisuje na change,
# żeby uniknąć nadpisywania przez aplikacje/WirePlumber.
#
# Logi: $XDG_RUNTIME_DIR/niri-app-volume-daemon.log
# Wymaga: niri, jq, pactl, pw-dump

set -uo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-state.json"
MAP_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-map.json"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-daemon.pid"
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-daemon.log"

log() {
    local level="$1" msg="$2"
    printf '%s [%s] %s\n' "$(date -Iseconds)" "$level" "$msg" >> "$LOG_FILE"
}

ensure_file() {
    local f="$1"
    [ -f "$f" ] || echo '{}' > "$f"
}

ensure_file "$STATE_FILE"
ensure_file "$MAP_FILE"

cleanup() {
    log "INFO" "daemon shutting down (PID $$)"
    rm -f "$PID_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

echo $$ > "$PID_FILE"
log "INFO" "daemon start PID=$$"

for cmd in jq pactl pw-dump niri; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "ERROR" "missing dependency: $cmd"
        exit 1
    fi
done
log "INFO" "dependencies OK"

atomic_jq() {
    local file="$1"
    shift
    ensure_file "$file"
    local tmp="${file}.tmp.$$"
    if jq "$@" "$file" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        mv "$tmp" "$file"
    else
        rm -f "$tmp"
        return 1
    fi
}

get_si_field() {
    local idx="$1" field="$2"
    pactl list sink-inputs 2>/dev/null | awk -v idx="$idx" -v field="$field" '
        /^Sink Input #[0-9]+/ { gsub(/[^0-9]/, "", $3); cur = $3; }
        cur == idx && field == "serial" && /object.serial/ {
            gsub(/"/, ""); print $3; exit;
        }
        cur == idx && /^[[:space:]]*Properties:/ { in_props = 1 }
        cur == idx && in_props && field == "app_name" && /application.name/ {
            gsub(/"/, ""); print $3; exit;
        }
        cur == idx && /^$/ { cur = -1; in_props = 0 }
    '
}

handle_new() {
    local idx="$1"
    log "DEBUG" "new sink-input #$idx"
    sleep 0.2

    local app_name serial
    app_name="$(get_si_field "$idx" "app_name")"
    serial="$(get_si_field "$idx" "serial")"

    log "DEBUG" "sink-input #$idx app_name='$app_name' serial='$serial'"

    if [ -z "$app_name" ] || [ -z "$serial" ]; then
        log "WARN" "sink-input #$idx: empty app_name or serial"
        return
    fi

    local pw_json media_name media_title media_artist
    pw_json="$(pw-dump 2>/dev/null | jq -c --argjson s "$serial" '
        [.[] | select(.info.props["object.serial"]? == $s)] | .[0] // {}
    ')"

    if [ -z "$pw_json" ] || [ "$pw_json" = "{}" ]; then
        log "WARN" "sink-input #$idx serial=$serial: pw-dump empty"
        return
    fi

    media_name="$(jq -r '.info.props["media.name"] // empty' <<<"$pw_json")"
    media_title="$(jq -r '.info.props["media.title"] // empty' <<<"$pw_json")"
    media_artist="$(jq -r '.info.props["media.artist"] // empty' <<<"$pw_json")"

    log "DEBUG" "sink-input #$idx media_name='$media_name' title='$media_title' artist='$media_artist'"

    local windows
    windows="$(niri msg -j windows 2>/dev/null || echo '[]')"

    local matched_win_id="" match_method="none"

    if [ -n "$media_name" ]; then
        matched_win_id="$(jq -r --arg mn "$media_name" --arg app "$app_name" '
            [.[] | select(.app_id == $app and (.title | startswith($mn))) | .id]
            | first // empty
        ' <<<"$windows")"
        [ -n "$matched_win_id" ] && match_method="media.name"
    fi
    if [ -z "$matched_win_id" ] && [ -n "$media_title" ]; then
        matched_win_id="$(jq -r --arg mt "$media_title" --arg app "$app_name" '
            [.[] | select(.app_id == $app and (.title | startswith($mt))) | .id]
            | first // empty
        ' <<<"$windows")"
        [ -n "$matched_win_id" ] && match_method="media.title"
    fi
    if [ -z "$matched_win_id" ] && [ -n "$media_artist" ]; then
        matched_win_id="$(jq -r --arg ma "$media_artist" --arg app "$app_name" '
            [.[] | select(.app_id == $app and (.title | startswith($ma))) | .id]
            | first // empty
        ' <<<"$windows")"
        [ -n "$matched_win_id" ] && match_method="media.artist"
    fi

    if [ -z "$matched_win_id" ]; then
        local focused focused_app
        focused="$(niri msg -j focused-window 2>/dev/null || echo '{}')"
        focused_app="$(jq -r '.app_id // empty' <<<"$focused")"
        if [ "${focused_app,,}" = "${app_name,,}" ]; then
            matched_win_id="$(jq -r '.id // empty' <<<"$focused")"
            match_method="focused-window"
        fi
    fi

    if [ -z "$matched_win_id" ]; then
        log "WARN" "sink-input #$idx app='$app_name': no matching window"
        return
    fi

    log "INFO" "sink-input #$idx app='$app_name' -> win_id=$matched_win_id method=$match_method"

    atomic_jq "$MAP_FILE" --arg idx "$idx" --arg wid "$matched_win_id" \
        '. + {($idx): $wid}' || {
        log "ERROR" "atomic_jq failed MAP_FILE idx=$idx"
        return
    }

    local saved_vol
    saved_vol="$(jq -r --arg wid "$matched_win_id" '.[$wid] // empty' "$STATE_FILE")"

    if [ -n "$saved_vol" ] && [ "$saved_vol" != "null" ]; then
        log "INFO" "restoring volume ${saved_vol}% for win_id=$matched_win_id"
        pactl set-sink-input-volume "$idx" "${saved_vol}%"
    else
        log "DEBUG" "no saved volume for win_id=$matched_win_id (new app?)"
    fi
}

handle_remove() {
    local idx="$1"
    local win_id
    win_id="$(jq -r --arg idx "$idx" '.[$idx] // empty' "$MAP_FILE")"
    log "INFO" "remove sink-input #$idx win_id=${win_id:-unknown}"
    atomic_jq "$MAP_FILE" --arg idx "$idx" 'del(.[$idx])' || \
        log "ERROR" "atomic_jq failed removing idx=$idx"
}

log "INFO" "entering main loop"

pactl subscribe 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" =~ Event\ \'new\'\ on\ sink-input\ #([0-9]+) ]]; then
        handle_new "${BASH_REMATCH[1]}" &
    elif [[ "$line" =~ Event\ \'remove\'\ on\ sink-input\ #([0-9]+) ]]; then
        handle_remove "${BASH_REMATCH[1]}" &
    fi
done