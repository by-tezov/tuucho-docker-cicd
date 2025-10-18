#!/bin/bash

usage() {
    echo "***** help *****"
    echo "Command: docker <command> <container> [branch]"
    echo "=> perform an action on docker host"
    echo "  <command>     action to perform:"
    echo "                  start"
    echo "                  stop"
    echo "                  create-and-start"
    echo "                  stop-and-delete"
    echo "  <container>   Name of the container"
    echo "  [branch]      Required only for create-and-start"
}

command_docker_start() {
    local container="$1"
    docker start "$container" > /dev/null 2>&1 && echo "true" || { echo "false result='fail to start container'"; }
}

command_docker_stop() {
    local container="$1"
    docker stop "$container" > /dev/null 2>&1 && echo "true" || { echo "false result='fail to stop container'"; }
}

command_docker_create_and_start() {
    local container="$1"
    local branch="$2"
    docker run -d \
        --name "$container" \
        --network cicd_main-network \
        -e BRANCH="$branch" \
        --restart always \
        backend-tuucho:latest > /dev/null 2>&1 && echo "true" || { echo "false result='fail to create and start container'"; }
}

command_docker_stop_and_delete() {
    local container="$1"
    docker stop "$container" > /dev/null 2>&1 || true
    docker rm "$container" > /dev/null 2>&1 || true
}

command_docker() {
    local command="$1"
    local container="$2"
    if [ -z "$container" ]; then
        echo "false result='missing container name'"
        return
    fi
    case "$command" in
        start)
            command_docker_start "$container"
            ;;
        stop)
            command_docker_stop "$container"
            ;;
        create-and-start)
            local branch="$3"
            if [ -z "$branch" ]; then
                echo "false result='missing branch argument'"
                return
            fi
            command_docker_create_and_start "$container" "$branch"
            ;;
        stop-and-delete)
            command_docker_stop_and_delete "$container"
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
