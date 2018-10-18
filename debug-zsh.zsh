#!/bin/zsh

typeset DZSH_VERSION='0.1.0' DZSH_NAME='debug-zsh' DEBUG_ZSH_FULL_PATH="${${(%):-%x}:A}"
typeset DEBUG_ZSH_DIR="${DEBUG_ZSH_FULL_PATH:h}"

__dzsh() > /dev/tty {
    pifo() {
        print -- $'\e[1;95mINFO\e[1;35m: \e[0;37m'"$1"$'\e[0;37m'
    }
    cprt() {
        print -n -- $'\e['"$1""m$2${3+\e[0;37m}"
    }
    cprtln() {
        print -- $'\e['"$1""m$2${3+\e[0;37m}"
    }
    die() {
        cprt '1;91' "ERROR: "; cprtln "1;97" "$1" clear
        exit "${2:-1}"
    }
    header() {
        cprt '1;97' "$DZSH_NAME"; cprt '0;37' ' version '; cprtln '1;97' "$DZSH_VERSION"$'\n'
        cprt '0;37' 'A Very Uninterestingly Named Zsh Script Assistant'
        print
    }
    usage() {
        cprt '1;97' "$DZSH_NAME"; cprtln '0;37' ' script-to-debug [script-parameters]'
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

builtin setopt extendedglob debugbeforecmd || __dzsh die "Couldn't setopt extendedglob debugbeforecmd; make sure this ZSH installation has those available"
builtin zmodload zsh/parameter zsh/system  || __dzsh die "Couldn't load modules zsh/parameter and zsh/system; make sure this ZSH installation has those available"
__dzsh header

(( $# >= 1 )) || [[ -e "$1" ]] || __dzsh usage $'Missing script or parameter'
[[ -n "$TMUX" ]]               || __dzsh usage $'Must be run in a tmux window'
#set -x
typeset -x DZSH_TARGET="${1:A}"; declare -x DZSH_TARGET_DIRECTORY="${${DZSH_TARGET:h}:A}"; shift
typeset DEBUG_CFG_PATH="$HOME/.config/zsh/debug.lib"
[[ -d "$DEBUG_CFG_PATH" ]] || mkdir -p "$DEBUG_CFG_PATH" || __dzsh die "Failed to create debug configuration path at '$DEBUG_CFG_PATH'"
set +x
typeset THIS_STDOUT="${${(Ms< >)${(f)$(ps ax)}[@]:#$$*}[2]}"

typeset RID="$RANDOM";
source "$DEBUG_ZSH_DIR/lib/common.lib.zsh" || __dzsh die "Failed to source common.lib.zsh"
instantiate_debugger

__dzsh pifo 'Starting monitor and waiting for it to attach'

tmux split-window "$DEBUG_ZSH_DIR/monitor/monitor.zsh $RID ${(qqq)DZSH_TARGET_DIRECTORY}"
wait_for/monitor

__dzsh pifo 'Monitor Available - Starting debugger and application'

source "$DEBUG_ZSH_DIR/lib/debug.lib.zsh"
__dzsh pifo "Setting working directory to \e[1;97m'${DZSH_TARGET_DIRECTORY}'"
pushd "$DZSH_TARGET_DIRECTORY" || __dzsh die "Unable to access directory $DZSH_TARGET_DIRECTORY"
{
    __dzsh pifo "Running '\e[1;97m${DZSH_TARGET:t}\e[0;37m'"
    setopt debugbeforecmd extendedglob
    source -- ${DZSH_TARGET} "$@"
} always { popd }

