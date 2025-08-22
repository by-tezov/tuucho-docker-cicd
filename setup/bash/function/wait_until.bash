#!/bin/bash

wait_until() {
    local command=$1
    local timeout=$2
    local failure_message=$3

    local elapsed=0
    until eval "$command" > /dev/null 2>&1; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ "$elapsed" -ge "$timeout" ]; then
            log_error "$failure_message"
            exit 1
        fi
    done
}