#!/bin/bash

: ${TERM=linux}
export TERM

__aneth_cli_colorize() {
	local color="${1}"; shift
	local tput_color=$(tput colors 2>/dev/null)
	test -z "${tput_color}" && tput_color=0
	echo "$(test ${tput_color} -ge 8 && printf "$(printf "${color}"|tput -S)${@}$(tput sgr0)" || echo "${@}")"
}

AETEN_CLI_LEVEL_FATAL=0
AETEN_CLI_LEVEL_ERROR=$((${AETEN_CLI_LEVEL_FATAL}+1))
AETEN_CLI_LEVEL_WARNING=$((${AETEN_CLI_LEVEL_ERROR}+1))
AETEN_CLI_LEVEL_INFORMATION=$((${AETEN_CLI_LEVEL_WARNING}+1))
AETEN_CLI_LEVEL_INFO=${AETEN_CLI_LEVEL_INFORMATION}
AETEN_CLI_LEVEL_DEBUG=$((${AETEN_CLI_LEVEL_INFORMATION}+1))
AETEN_CLI_LEVEL_TRACE=$((${AETEN_CLI_LEVEL_DEBUG}+1))


: ${AETEN_CLI_CONFIG_FILE=$(for prefix in /etc/ ~/. ~/.config/ ~/.etc/; do echo ${prefix}aneth-cli; done)}
for config_file in ${AETEN_CLI_CONFIG_FILE}; do
	[ -f ${config_file} ] && . ${config_file}
done

: ${AETEN_CLI_LEVEL=${AETEN_CLI_LEVEL_INFO}}
: ${AETEN_CLI_INFORMATION=INFO}
: ${AETEN_CLI_WARNING=WARN}
: ${AETEN_CLI_SUCCESS=OK}
: ${AETEN_CLI_FAILURE=FAIL}
: ${AETEN_CLI_DEBUG=DEBU}
: ${AETEN_CLI_TRACE=TRAC}
: ${AETEN_CLI_QUERY=WARN}
: ${AETEN_CLI_ANSWERED=INFO}
: ${AETEN_CLI_PROGRESS=}
: ${AETEN_CLI_VERBOSE==>}
: ${AETEN_CLI_OPEN_BRACKET=[ }
: ${AETEN_CLI_CLOSE_BRACKET= ]}
: ${AETEN_CLI_INVALID_REPLY_MESSAGE=%s: Invalid reply (%s was expected).}
: ${AETEN_CLI_YES_DEFAULT='[Yes|no]:'}
: ${AETEN_CLI_NO_DEFAULT='[yes|No]:'}
: ${AETEN_CLI_YES_PATTERN='y|yes|Yes|YES'}
: ${AETEN_CLI_NO_PATTERN='n|no|No|NO'}
: ${AETEN_CLI_SHADOW=*}

__aneth_cli_string_length() {
	printf "${@}"|wc -m
}

__aneth_cli_add_padding() {
	local length
	local string
	local string_length
	local padding_left
	local padding_right
	length=${1}; shift
	string="${@}"
	string_length=$(__aneth_cli_string_length "${string}")
	padding_left=$(( (${length}-${string_length}) / 2 ))
	padding_right=$(( ${padding_left} + (${length}-${string_length}) % 2 ))
	printf "%${padding_left}s%s%${padding_right}s" '' "${string}" ''
}

if [ 0 -eq ${AETEN_CLI_TAG_LENGTH:-0} ]; then
	AETEN_CLI_TAG_LENGTH=0
	for AETEN_CLI_TAG in "${AETEN_CLI_INFORMATION}" "${AETEN_CLI_WARNING}" "${AETEN_CLI_SUCCESS}" "${AETEN_CLI_FAILURE}" "${AETEN_CLI_QUERY}" "${AETEN_CLI_ANSWERED}"; do
		[ ${#AETEN_CLI_TAG} -gt ${AETEN_CLI_TAG_LENGTH} ] && AETEN_CLI_TAG_LENGTH=$(__aneth_cli_string_length "${AETEN_CLI_TAG}")
	done
	unset AETEN_CLI_TAG
fi
AETEN_CLI_EMPTY_TAG=$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} '')
AETEN_CLI_TEXT_ALIGN="$(printf "%$(($(__aneth_cli_string_length "${AETEN_CLI_OPEN_BRACKET}${AETEN_CLI_EMPTY_TAG}${AETEN_CLI_CLOSE_BRACKET}") + 1))s" '')"

