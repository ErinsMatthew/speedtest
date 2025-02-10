#!/usr/bin/env bash

set -o nounset

/home/speedtest/bin/speedtest.sh -o

/home/speedtest/bin/process-results.sh
