#!/bin/zsh
typeset MONITOR_LIB_DIR="${${${${(%):-%x}:A}:h}:A}"
source "${MONITOR_LIB_DIR}/common.lib.zsh"

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
print "${cmds[reset]}"

declare -gi TRACE_LINES="$(( $LINES - 1 ))"
declare XPOS="-1" YPOS="-1"
stack-trace() {
    cursor/goto-xy 0 0
    stack-trace-line() {
        print-code-line() {
            function __debug/p() {
                if (( $lc >= $1 )); then
                    print -n -- "${fg[white]}${attr[bold]}${1}:${attr[reset]} "
                    if [[ "${2:-no}" == yes ]]; then print -n "${attr[bold]}${fg[bright-white]}"; fi
                    print -rn -- "${(V)lines[$1]}"
                    print -- "${attr[reset]}"
                fi
            }
            4="${${:-$DZSH_TARGET_DIRECTORY/$TARGET_FILE}:A}"
            [[ -e "$4" ]] && local -ar lines=( "${(f@)$(<$4)}" ) || local -ar lines=( )
            integer -i lc="${#lines[@]}"
            (( lc > 0 )) || return 0
            if [[ "${3:-short}" == "long" ]] && (( $2 - 1 <= $lc )); then __debug/p $(( $2 - 1 )); fi
            __debug/p $2 yes
            if [[ "${3:-short}" == "long" ]] && (( $2 - 1 <= $lc )); then __debug/p $(( $2 + 1 )); fi
            print -n $'\e[0;37m'
        }

        local TARGET_FILE="$1" LN="$2" FN="${${3:#$1}:-[script code]}"
        local -i wid=$(( $COLUMNS - ( 19 + ${${${FN}:+$(( ${#FN} + 5 ))}:-0} + ${#TARGET_FILE} + 5 ) + ${#LN} ))
        if [[ "$4" == "long" ]]; then
            print -n $'\e[1;97mStack Trace \e[0;37m '
            [[ -z "$FN" ]] || print -n -- $'for \e[1;94m'"$FN"$'\e[0;37m '
            TARGET_FILE="$(realpath "$TARGET_FILE" --relative-to="$DZSH_TARGET_DIRECTORY")"
            print -n 'in '"$TARGET_FILE"
            print $'\e[1;97m'" on $LN ${(r<$wid><->)}"$'\e[0;37m'
        else
            print $'\e[0;90m ... on \e[1;97m'"${LN}"$'\e[0;37m in \e[4;35m'"${FN}"$'\e[0;37m of \e[4;36m'" ${TARGET_FILE}"$'\e[0;37m'
        fi
        #if (( $LN == 53 )); then set -x; fi
        print-code-line "$TARGET_FILE" "$LN" "$4"
    }
    local -i i=0
    for (( i=1; i<${#traces[@]}; i++ )); do
        stack-trace-line "${traces[$i]}" "${tracelines[$i]}" "${funcs[$i]}" ${${${(M)i:#1}:+long}:-short}
    done
    cursor/get-xy
}


declare -A cmd_keys=(
    n next
)
declare -A cmd_desc=(
    n 'Next Script Command'
)

pause_exit() {
    print -- "${fg[white]}${attr[underline]}${1:-. . . tap a letter to exit . . .}${attr[reset]}"
    read -k1 -s
    exit $1
}
if [[ "${1:-}" == "test" ]]; then
    return 0
fi