AETEN_CLI_INFORMATION="$(__aneth_cli_colorize 'bold\nsetaf 7' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_INFORMATION}")")"
AETEN_CLI_QUERY="$(__aneth_cli_colorize 'bold\nsetaf 3' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_QUERY}")")"
AETEN_CLI_ANSWERED="$(__aneth_cli_colorize 'bold\nsetaf 7' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_ANSWERED}")")"
AETEN_CLI_WARNING="$(__aneth_cli_colorize 'bold\nsetaf 3' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_WARNING}")")"
AETEN_CLI_SUCCESS="$(__aneth_cli_colorize 'bold\nsetaf 2' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_SUCCESS}")")"
AETEN_CLI_FAILURE="$(__aneth_cli_colorize 'bold\nsetaf 1' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_FAILURE}")")"
AETEN_CLI_DEBUG="$(__aneth_cli_colorize 'bold\nsetaf 4' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_DEBUG}")")"
AETEN_CLI_TRACE="$(__aneth_cli_colorize 'bold\nsetaf 4' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_TRACE}")")"
AETEN_CLI_VERBOSE="$(__aneth_cli_colorize 'bold\nsetaf 7' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_VERBOSE}")")"
AETEN_CLI_PROGRESS="$(__aneth_cli_colorize 'bold\nsetaf 7' "$(__aneth_cli_add_padding ${AETEN_CLI_TAG_LENGTH} "${AETEN_CLI_PROGRESS}")")"
AETEN_CLI_OPEN_BRACKET=$(__aneth_cli_colorize 'setaf 7' "${AETEN_CLI_OPEN_BRACKET}")
AETEN_CLI_CLOSE_BRACKET=$(__aneth_cli_colorize 'setaf 7' "${AETEN_CLI_CLOSE_BRACKET}")
AETEN_CLI_TITLE_COLOR='bold\nsetaf 7'
AETEN_CLI_SAVE_CURSOR_POSITION=$(tput sc)
AETEN_CLI_RESTORE_CURSOR_POSITION=$(tput rc)
AETEN_CLI_MOVE_CURSOR_UP=$(tput cuu1)
AETEN_CLI_MOVE_CURSOR_DOWN=$(tput il 1)
AETEN_CLI_CLEAR_LINE=$(tput el1)
AETEN_CLI_CLEAR_UNTIL_EOL=$(tput el)

__aneth_cli_ppid() {
	awk '{print $4}' /proc/${1}/stat 2>/dev/null
}

__aneth_cli_out_fd() {
	local script
	local pid
	pid=${$}
	echo /proc/${pid}/fd/${1}
}

AETEN_CLI_OUTPUT=$(__aneth_cli_out_fd 2)

__aneth_cli_api() {
	sed --quiet --regexp-extended 's/^aneth_cli_([[:alpha:]][[:alnum:]_-]+)\s*\(\)\s*\{/\1/p' "${*}" 2>/dev/null
}

__aneth_cli_is_api() {
	test 1 -eq $(__aneth_cli_api "${1}"|grep -F "${2}"|wc -l) 2>/dev/null
}

__aneth_cli_tag() {
	local eol
	local restore
	local moveup
	local tag
	eol="\n"
	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-r) restore=${AETEN_CLI_RESTORE_CURSOR_POSITION};;
			-u) moveup=${AETEN_CLI_MOVE_CURSOR_UP};;
			-n) eol="" ;;
			*) break;;
		esac
		shift
	done
	case "${1}" in
		info|inform) tag="${AETEN_CLI_INFORMATION}";;
		success)     tag="${AETEN_CLI_SUCCESS}";;
		warn)        tag="${AETEN_CLI_WARNING}";;
		error)       tag="${AETEN_CLI_FAILURE}";;
		fatal)       tag="${AETEN_CLI_FAILURE}";;
		query)       tag="${AETEN_CLI_QUERY}";;
		confirm)     tag="${AETEN_CLI_ANSWERED}";;
		verbose)     tag="${AETEN_CLI_VERBOSE}";;
		*)           tag="${1}";;
	esac
	printf "${moveup}\r${AETEN_CLI_OPEN_BRACKET}%s${AETEN_CLI_CLOSE_BRACKET}${restore}${eol}" "${tag}" >${AETEN_CLI_OUTPUT}
}

