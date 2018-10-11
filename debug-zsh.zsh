#!/bin/zsh
declare DZSH_VERSION='0.1.0'
declare DZSH_NAME='debug-zsh'
declare DEBUG_ZSH_DIR="${${${(%):-%x}:A}:h}"

__dzsh() {
    pifo() {
        print -- $'\e[1;95mINFO\e[1;35: \e[0;37m'"$1"$'\e[0;37m'
    }
    cprt() {
        print -n -- $'\e['"$1""m$2${3+\e[0;37m}"
    }
    cprtln() {
        print -- $'\e['"$1""m$2${3+\e[0;37m}"
    }
    die() {
        cprt '1;91' "ERROR:"; cprtln "1;97" "$1" clear
        exit "${2:-1}"
    }
    header() {
        cprt '1;97' "$DZSH_NAME"; cprt '0;37' ' version '; cprtln '1;97' "$DZSH_VERSION"$'\n'
        cprt '0;37' 'A Very Uninterestingly Named Zsh Script Assistant'
        print
    }
    usage() {
        cprt '1;97' "$DZSH_NAME"; cprtln '0;37' 'script-to-debug [script-parameters]'
        print
        print -- 'script-to-debug    - The path to the script to step through'
        print -- 'script-parameters  - The parameters to pass to the script-to-debug'
        print
        print -- 'Must be run from a tmux window'
        (( $# == 0 )) && exit 0 || {
            die "$1"
        }
    }
    "$@"
}

__dzsh header

(( $# >= 1 )) || [[ -e "$1" ]] || __dzsh usage $'Missing script or parameter'
[[ -z "$TMUX" ]]               || __dzsh usage $'Must be run in a tmux window'

declare DEBUG_CFG_PATH="$HOME/.config/zsh/debug.lib"
[[ -d "$DEBUG_CFG_PATH" ]] || mkdir -p "$DEBUG_CFG_PATH" || __dzsh die "Failed to create debug configuration path at '$DEBUG_CFG_PATH'"

declare THIS_STDOUT="${${(Ms< >)${(f)$(ps ax)}[@]:#$$*}[2]}"
__dzsh pifo "Planning to Execute Script on $THIS_STDOUT"

declare RID="$RANDOM"; declare DEBUG_WAIT="$DEBUG_CFG_PATH/debug.$RID.wait"
mkfifo "$DEBUG_WAIT" || die "Couldn't create named pipe"

print -- $'\e[1;97mStarting monitor and waiting for it to attach . . . '
local REMOTE_STDOUT
read REMOTE_STDOUT < "$DEBUG_WAIT"
[[ -z "$REMOTE_STDOUT" || "$REMOTE_STDOUT" == pts/* ]] || __dzsh die "It doesn't appear the monitor started successfully"
print -- $'\e[1;97mSending monitor output to \e[0;37m'"$REMOTE_STDOUT"

source "$DEBUG_ZSH_DIR/debug.lib.zsh"
"$@"
