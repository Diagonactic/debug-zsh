#!/bin/zsh

typeset DEBUGGER_PIPE="$DEBUG_CFG_PATH/debug.$RID.wait" MONITOR_PIPE="$DEBUG_CFG_PATH/monitor.$RID.wait"

instantiate_debugger() {
    if [[ -e "$DEBUGGER_PIPE" || -e "$MONITOR_PIPE" ]]; then return 1; fi
    mkfifo "$DEBUGGER_PIPE" "$MONITOR_PIPE"
}

function send_to/{monitor,debugger} {
    1="${1:-yes}"
    3="${(P)${:-${(U)0##*/}_PIPE}}"

    #print -- "\n$(date) : $0 - $3"
    print -- "${1:-yes}\n" > "$3"
    if [[ "${2:-}" == nowait ]]; then return 0; fi
    set +x
    "wait_for/${0##*/}" "$2"
}

function wait_for/{monitor,debugger} {

    # We wait on the opposite pipe that we write to
    case "${0##*/}" in
        (monitor)  3="$DEBUGGER_PIPE" ;;
        (debugger) 3="$MONITOR_PIPE"  ;;
    esac
    #print -- "$(date) : $0 - $3"

    local TMP=''
    read ${1:-TMP} < "$3"
}

to-relative-path() { realpath "$1" --relative-to="${${2:-$DZSH_TARGET_DIRECTORY}:A}"  }