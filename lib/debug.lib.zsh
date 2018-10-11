__debug/die() {
    print -- $'\e[1;91mBUGZSH ERROR: '"$1"
    exit "${2:-1}"
}

to-relative-path() { realpath --relative-to="${${2:-$DZSH_TARGET_DIRECTORY}:A}" "$1" }

function set-debug-vars() {

}

function eval-debug() {
    local -i IX=2

    __debug/nice-debug-line() {
        __debug/print-code-line() {
            function __debug/p() {
                if (( $lc >= $1 )); then print $'\t'"$1: ${lines[$1]}"; fi
            }
            [[ -e "$1" ]] && local -a lines=( "${(f@)$(<$1)}" ) || local -a lines=( )
            integer -i lc="${#lines[@]}"
            (( lc > 0 )) || return 0
            print -n $'\e[0;90m'
            [[ "${3:-short}" == "short" ]] || __debug/p $(( $2 - 1 ))
            print -n $'\e[1;97m'; __debug/p "$2"; print -n $'\e[0;90m'
            [[ "${3:-short}" == "short" ]] || __debug/p $(( $2 + 1 ))
            print -n $'\e[0;37m'
        }

        local TARGET_FILE="$1" LN="$2" FN="${${3:#$1}:-[script code]}"
        local -i wid=$(( $COLUMNS - ( 19 + ${${${FN}:+$(( ${#FN} + 5 ))}:-0} + ${#TARGET_FILE} + 5 ) + ${#LN} ))
        if [[ "$4" == "long" ]]; then
            print -n $'\e[1;97mStack Trace \e[0;37m '
            [[ -z "$FN" ]] || print -n -- $'for \e[1;94m'"$FN"$'\e[0;37m '
            local RELPATH="$(to-relative-path "$TARGET_FILE")"
            print -n 'in '"$RELPATH"
            print $'\e[1;97m'" on $LN ${(r<$wid><->)}"$'\e[0;37m'
        else
            print $'\e[0;90m ... on \e[1;97m'"${LN}"$'\e[0;37m in \e[4;35m'"${FN}"$'\e[0;37m of \e[4;36m'" ${TARGET_FILE}"$'\e[0;37m'
        fi
        if (( $LN == 53 )); then set -x; fi
        __debug/print-code-line "$TARGET_FILE" "$LN" "$4"
    }
    if (( ${#${funcsourcetrace[@]}} == 0 )); then
        local -ar   traces=( "${${(@)funcsourcetrace:$IX}[@]%%:*}" ) \
                    tracelines=( "${${(@)funcfiletrace:$(( IX - 1 ))}[@]##*:}" ) \
                    funcs=( "${${(@)funcstack:$IX}[@]}" )
    else
        IX=1
        local -ar   traces=( "${${(@)funcfiletrace:$IX}[@]%%:*}" ) \
                    tracelines=( "${${(@)funcfiletrace:$IX}[@]##*:}" ) \
                    funcs=( "${${(@)funcfiletrace:$IX}[@]%%:*}" )
    fi

    (( ${#traces} > 0 )) || return 1
    integer i=0

    print -- "local -ar traces=( ${j< >${(qqq@)traces[@]}} ) tracelines=( ${j< >${(qqq@)tracelines[@]}} ) funcs=( ${j< >${(qqq@)funcs[@]}} )"

    # print -- "local -ar ;"
    # print -- "local -ar traces=( ${j< >${(qqq@)traces[@]}} );"

    # for (( i=1; i<=${#traces[@]}; i++ )); do
    #     __debug/nice-debug-line "${traces[$i]}" "${tracelines[$i]}" "${funcs[$i]}" ${${${(M)i:#1}:+long}:-short}
    # done
}

TRAPDEBUG() > "$OUT_PIPE" 2>&1 {
    if [[ "${funcfiletrace[1]}" == */(debug.lib|debug-zsh).zsh ]]; then return 0; fi
    eval-debug
    local CMD=''
    cat "$IN_PIPE" | read CMD
}