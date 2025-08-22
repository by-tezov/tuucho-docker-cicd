#!/bin/bash

usage() {
    echo "***** help *****"
    echo "Command: docker <command> <container>"
    echo "=> perform an action on docker host"
    echo "  <command>     action to perform (start or stop)"
    echo "  <container>   Name of the container"
}

command_docker() {
    local command="$1"
    local container="$2"

    case "$command" in
        start)
            docker start "$container" > /dev/null 2>&1 && echo "true" || { echo "false"; }
            ;;
        stop)
            docker stop "$container" > /dev/null 2>&1 && echo "true" || { echo "false"; }
            ;;
        *)
            usage
            ;;
    esac    
}

parse_command() {
    case "$1" in
        docker)
            shift
            command_docker "$@"
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
