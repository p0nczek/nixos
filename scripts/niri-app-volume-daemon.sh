#!/usr/bin/env bash
#
# niri-app-volume-daemon
# Demon w tle przywracający zapisaną głośność per okno (niri window id).
#
# Użycie:
#   ./niri-app-volume-daemon.sh &
#   disown
#
# Logi: $XDG_RUNTIME_DIR/niri-app-volume-daemon.log
# Wymaga: niri, jq, pactl, pw-dump

set -uo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-state.json"
MAP_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-map.json"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-daemon.pid"
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-app-volume-daemon.log"

# --- logowanie ----------------------------------------------------------
log() {
    local level="$1" msg="$2"
    local ts
    ts="$(date -Iseconds)"
    printf '%s [%s] %s\n' "$ts" "$level" "$msg" >> "$LOG_FILE"
}

ensure_file() {
    local f="$1"
    if [ ! -f "$f" ]; then
        echo '{}' > "$f"
    fi
}

ensure_file "$STATE_FILE"
ensure_file "$MAP_FILE"

# --- cleanup on exit ----------------------------------------------------
cleanup() {
    log "INFO" "daemon shutting down (PID $$)"
    rm -f "$PID_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

echo $$ > "$PID_FILE"
log "INFO" "daemon start PID=$$"

# --- sprawdzenie zależności ---------------------------------------------
for cmd in jq pactl pw-dump niri; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "ERROR" "missing dependency: $cmd"
        exit 1
    fi
done
log "INFO" "dependencies OK"

# --- atomowy zapis JSON -------------------------------------------------
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

# --- helper: wyciągnij pole z tekstowego pactl list sink-inputs ---------
get_si_field() {
    local idx="$1" field="$2"
    pactl list sink-inputs 2>/dev/null | awk -v idx="$idx" -v field="$field" '
        /^Sink Input #[0-9]+/ {
            gsub(/[^0-9]/, "", $3);
            cur = $3;
        }
        cur == idx && field == "Name" && /^[[:space:]]*Name:/ {
            print $2;
            exit;
        }
        cur == idx && field == "serial" && /object.serial/ {
            gsub(/"/, "");
            print $3;
            exit;
        }
        cur == idx && field == "Volume" && /^[[:space:]]*Volume:/ {
            match($0, /[0-9]+%/);
            if (RSTART) print substr($0, RSTART, RLENGTH - 1);
            exit;
        }
        cur == idx && /^[[:space:]]*Properties:/ { in_props = 1 }
        cur == idx && in_props && field == "app_name" && /application.name/ {
            gsub(/"/, "");
            print $3;
            exit;
        }
        cur == idx && in_props && field == "media_name" && /media.name/ {
            gsub(/"/, "");
            sub(/^[^=]+= /, "");
            print;
            exit;
        }
        cur == idx && /^$/ { cur = -1; in_props = 0 }
    '
}

# --- handle new sink-input ----------------------------------------------
handle_new() {
    local idx="$1"
    log "DEBUG" "new sink-input #$idx"
    sleep 0.2

    local app_name serial
    app_name="$(get_si_field "$idx" "app_name")"
    serial="$(get_si_field "$idx" "serial")"

    log "DEBUG" "sink-input #$idx app_name='$app_name' serial='$serial'"

    if [ -z "$app_name" ] || [ -z "$serial" ]; then
        log "WARN" "sink-input #$idx: empty app_name or serial (pactl parse failed?)"
        return
    fi

    local pw_json media_name media_title media_artist
    pw_json="$(pw-dump 2>/dev/null | jq -c --argjson s "$serial" '
        [.[] | select(.info.props["object.serial"]? == $s)] | .[0] // {}
    ')"

    if [ -z "$pw_json" ] || [ "$pw_json" = "{}" ]; then
        log "WARN" "sink-input #$idx serial=$serial: pw-dump returned empty"
        return
    fi

    media_name="$(jq -r '.info.props["media.name"] // empty' <<<"$pw_json")"
    media_title="$(jq -r '.info.props["media.title"] // empty' <<<"$pw_json")"
    media_artist="$(jq -r '.info.props["media.artist"] // empty' <<<"$pw_json")"

    log "DEBUG" "sink-input #$idx media_name='$media_name' media_title='$media_title' media_artist='$media_artist'"

    local windows
    windows="$(niri msg -j windows 2>/dev/null || echo '[]')"

    if [ -z "$windows" ] || [ "$windows" = "[]" ]; then
        log "WARN" "niri msg -j windows returned empty"
        return
    fi

    local matched_win_id=""
    local match_method="none"

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
        log "WARN" "sink-input #$idx app='$app_name': no matching niri window found"
        return
    fi

    log "INFO" "sink-input #$idx app='$app_name' -> win_id=$matched_win_id method=$match_method"

    if ! atomic_jq "$MAP_FILE" --arg idx "$idx" --arg wid "$matched_win_id" \
        '. + {($idx): $wid}'; then
        log "ERROR" "atomic_jq failed for MAP_FILE (idx=$idx wid=$matched_win_id)"
        return
    fi

    local saved_vol
    saved_vol="$(jq -r --arg wid "$matched_win_id" '.[$wid] // empty' "$STATE_FILE")"

    if [ -n "$saved_vol" ] && [ "$saved_vol" != "null" ]; then
        log "INFO" "restoring volume ${saved_vol}% for win_id=$matched_win_id"
        pactl set-sink-input-volume "$idx" "${saved_vol}%"
    else
        log "DEBUG" "no saved volume for win_id=$matched_win_id"
    fi
}

# --- handle change (volume update) --------------------------------------
handle_change() {
    local idx="$1"

    local win_id
    win_id="$(jq -r --arg idx "$idx" '.[$idx] // empty' "$MAP_FILE")"
    if [ -z "$win_id" ]; then
        log "DEBUG" "change sink-input #$idx: unknown (not in map)"
        return
    fi

    local vol
    vol="$(get_si_field "$idx" "Volume")"
    if [ -z "$vol" ]; then
        log "WARN" "change sink-input #$idx: could not read volume"
        return
    fi

    log "INFO" "change sink-input #$idx win_id=$win_id -> saving volume=$vol"

    if ! atomic_jq "$STATE_FILE" --arg wid "$win_id" --argjson v "$vol" \
        '. + {($wid): $v}'; then
        log "ERROR" "atomic_jq failed for STATE_FILE (wid=$win_id vol=$vol)"
    fi
}

# --- handle remove ------------------------------------------------------
handle_remove() {
    local idx="$1"
    local win_id
    win_id="$(jq -r --arg idx "$idx" '.[$idx] // empty' "$MAP_FILE")"
    log "INFO" "remove sink-input #$idx win_id=${win_id:-unknown}"
    if ! atomic_jq "$MAP_FILE" --arg idx "$idx" 'del(.[$idx])'; then
        log "ERROR" "atomic_jq failed removing idx=$idx from MAP_FILE"
    fi
}

# --- główna pętla: słuchaj pactl subscribe -----------------------------
log "INFO" "entering main loop (pactl subscribe)"

pactl subscribe 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" =~ Event\ \'new\'\ on\ sink-input\ #([0-9]+) ]]; then
        handle_new "${BASH_REMATCH[1]}" &
    elif [[ "$line" =~ Event\ \'remove\'\ on\ sink-input\ #([0-9]+) ]]; then
        handle_remove "${BASH_REMATCH[1]}" &
    elif [[ "$line" =~ Event\ \'change\'\ on\ sink-input\ #([0-9]+) ]]; then
        handle_change "${BASH_REMATCH[1]}" &
    fi
done