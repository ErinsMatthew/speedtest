#!/bin/sh

. /home/speedtest/bin/exports.sh

ERRORS_FILE=$RESULTS_DIR/errors/process.txt

cd "$RESULTS_DIR"

for file in *.json; do
    if [ -s "$file" ]; then
        jq '( env.BYTE_TO_MEGABIT | tonumber ) as $byteToMbit | { timestamp: .timestamp, ping:
        .ping.latency, download: ( .download.bandwidth * $byteToMbit ), upload: (
        .upload.bandwidth * $byteToMbit ) }' "$file" | /usr/local/bin/sqlite-utils insert "$RESULTS_DB" results - 2>> "$ERRORS_FILE"

        if [ $? -eq 0 ]; then
            mv "$file" "$PROCESSED_DIR"
        fi
    else
        rm "$file"
    fi
done
