#!/bin/zsh
# Requires monitor.lib.zsh
declare TERM_LIB_DIR="${${${${(%):-%x}:A}:h}:A}"

zmodload zsh/parameter zsh/terminfo
setopt localoptions extendedglob shortloops
ticode() { 2>/dev/null echoti "$1" }

# Initialize Globals Used by Library
typeset -ah target_keycombinations=(
	{dim-{italic,underline,italic-underline,italic-underline-reverse},bold-{italic,underline,italic-underline,italic-underline-reverse},underline-{italic,{reverse,italic-reverse}}}
)

typeset -Ag fg=( ) bg=( ) attr=(
	bold 			"$(ticode bold)"
	dim				"$(ticode dim)"
	italic			"$(ticode sitm)"
	reverse			"$(ticode rev)"
	standout        "$(ticode smso)"
	underline		"$(ticode smul)"
	blink 			"$(ticode blink)"
	strikethrough   "$(ticode smxx)"
) exit_attr=(
	underline 		"$(ticode rmul)"
	italic			"$(ticode ritm)"
	standout        "$(ticode rmso)"
) cmds=(
	'reset'			"$(ticode sgr0)"
	'clear'			"$(ticode clear)"
	'clear-to-bol'  "$(ticode el1)"
	'clear-to-eol'  "$(ticode el)"
	'clear-to-eos'  "$(ticode ed)"
) supports=(
	'truecolor'     "$(ticode Tc)"
)
target_keycombinations+=( "${(k)attr[@]}" )

# Get base attributes that are unsupported by this terminal session
typeset -agU unsupported_attrs=( )
() {
	while (( $# > 0 )); do [[ -n "${attr[$1]}" ]] || unsupported_attrs+=( "$1" ); shift; done
} "${(k)attr[@]}"

() {
	while (( $# > 0 )); do
		local KEY="$1"
		() {
			while (( $# > 0 )); do
				attr[$KEY]+="${attr[$1]}"
				if (( ${unsupported_attrs[(i)$1]} <= ${#${unsupported_attrs[@]}} )); then
					unsupported_attrs+=( "$KEY" )
				fi
				shift
			done

		} ${(oi@s<->)KEY}
		shift
	done
} "${target_keycombinations[@]}"

# Add the 'reset' capability
attr+=( 'reset' "$(ticode sgr0)" )

typeset -agU supported_end_attrs=( ) all_attrs=( "${(oik)attr[@]}" ) supported_attrs=( ${${${${(oik)attr[@]}:|unsupported_attrs}[@]}:#*-*} )

function concmds/{clear{,-to-{bol,eol,eos}},reset} {
	print -n -- "${cmds[${0##*/}]}"
}
function consupports/truecolor {
	case "${0##*/}" in
		(truecolor) [[ "${supports[${0##*/}]}" == yes ]] ;;
	esac
}

typeset -gA out_color_map=(
    info    "${fg[light-white]}${attr[bold]}INFO${attr[reset]}: ${fg[white]}"
    warn    "${fg[light-yellow]}${attr[bold]}WARN${attr[reset]}: ${fg[light-white]}${attr[reset]}"
    error    "${fg[light-red]}${attr[bold]}ERROR${attr[reset]}: ${fg[light-white]}${attr[reset]}"
)

function out-{info,warn,error} {
    local {OPT{,ARG}}=''; local -i OPTIND=0; local -aU print_opts=( '--' )
    while getopts n OPT; do
        case "$OPT" in
            (n) print_opts=( '-n' "${print_opts}" ) ;;
        esac
    done
    (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))
    print "${print_opts[@]}" "${out_color_map[${0##*-}]}$1${attr[reset]}"
}

# function printc-{{light-,}{black,red,green,yellow,blue,magenta,cyan,white},darg-gray} {
#     local {OPT{,ARG},ATTR}=''; local -i {OPTIND}=0; local -i {XLOC,YLOC}=-1 local -a print_opts=( '--' )
#     while getopts x:y:na: OPT; do
#         case "$OPT" in
#             (a) ATTR="$OPTARG"
#                 [[ -n "$ATTR" && "${+attr[$ATTR]}" == 1 ]] && ATTR="${attr[$ATTR]}" || ATTR=''
#                 ;;
#             (n) print_opts=( '-n' "${print_opts}" ) ;;
#             (x) [[ "$OPTARG" ~= '^[0-9]+$' ]] || continue
#                 (( $OPTARG <= $COLUMNS )) || continue
#                 XLOC="$OPTARG"
#                 ;;
#             (y) [[ "$OPTARG" ~= '^[0-9]+$' ]] || continue
#                 (( $OPTARG <= $LINES )) || continue
#                 YLOC="$OPTARG"
#                 ;;
#         esac
#     done
#     (( OPTIND > 1 )) && shift $(( OPTIND - 1 ))
#     if   (( XLOC > 0 && YLOC > 0 )); then

#     elif (( XLOC > 0 )); then
#     elif (( YLOC > 0 )); then

#     fi
#     print "${print_opts[@]}" "${fg[${0#*-}]}$ATTR${(j< >)@}${attr[reset]}"
# }

() {
    local -A cname_map=(
        black     		0
        red       		1
        green     		2
        yellow    		3
        orange    		3
        blue      		4
        purple    		5
        magenta   		5
        cyan      		6
        white     		7
        gray      		7
		dark-gray 		8
		light-red 		9
		light-green 	10
		light-yellow 	11
		light-blue   	12
		light-purple	13
		light-magenta	13
		light-cyan		14
		light-white		15
		bright-white    15
    )
    local ATTROFF="$(echoti sgr0)" BOLD="$(echoti bold)"
    typeset -Ag fg=( ) bg=( )
    typeset -a name_keys=( "${(koi)cname_map[@]}" )
    typeset {{F,B}G,{ATTR,KEY,KEYV,CKEY}}=''
    integer i=0
    for (( i=0; i<16; i++ )); do
        FG="$(echoti setaf $i)"
        BG="$(echoti setab $i)"
        fg+=( $i "$FG" )
        bg+=( $i "$BG" )
    done

    for KEY in ${(oin)name_keys[@]}; do
		KEYV="${cname_map[$KEY]}"
		FG="${fg[$KEYV]}"
		fg+=( "$KEY" "$FG" )
    done
}