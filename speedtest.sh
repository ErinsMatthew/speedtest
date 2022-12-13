#!/bin/sh

. /home/speedtest/bin/exports.sh

ERRORS_FILE=$RESULTS_DIR/errors.txt

RESULTS_FILE=$RESULTS_DIR/results-$( date "+%Y%m%d-%H%M%S" ).json

/usr/bin/speedtest --format=json --output-header --accept-license --accept-gdpr > $RESULTS_FILE 2>> $ERRORS_FILE
