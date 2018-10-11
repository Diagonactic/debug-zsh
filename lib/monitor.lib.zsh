#!/bin/zsh
declare MONITOR_LIB_DIR="${${${${(%):-%x}:A}:h}:A}"
die () {
    print -- "ERROR: $1"
    print -- $'\e[4;97mPress any key to exit . . .\e[0;37m'
    read -k1 -s
}
arg_check() {
    local SPEC="$1"; local -a spec=( "${(s<:>@)1}" ); shift
    (( ${#spec} % 2 == 0 )) || die "Function ${funcstack[1]}: Expected an even number of arguments for the first parameter"
    local -i i=0;
    for (( i = 1; i <= ${#spec}; i += 2 )); do
        local OP="${spec[i]}"; local -i VAL="${spec[i+1]}"
        (( $# $OP $VAL )) || die "Function ${funcstack[1]}: Expected $OP $VAL arguments"
    done
}
alias expect:args='() { arg_check "${argv[-1]}" "${${argv[1,-2]}[@]}" } "$@" '
source "${MONITOR_LIB_DIR}/term.lib.zsh"

# TODO: Really dumb to sleep to avoid a race condition . . . but this is meant to be very dirty
declare -A cmd_keys=(
    n next
)
declare -A cmd_desc=(
    n 'Next Script Command'
)
pause_exit() {
    print -- $'\e[4;97m'"${1:-Press any key to exit . . .}"$'\e[0;37m'
    read -k1 -s
    exit $1
}
if [[ "${1:-}" == "test" ]]; then
    return 0
fi
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
