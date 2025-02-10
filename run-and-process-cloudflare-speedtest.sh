#!/usr/bin/env bash

set -o nounset

/home/speedtest/bin/speedtest.sh -c

/home/speedtest/bin/process-results.sh