__aneth_cli_is_log_enable() {
	[ ${AETEN_CLI_LEVEL} -ge $(__aneth_cli_get_log_level ${1}) ] && echo true || echo false
}

__aneth_cli_log() {
	local level
	local eol
	local save
	local message
	eol="\n"
	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-l) level=${2}; shift;;
			-s) save=${AETEN_CLI_SAVE_CURSOR_POSITION};;
			-n) eol="";;
			*) break;;
		esac
		shift
	done
	message="${@}"
	printf "\r${AETEN_CLI_CLEAR_LINE}${AETEN_CLI_OPEN_BRACKET}%s${AETEN_CLI_CLOSE_BRACKET} %s${save}${eol}" "${level}" "$message" >${AETEN_CLI_OUTPUT}
}

aneth_cli_title() {
	local mesage
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	message="${@}"
	echo "${AETEN_CLI_TEXT_ALIGN}$(__aneth_cli_colorize "${AETEN_CLI_TITLE_COLOR}" "${message}")" >${AETEN_CLI_OUTPUT}
}

aneth_cli_inform() {
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	$(__aneth_cli_is_log_enable info) && __aneth_cli_log -l "${AETEN_CLI_INFORMATION}" "${@}"
}

aneth_cli_success() {
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	$(__aneth_cli_is_log_enable info) && __aneth_cli_log -l "${AETEN_CLI_SUCCESS}" "${@}"
}

aneth_cli_warn() {
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	$(__aneth_cli_is_log_enable warn) && __aneth_cli_log -l "${AETEN_CLI_WARNING}" "${@}"
}

aneth_cli_error() {
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	$(__aneth_cli_is_log_enable error) && __aneth_cli_log -l "${AETEN_CLI_FAILURE}" "${@}"
}

aneth_cli_fatal() {
	local usage
	local errno
	usage="${FUNCNAME:-${0}} [--help|h] [--errno|-e <errno>] [--] <message>"
	errno=1

	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-e|--errno)   errno=${2}; shift ;;
			-h|--help)    echo "${usage}" >&2; exit 0 ;;
			--)           shift; break ;;
			-*)           echo "Usage: ${usage}" >&2; exit 1 ;;
			*)            break ;;
		esac
		shift
	done
	[ 0 -lt ${#} ] || { echo "Usage: ${usage}" >&2 ; exit 2; }
	$(__aneth_cli_is_log_enable fatal) && __aneth_cli_log -l "${AETEN_CLI_FAILURE}" "${@}"
	case "$(basename ${0})" in
		fatal|check|aneth-cli.sh) kill -s ABRT ${PPID};;
		*) exit ${errno};;
	esac
}

aneth_cli_debug() {
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	$(__aneth_cli_is_log_enable debug) && __aneth_cli_log -l "${AETEN_CLI_DEBUG}" "${@}"
}

aneth_cli_trace() {
	[ 0 -lt ${#} ] || { echo "Usage: ${FUNCNAME:-${0}} <message>" >&2 ; exit 1; }
	$(__aneth_cli_is_log_enable trace) && __aneth_cli_log -l "${AETEN_CLI_TRACE}" "${@}"
}

aneth_cli_get_log_level() {
	case "${AETEN_CLI_LEVEL}" in
		${AETEN_CLI_LEVEL_FATAL})       echo fatal;;
		${AETEN_CLI_LEVEL_ERROR})       echo error;;
		${AETEN_CLI_LEVEL_WARNING})     echo warn;;
		${AETEN_CLI_LEVEL_INFORMATION}) echo info;;
		${AETEN_CLI_LEVEL_DEBUG})       echo debug;;
		${AETEN_CLI_LEVEL_TRACE})       echo trace;;
		*) echo "Usage: ${FUNCNAME:-${0}} fatal|error|warn|info|debug|trace" >&2 ; exit 1;;
	esac
}

