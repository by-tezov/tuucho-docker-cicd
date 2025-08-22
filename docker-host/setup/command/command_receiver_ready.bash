#!/bin/bash

source /usr/local/bin/keys.bash
source /usr/local/bin/bash/function/get_key_value.bash

usage() {
    echo "***** help *****"
    echo "Command: ready"
    echo "=> request status, response true if ready, false if no ready"
}

command_ready() {
    result=$(get_key_value "$COMMAND_RESPONSE_READY_KEY" "false")
    echo "$result"
}

parse_command() {
    case "$1" in
        ready)
            command_ready
            ;;
        *)
            usage
            ;;
    esac
    exit 0
}

if [ $# -eq 0 ] && [ ! -t 0 ]; then
    set -- $(cat)
fi
parse_command "$@"