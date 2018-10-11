#!/bin/zsh
set -x

# TODO: Really dumb to sleep to avoid a race condition . . . but this is meant to be very dirty

pause_exit() {
    print -- $'\e[4;97m'"${1:-Press any key to exit . . .}"$'\e[0;37m'
    read -k1 -s
    exit $1
}
die() {
    print -- $'\e[1;91mERROR: \e[1;97m'"$1"$'\e[0;37m'
    pause_exit
    exit 1
}

declare DEBUG_CFG_PATH="$HOME/.config/zsh/debug.lib"
declare RID="$1"
declare DEBUG_WAIT="$DEBUG_CFG_PATH/debug.$RID.wait"
declare THIS_STDOUT="${${(Ms< >)${(f)$(ps ax)}[@]:#$$*}[2]}"

[[ -d "$DEBUG_CFG_PATH" && -e "$DEBUG_WAIT" ]] && {
    print -- 'Debug monitor started - to terminate, press any key in this pane'
    echo "$THIS_STDOUT" > "$DEBUG_WAIT"
    pause_exit ''
} || {
    die "The monitor appears to have been run before a debugging session was started; this should not be run on its own"
}
