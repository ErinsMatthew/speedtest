#!/usr/bin/env bash

set -o nounset

usage() {
    cat <<EOT 1>&2
Usage: process-results.sh [-dh] [-b file] [-r dir]

OPTIONS
=======
-b file   use <file> as output database
-d        output debug information
-h        show help
-r dir    use <dir> as output directory


EXAMPLES
========
# process result files in local directory
$ process-results.sh -r .

EOT

    exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false'  # -d
        [ERRORS_FILE]='' # -r
        [TIMESTAMP]=$(date "+%Y%m%d-%H%M%S")
        [PROCESSED_DIR]=''
        [RESULTS_DB]=''
        [RESULTS_DIR]=''
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

    if [[ -d ${results_dir} ]]; then
        mkdir -p "${results_dir}/errors"
        mkdir -p "${results_dir}/processed"
    else
        debug "Not making directories as results directory is not valid: ${results_dir}"
    fi

    GLOBALS[RESULTS_DIR]=${results_dir}
    GLOBALS[PROCESSED_DIR]=${results_dir}/processed
    GLOBALS[ERRORS_FILE]=${results_dir}/errors/process.txt

    debug "Set base directory to '${results_dir}'."
}

process_options() {
    local OPTARG # set by getopts
    local OPTIND # set by getopts

    while getopts ":b:dhr:" o; do
        case "${o}" in
        b)
            GLOBALS[RESULTS_DB]=${OPTARG}

            debug "Set results database to ${GLOBALS[RESULTS_DB]}."
            ;;

        d)
            GLOBALS[DEBUG]='true'

            debug "Debug mode turned on."
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
}

set_defaults() {
    if [[ -z ${GLOBALS[ERRORS_FILE]} ]]; then
        set_filenames '/home/speedtest/results'
    fi

    if [[ -z ${GLOBALS[RESULTS_DB]} || ! -f ${GLOBALS[RESULTS_DB]} ]]; then
        GLOBALS[RESULTS_DB]="${GLOBALS[RESULTS_DIR]}/speedtest.db"
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
        'mv'
        'realpath'
        'rm'
        'sqlite-utils'
    )

    for dependency in "${dependencies[@]}"; do
        check_for_dependency "${dependency}"
    done
}

process_file() {
    local file

    file=$1

    debug "Processing ${file}."

    if [[ -s ${file} ]]; then
        sqlite-utils insert "${GLOBALS[RESULTS_DB]}" results "${file}" 2>>"${GLOBALS[ERRORS_FILE]}"

        if [ $? -eq 0 ]; then
            mv "${file}" "${GLOBALS[PROCESSED_DIR]}"
        fi
    else
        echo "Removing zero byte file: ${file}" >>"${GLOBALS[ERRORS_FILE]}"

        rm "${file}"
    fi
}

process_files() {
    if [[ -d ${GLOBALS[RESULTS_DIR]} ]]; then
        local file

        for file in "${GLOBALS[RESULTS_DIR]}"/*.json; do
            if [[ ! -e ${file} ]]; then
                debug "Skipping missing file ${file}."

                continue
            fi

            file=$(realpath "${file}")

            process_file "${file}"
        done
    else
        debug "Not processing files as results directory is not valid: ${GLOBALS[RESULTS_DIR]}"
    fi
}

main() {
    init_globals

    process_options "$@"

    set_defaults

    dependency_check

    process_files
}

main "$@"