__aneth_cli_get_log_level() {
	case "${1}" in
		fatal)                   echo ${AETEN_CLI_LEVEL_FATAL};;
		error)                   echo ${AETEN_CLI_LEVEL_ERROR};;
		warn|warning)            echo ${AETEN_CLI_LEVEL_WARNING};;
		info|inform|information) echo ${AETEN_CLI_LEVEL_INFORMATION} ;;
		debug)                   echo ${AETEN_CLI_LEVEL_DEBUG};;
		trace)                   echo ${AETEN_CLI_LEVEL_TRACE};;
		*) echo "Usage: ${FUNCNAME:-${0}} fatal|error|warn|info|debug|trace" >&2 ; exit 1;;
	esac
}

aneth_cli_set_log_level() {
	AETEN_CLI_LEVEL=$(__aneth_cli_get_log_level ${1})
}

__read_shadow() {
	local reply
	local char
	local numeric
	local length
	local new_length
	local out
	local return_code
	out=${1}
	length=0
	(
		[ -t 0 ] && {
			trap "stty $(stty -g)" EXIT INT QUIT
			stty -echo
			stty raw
		}
		while true; do
			char=$(dd bs=1 count=1 2>/dev/null)
			numeric=$(printf "%d" "'${char}")
			if [ ${numeric} -eq 3 ]; then
				reply=
				return 130
			elif [ ${numeric} -eq 13 ] || [ ${numeric} -eq 0 ]; then
				break
			elif [ ${numeric} -eq 127 ]; then
				length=$(( $(__aneth_cli_string_length "${reply}") - 1 ))
				[ ${length} -eq -1 ] && length=0 && continue
				reply=$(echo ${reply}|awk '{ string=substr($0, 0, '${length}'); print string; }')
				printf "\b${AETEN_CLI_CLEAR_UNTIL_EOL}" >${out}
			else
				reply=${reply}${char}
				new_length=$(__aneth_cli_string_length "${reply}")
				[ ${new_length} -gt ${length} ] && printf "${AETEN_CLI_SHADOW}" >${out}
				length=${new_length}
			fi
		done
		echo ${reply}
	)
	return_code=$?
	[ -t 0 ] && echo >${out}
	return ${return_code}
}

aneth_cli_highlight() {
	local color=7
	local termcap='bold\nsetaf 7'
   local tput_color=$(tput colors 2>/dev/null)
	local pattern
	local usage="Usage: highlight [-c|--color <black|red|green|yellow|blue|magenta|cyan|white> | -t|--termcap <tput-capabilities>] regex"
   test -z "${tput_color}" && tput_color=0

   if [ ${tput_color} -lt 8 ]; then
		echo "No colorized terminal!" >&2
		exit 1
	fi

	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-c|--color)
				case "${2}" in
					black)   color=0;;
					red)     color=1;;
					green)   color=2;;
					yellow)  color=3;;
					blue)    color=4;;
					magenta) color=5;;
					cyan)    color=6;;
					white)   color=7;;
					*) printf "Invalid argument.\nUsage: ${usage}\n" >&2; exit 1;;
				esac
				termcap="bold\\nsetaf ${color}"
				shift;;
			-t|--termcap) termcap="${2}"; shift; break;;
			-h|--help)
				echo "Usage: ${usage}"
				exit 0
				;;
			*) break;;
		esac
		shift
	done
	pattern="$@"
	if [ -z "${pattern}" ]; then
		printf "Invalid argument.\nUsage: ${usage}\n" >&2
		exit 1
	fi
	stdbuf -oL awk '{gsub("'"${pattern}"'", "'"$(printf "${termcap}"|tput -S)"'&'"$(tput sgr0)"'"); print}'
}

aneth_cli_query() {
	local out
	local usage
	local opts
	local script
	local shadow
	local return_code
	shadow=false
	usage="${FUNCNAME:-${0}} [--help|-h] [-s|--shadow] [--] <message>"
	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-h|--help)     echo "${usage}" >&2; exit 0 ;;
			-s|--shadow)   shadow=true ;;
			--)            shift; break ;;
			-*)            echo "Usage:\n${usage}" >&2; exit 3 ;;
			*)             break ;;
		esac
		shift
	done
	[ 2 -eq $(basename ${AETEN_CLI_OUTPUT}) ] && out=${AETEN_CLI_OUTPUT} || out=$(__aneth_cli_out_fd 2)
	__aneth_cli_log -n -s -l "${AETEN_CLI_QUERY}" "${*} " > ${out}
	if ${shadow}; then
		REPLY=$(__read_shadow ${out})
	else
		read REPLY
	fi
	return_code=$?
	[ 0 -eq ${return_code} ] || return ${return_code}
	[ -t 0 ] && opts="-u -n"
	__aneth_cli_tag -r ${opts} "${AETEN_CLI_ANSWERED}" >${out}
	printf "\r" >${out}
	printf '%s' "${REPLY}"
}

