#!/usr/bin/env bash

set -o nounset

usage() {
    cat <<EOT 1>&2
Usage: speedtest.sh [-dh] [-r dir] -c | -o

OPTIONS
=======
-c        run Cloudflare speed test
-d        output debug information
-h        show help
-o        run Ookla speed test
-r dir    use <dir> as output directory

EXAMPLES
========
# run Cloudflare speed test, with output in current directory
$ speedtest.sh -c -r .

EOT

    exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false' # -d
        [SOURCE]=''     # -c or -o
        [MAX_TRIES]=3
        [RETRY_DELAY]=15
        [BYTE_TO_MEGABIT]=0.000008
        [ERRORS_FILE]='' # -r
        [TIMESTAMP]=$(date "+%Y%m%d-%H%M%S")
        [RAW_RESULTS_FILE]='' # -r
        [RESULTS_FILE]=''     # -r
    )
}

debug() {
    if [[ ${GLOBALS[DEBUG]} == 'true' ]]; then
        echo "$@"
    fi
}

set_filenames() {
    local results_dir

    results_dir=$1

    mkdir -p "${results_dir}/errors"
    mkdir -p "${results_dir}/raw"

    GLOBALS[ERRORS_FILE]=${results_dir}/errors/speedtest.txt
    GLOBALS[RAW_RESULTS_FILE]=${results_dir}/raw/results-${GLOBALS[TIMESTAMP]}.json
    GLOBALS[RESULTS_FILE]=${results_dir}/results-${GLOBALS[TIMESTAMP]}.json

    debug "Set base directory to '${results_dir}'."
}

process_options() {
    local OPTARG # set by getopts
    local OPTIND # set by getopts

    [[ $# -eq 0 ]] && usage

    while getopts ":cdhor:" o; do
        case "${o}" in
        c)
            if [[ -n ${GLOBALS[SOURCE]} ]]; then
                usage
            else
                GLOBALS[SOURCE]='Cloudflare'

                GLOBALS[JQ_FILTER]='{ source: "Cloudflare", timestamp: .version.time | todate, ping: .latency_ms.value, download: .["90th_percentile_download_speed"].value, upload: .["90th_percentile_upload_speed"].value }'

                debug "Performing speed test via Cloudflare."
            fi
            ;;

        d)
            GLOBALS[DEBUG]='true'

            debug "Debug mode turned on."
            ;;

        o)
            if [[ -n ${GLOBALS[SOURCE]} ]]; then
                usage
            else
                GLOBALS[SOURCE]='Ookla'

                # shellcheck disable=SC2016
                GLOBALS[JQ_FILTER]=$(printf '( %s | tonumber ) as $byteToMbit | { source: "Ookla", timestamp: .timestamp, ping: .ping.latency, download: ( .download.bandwidth * $byteToMbit ), upload: ( .upload.bandwidth * $byteToMbit ) }' "${GLOBALS[BYTE_TO_MEGABIT]}")

                debug "Performing speed test via Ookla."
            fi
            ;;

        r)
            local results_dir

            results_dir=${OPTARG}

            if [[ ! -d ${results_dir} ]]; then
                echo "Base directory is not actually a directory." >/dev/stderr

                exit
            else
                results_dir=$(realpath "${results_dir}")
            fi

            set_filenames "${results_dir}"
            ;;

        h | *)
            usage
            ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ -z "${GLOBALS[SOURCE]}" ]]; then
        usage
    fi
}

set_defaults() {
    if [[ -z ${GLOBALS[ERRORS_FILE]} || -z ${GLOBALS[RAW_RESULTS_FILE]} || -z ${GLOBALS[RESULTS_FILE]} ]]; then
        set_filenames '/home/speedtest/results'
    fi
}

check_for_dependency() {
    debug "Checking for dependency '$1'."

    if ! command -v "$1" &>/dev/null; then
        printf 'Dependency %s is missing.\n' "$1" >/dev/stderr

        exit
    fi
}

dependency_check() {
    local dependency

    local -a dependencies=(
        'cat'
        'jq'
    )

    case ${GLOBALS[SOURCE]} in
    Cloudflare)
        dependencies+=('cfspeedtest')
        ;;

    Ookla)
        dependencies+=('speedtest')
        ;;
    esac

    for dependency in "${dependencies[@]}"; do
        check_for_dependency "${dependency}"
    done
}

run_speedtest() {
    case ${GLOBALS[SOURCE]} in
    Cloudflare)
        cfspeedtest --json >"${GLOBALS[RAW_RESULTS_FILE]}" 2>>"${GLOBALS[ERRORS_FILE]}"
        ;;

    Ookla)
        speedtest --format=json \
            --accept-license \
            --accept-gdpr >"${GLOBALS[RAW_RESULTS_FILE]}" 2>>"${GLOBALS[ERRORS_FILE]}"
        ;;
    esac
}

format_response() {
    local error_code

    error_code=$1

    if [[ ${error_code} -ne 0 ]]; then
        # insert zeros if failed
        echo "{\"source\":\"Script\",\"timestamp\":\"${GLOBALS[TIMESTAMP]}\",\"ping\":null,\"download\":0,\"upload\":0}" >"${GLOBALS[RESULTS_FILE]}"
    else
        jq "${GLOBALS[JQ_FILTER]}" "${GLOBALS[RAW_RESULTS_FILE]}" >"${GLOBALS[RESULTS_FILE]}" 2>>"${GLOBALS[ERRORS_FILE]}"
    fi
}

main() {
    local error_code

    error_code=0

    init_globals

    process_options "$@"

    set_defaults

    dependency_check

    for ((i = 1; i <= GLOBALS[MAX_TRIES]; i++)); do
        run_speedtest

        error_code=$?

        if [[ ${error_code} -ne 0 ]]; then
            printf '%s: There was an error running speed test for %s.\r\nTry %d: Error Code: %s' "${GLOBALS[TIMESTAMP]}" "${GLOBALS[SOURCE]}" "${i}" "${error_code}" >>"${GLOBALS[ERRORS_FILE]}"

            if [[ $i -lt ${GLOBALS[MAX_TRIES]} ]]; then
                # wait RETRY_DELAY seconds and fall through to retry
                sleep "${GLOBALS[RETRY_DELAY]}"
            fi
        else
            break
        fi
    done

    format_response "${error_code}"
}

main "$@"
