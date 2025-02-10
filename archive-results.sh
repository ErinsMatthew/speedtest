#!/usr/bin/env bash

set -o nounset

usage() {
    cat <<EOT 1>&2
Usage: archive-results.sh [-dh] [-b file] [-r dir]

OPTIONS
=======
-d        output debug information
-h        show help
-r dir    use <dir> as output directory


EXAMPLES
========
# archive result files in local directory
$ archive-results.sh -r .

EOT

    exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false'  # -d
        [ERRORS_FILE]='' # -r
        [PROCESSED_DIR]=''
        [RAW_DIR]=''
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
    mkdir -p "${results_dir}/processed"
    mkdir -p "${results_dir}/raw"

    GLOBALS[PROCESSED_DIR]=${results_dir}/processed
    GLOBALS[RAW_DIR]=${results_dir}/raw
    GLOBALS[ERRORS_FILE]=${results_dir}/errors/archive.txt

    debug "Set base directory to '${results_dir}'."
}

process_options() {
    local OPTARG # set by getopts
    local OPTIND # set by getopts

    [[ $# -eq 0 ]] && usage

    while getopts ":dhr:" o; do
        case "${o}" in
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
}

check_for_dependency() {
    debug "Checking for dependency '$1'."

    if ! command -v "$1" &>/dev/null; then
        printf 'Dependency %s is missing.' "$1" >/dev/stderr

        exit
    fi
}

dependency_check() {
    local dependency

    local -a dependencies=(
        'cat'
        'cut'
        'gdate'
        'gzip'
        'gunzip'
        'realpath'
        'rm'
        'tar'
    )

    for dependency in "${dependencies[@]}"; do
        check_for_dependency "${dependency}"
    done
}

get_year_month() {
    gdate --date="$(basename "${file}" | cut -d - -f 2)" '+year=%Y%nmonth=%m'
}

archive_file() {
    local path
    local file

    local compressed_archive_file
    local uncompressed_archive_file

    declare -A file_year_month

    path=$1
    file=$2

    debug "Archiving ${file} in ${path}."

    if [[ -s ${file} ]]; then
        while IFS="=" read -r key value; do
            file_year_month["${key}"]="${value}"
        done < <(get_year_month "${file}")

        debug "file_year_month = ${file_year_month[*]}"

        compressed_archive_file="${path}/${file_year_month[year]}-${file_year_month[month]}.tar.gz"
        uncompressed_archive_file="${path}/${file_year_month[year]}-${file_year_month[month]}.tar"

        debug "compressed_archive_file = ${compressed_archive_file}"

        if [[ -f ${compressed_archive_file} ]]; then
            debug "Uncompressing ${compressed_archive_file}"

            gunzip "${compressed_archive_file}"
        fi

        # add file to tar.gz archive
        tar --append --file "${uncompressed_archive_file}" "${file}"

        # remove file
        rm "${file}"

        debug "Archived ${file}."
    else
        echo "Removing zero byte file: ${file}" >>"${GLOBALS[ERRORS_FILE]}"

        rm "${file}"
    fi
}

archive_files() {
    local paths
    local path
    local file

    paths=("${GLOBALS[PROCESSED_DIR]}" "${GLOBALS[RAW_DIR]}")

    for path in "${paths[@]}"; do
        for file in "${path}"/*.json; do
            if [[ ! -e ${file} ]]; then
                debug "Skipping missing file ${file}."

                continue
            fi

            file=$(realpath "${file}")

            archive_file "${path}" "${file}"
        done
    done
}

compress_archives() {
    local paths
    local path
    local file

    paths=("${GLOBALS[PROCESSED_DIR]}" "${GLOBALS[RAW_DIR]}")

    for path in "${paths[@]}"; do
        for file in "${path}"/*.tar; do
            if [[ ! -e ${file} ]]; then
                debug "Skipping missing file ${file}."

                continue
            fi

            file=$(realpath "${file}")

            gzip "${file}"
        done
    done
}

main() {
    init_globals

    process_options "$@"

    set_defaults

    dependency_check

    archive_files

    compress_archives
}

main "$@"