aneth_cli_confirm() {
	local expected
	local yes_pattern
	local no_pattern
	local usage
	local assert
	local loop
	local reply
	local query_args
	expected=${AETEN_CLI_NO_DEFAULT}
	yes_pattern=${AETEN_CLI_YES_PATTERN}
	no_pattern=${AETEN_CLI_NO_PATTERN}
	assert=0
	usage="${FUNCNAME:-${0}} [--assert|-a] [--yes-pattern <pattern>] [--no-pattern <pattern>] [--] <message>
${FUNCNAME:-${0}} [--assert|-a] [--yes-pattern <pattern>] [--no-pattern <pattern>] [--] <message>
${FUNCNAME:-${0}} [--yes|y] [--loop|-l] [--yes-pattern <pattern>] [--no-pattern <pattern>] [--] <message>
${FUNCNAME:-${0}} [--no|n] [--loop|-l] [--yes-pattern <pattern>] [--no-pattern <pattern>] [--] <message>
\t-y, yes
\t\tPositive reply is default.
\t-n, no
\t\tNegative reply is default.
\t-a, --assert
\t\tReturn code is 2 if reply does not matches patterns.
\t--yes-pattern
\t\tThe extended-regex (see grep) for positive answer.
\t--no-pattern
\t\tThe extended-regex (see grep) for negative answer.
"
	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-y|--yes)      expected=${AETEN_CLI_YES_DEFAULT} ;;
			-n|--no)       expected=${AETEN_CLI_NO_DEFAULT} ;;
			-a|--assert)   assert=1 ;;
			-l|--loop)     loop=1 ;;
			--yes-pattern) yes_pattern=${2}; shift ;;
			--no-pattern)  no_pattern=${2}; shift ;;
			-h|--help)     echo "${usage}" >&2; exit 0 ;;
			--)            shift; break ;;
			-*)            echo "Usage:\n${usage}" >&2; exit 3 ;;
			*)             break ;;
		esac
		shift
	done

	while true; do
		reply=$(aneth_cli_query ${query_args} "${@}" $([ "${yes_pattern}" = "${AETEN_CLI_YES_PATTERN}" ] && echo "${expected}"))
		echo "${reply}" | grep --extended-regexp "${yes_pattern}|${no_pattern}" 2>&1 1>/dev/null && break
		if [ ${loop:-0} -eq 1 ]; then
			printf "${AETEN_CLI_INVALID_REPLY_MESSAGE}\n" "${reply}" "[${yes_pattern}|${no_pattern}]" >${AETEN_CLI_OUTPUT}
		else
			break
		fi
	done
	[ -z "${reply}" ] && { [ ${expected} = ${AETEN_CLI_YES_DEFAULT} ] && return 0 || return 1; }
	echo "${reply}" | grep --extended-regexp "${yes_pattern}" 2>&1 1>/dev/null && return 0
	echo "${reply}" | grep --extended-regexp "${no_pattern}" 2>&1 1>/dev/null && return 1
	[ ${assert:-0} -eq 0 ] && { [ ${expected} = ${AETEN_CLI_YES_DEFAULT} ] && return 0 || return 1; } || return 2
}

