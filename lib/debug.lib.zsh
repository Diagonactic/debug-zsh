#!/bin/zsh

__debug/die() {
    print -- $'\e[1;91mBUGZSH ERROR: '"$1"
    exit "${2:-1}"
}

function eval-debug() {
    local -i IS_ERROR="$1"
    local -i IX=2

    if (( ${#${funcsourcetrace[@]}} == 0 )); then
        local -a    traces=( "${${(@)funcsourcetrace:$IX}[@]%%:*}" ) \
                    tracelines=( "${${(@)funcfiletrace:$(( IX - 1 ))}[@]##*:}" ) \
                    funcs=( "${${(@)funcstack:$IX}[@]}" )
    else
        IX=1
        local -a    traces=( "${${(@)funcfiletrace:$IX}[@]%%:*}" ) \
                    tracelines=( "${${(@)funcfiletrace:$IX}[@]##*:}" ) \
                    funcs=( "${${(@)funcfiletrace:$IX}[@]%%:*}" )
    fi
    local -a abs_traces=( "${traces[@]:A}" )

    (( ${#traces} > 0 )) || return 1
    integer i=0

    to_relative_traces() { while (( $# >= 1 )); do to-relative-path "$1"; shift; done  }

    send_to/monitor "local -ar traces=( ${(j< >)${(qqq@)abs_traces[@]}} ) tracelines=( ${(j< >)${(qqq@)tracelines[@]}} ) funcs=( ${(j< >)${(qqq@)funcs[@]}} ); local -ri IS_ERROR=\"${IS_ERROR}\"" nowait
}

notify_monitor_of_data() {
    print -- "${functrace[1]}" > "$DEBUGGER_PIPE"
}

to_monitor() {

    debug_traces=( "${(@f)$(to_relative_traces)}" )
    debug_functions=( "${funcs[@]}" )
    debug_trace_lines=( "${tracelines[@]}" )
    send_to/monitor "local -ar debug_traces=( ${j< >${(qqq@)debug_traces[@]}} ) debug_trace_lines=( ${j< >${(qqq@)debug_trace_lines[@]}} ) debug_functions=( ${j< >${(qqq@)debug_functions[@]}} )"
}

is-in-debug-library() { [[ "${1%:*}" == "$DEBUG_ZSH_DIR"/* ]]; }

TRAPDEBUG() {
    is-in-debug-library "${${${funcfiletrace[1]}:-${funcsourcetrace[2]}}:A}" && return 0 || eval-debug 0
    local CMD=''
    wait_for/monitor CMD
}
TRAPZERR() {
    print -l -- "$@"
    eval-debug 1
    __dzsh die "The script failed with an error"
}