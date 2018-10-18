#!/bin/zsh
typeset MONITOR_ZSH_DIR="${0:h:A}" MONITOR_ZSH_FULL_PATH="${0:A}" DZSH_TARGET_DIRECTORY="$2"
typeset DEBUG_ZSH_DIR="${MONITOR_ZSH_DIR:h}"
declare DEBUG_CFG_PATH="$HOME/.config/zsh/debug.lib"
typeset RID="$1"
# source "${DEBUG_ZSH_DIR}/lib/common.lib.zsh"
source "${DEBUG_ZSH_DIR}/lib/monitor.lib.zsh"
# print "'$MONITOR_ZSH_DIR' '$MONITOR_ZSH_FULL_PATH' '$DZSH_TARGET_DIRECTORY' '$DEBUG_CFG_PATH' '${DEBUG_ZSH_DIR}' '$RID'"
# sleep 10s
# read -k1 -s
# read -k1 -s
# read -k1 -s
# read -k1 -s
{
    [[ -n "$DZSH_TARGET_DIRECTORY" ]] || die "Couldn't detect target directory"
    [[ -d "$DEBUG_CFG_PATH" && -e "$DEBUGGER_PIPE" ]] && {
        #print -- "${fg[white]}Debug monitor started - to terminate, press any key in this pane"
        send_to/debugger "ready"
        local FROM_DEBUGGER=''
        while true; do
        () {
            [[ -z "$FROM_DEBUGGER" ]] || eval "${FROM_DEBUGGER}"
            stack-trace
            local REQUESTED_COMMAND=''
            print -n -- "Command: "
            read -k1 -s REQUESTED_COMMAND
            send_to/debugger "::cmd:${cmd_keys[n]}" FROM_DEBUGGER || die "Error reported waiting for debugger; exiting"
        }
        done
    } || {
        die "The monitor appears to have been run before a debugging session was started; this should not be run on its own"
    }
} always { pause_exit }