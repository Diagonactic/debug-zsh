#!/bin/zsh
# Requires monitor.lib.zsh

declare TERM_LIB_DIR="${${${${(%):-%x}:A}:h}:A}"

declare -AHg ti_cursor_map=(
    back_tab    cbt
    home        home
    back        cub
    forward     cuf
    down        cud
)

typeset -AHg ti_termprops_map=(
    can_redefine_colors     ccc
    can_erase_overstrike    eo
    is_cursor_hard_to_see   chts
    has_auto_right_margins  am
)
() {
    local -A cname_map=(
        black   0
        red     1
        green   2
        yellow  3
        orange  3
        blue    4
        purple  5
        magenta 5
        cyan    6
        white   7
        gray    8
    )
    local ATTROFF="$(echoti sgr0)"
    typeset -Ag fg=( ) bg=( )
    typeset -a name_keys="${(k)cname_map[@]}"
    typeset {{F,B}G,KEY}=''
    integer i=0
    for (( i=0; i<=8; i++ )); do
        FG="$(echoti setaf $i)"
        BG="$(echoti setab $i)"
        fg+=( \
            $i          "$FG"         \
            normal-$i   "$ATTROFF$FG" \
        )
        bg+=( \
            $i          "$BG"         \
        )
    done
    for KEY in ${name_keys[@]}; do
        fg+=( \
            "$KEY" "${fg[cname_map[$KEY]]}" \
            "$KEY" "$ATTROFF${fg[cname_map[$KEY]]}" \
        )
    done
}

if [[ "${1:-}" == 'test-term' ]]; then
    source "${TERM_LIB_DIR}/monitor.lib.zsh" test
fi

function cursor/{back{,_tab},forward,down,home} {
    case "${0##*/}" in
        (back|forward|down) (( $# >= 0 || $# <= 1 )) || die "Function $0: Expected 0 or 1 arguments"; echoti "${ti_cursor_map[${0##*/}]}" "${1:-1}" ;;
        (back_tab|home)     (( $# == 0 ))            || die "Function $0: Expected 0 arguments"; echoti "${ti_cursor_map[${0##*/}]}"                ;;
    esac
}

function termprops/{is_cursor_hard_to_see,has_auto_right_margins,can_{redefine_colors,erase_overstrike}} {
    1="${0##*/}"
    [[ "${+ti_termprops_map[$1]}" -eq 1 ]] || die "Term Check Failed - this should never happen"
    local CAP="${${ti_termprops_map[$1]}##:*}"; local VAL="${${${(M)${CAP##*:}:#$CAP}:+yes}:-${CAP##*:}}"
    [[ "${+ti_termprops_map[$CAP]}" -eq 1 && "${terminfo[$CAP]}" == "$VAL" ]]
}

function text/{blink,bold,reset} {
    case "${0##*/}" in
        (blink|bold) echoti "${0##*/}" ;;
    esac
}

if [[ "${1:-}" == 'test-term' ]]; then
    print -n '12345'; cursor/back; print 6
fi