aneth_cli_check() {
	local level
	local message
	local errno
	local output
	local mode
	local mode_usage
	local usage
	local is_log_enable
	usage="${FUNCNAME:-${0}} [--quiet|-q] [--verbose|-v] [--level|-l warn|error|fatal] [--errno|-e <errno>] [--message|-m <message>] [--] <command>"
	mode_usage="--quiet and --verbose are incompatible options.\nUsage: ${usage}"
	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-m|--message) message=${2}; shift ;;
			-l|--level)   level=${2}; shift ;;
			-e|--errno)   errno=${2}; shift ;;
			-v|--verbose) [ -z ${mode:-} ] && mode=verbose || { echo "Usage: ${mode_usage}" >&2; exit 3; } ;;
			-q|--quiet)   [ -z ${mode:-} ] && mode=quiet   || { echo "Usage: ${mode_usage}" >&2; exit 3; } ;;
			-h|--help)    echo "${usage}" >&2; exit 0 ;;
			--)           shift; break ;;
			-*)           echo "Usage: ${usage}" >&2; exit 3 ;;
			*)            break ;;
		esac
		shift
	done
	unset mode_usage
	unset usage
	: ${level=fatal}
	is_log_enable=$(__aneth_cli_is_log_enable ${level})
	: ${mode=${is_log_enable}}
	: ${message="${@}"}
	case ${mode} in
		verbose) ${is_log_enable} && {
		         	__aneth_cli_log -s -l "${AETEN_CLI_VERBOSE}" "${message}"
		         	( eval "${@}" >&2 2>${AETEN_CLI_OUTPUT} )
		         } || output=$(eval "${@}" 2>&1);;
		quiet)   output=$(eval "${@}" 2>&1);;
		*)       ${is_log_enable} && __aneth_cli_log -s -n -l "${AETEN_CLI_PROGRESS}" "${message}"
		         output=$(eval "${@}" 2>&1);;
	esac
	[ 0 -eq ${?} ] && errno=0 || errno=${errno:-${?}}
	if [ 0 -eq ${errno} ] && ${is_log_enable}; then
		case ${mode} in
			verbose) aneth_cli_success "${message}";;
			quiet)   ;;
			*)       __aneth_cli_tag success;;
		esac
	elif ${is_log_enable}; then
		case ${mode} in
			verbose) aneth_cli_${level} "${message}";;
			quiet)   __aneth_cli_log -s -l "${AETEN_CLI_VERBOSE}" "${message}"
			         printf "%s\n%s\n" "${*}" "${output}" >${AETEN_CLI_OUTPUT}
			         aneth_cli_${level} "${message}";;
			*)       __aneth_cli_tag verbose
			         printf "%s\n%s\n" "${*}" "${output}" >${AETEN_CLI_OUTPUT}
			         aneth_cli_${level} "${message}";;
		esac
		[ 'fatal' = ${level} ] && exit ${errno}
	fi
	return ${errno}
}

aneth_cli_unterm() {
	local unbuffered
	while [ ${#} -ne 0 ]; do
		case "${1}" in
			-u|--unbuffered) unbuffered=' fflush();' ;;
			*)               echo "Usage: ${FUNCNAME:-${0}} [-u|--unbuffered]" >&2; exit 1 ;;
		esac
		shift
	done
	gawk "{
		gsub(/\\x1B\\[[0-9;]*[a-zA-Z]|\\x1B(\\(B|[0-9]+)/, \"\");
		while (match(\$0, /([^\\r]*)\\r([^\\r]*)(.*)/, group)) {
			\$0 = group[2] substr(\$0, length(group[2])+((length(group[1]) == 0)? 0: 1), length(group[1])-length(group[2])) group[3];
		};
		gsub(/\\\[][]/,\"\");
		print;
		${unbuffered}
	}"
}

aneth_cli_import() {
	local api all import
	all=$(__aneth_cli_api ${1})
	api=$(echo "${all}"|paste -sd\|)
	shift
	[ "${1}" = all ] && [ 1 -eq ${#} ] && import="${all}" || import="${@}"
	for cmd in ${import}; do
		echo ${cmd}|grep -E ${api} >/dev/null || { echo "Unexpected token ${cmd}" >&2; exit 1; }
		eval ${cmd}'() { aneth_cli_'${cmd}' "${@}"; }'
	done
}

if [ aneth-cli.sh = $(basename $(readlink -f $0)) ]; then
	if __aneth_cli_is_api "$(readlink -f $0)" "$(basename $0)"; then
		aneth_cli_$(basename $0) "$@"
	elif [ ! -L $0 ] && __aneth_cli_is_api "$0" "$1"; then
		aneth_cli_cmd=$1
		shift
		if [ import = "${aneth_cli_cmd}" ]; then
			if [ $# -eq 0 ]; then
				__aneth_cli_api $0 | grep -v '^import$'
			else
				echo eval ". $0 && aneth_cli_import $0 \"$@\""
			fi
		else
			aneth_cli_${aneth_cli_cmd} "$@"
		fi
	fi
fi
