#!/bin/bash

command_docker_host() {
    echo "docker $@" | socat - TCP:docker-host:4777 || { echo "false result='fail to send command'"; }
}

command_ready() {
    local target="$1"
    echo "ready" | socat - TCP:${target}:4777 || { echo "false"; }
}

parse_command() {
    case "$1" in
        start|stop|create-and-start|stop-and-delete)
            command_docker_host "$@"
            ;;
        status)
            shift
            command_ready "$@"
            ;;
        *)
            echo "false result='unknown command for command_send.bash'";
            ;;
    esac
    exit 0
}

if [ $# -eq 0 ] && [ ! -t 0 ]; then
    set -- $(cat)
fi
parse_command "$@"