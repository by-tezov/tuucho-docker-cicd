#!/bin/bash

# === CONFIGURATION ===
source /usr/local/bin/keys.bash
HOST_IP=$(hostname -i)
LOG_DIR="$HOME/log"
REPO_DIR="remote"
REPO_URL="git@github.com:by-tezov/tuucho-backend.git"
: "${BRANCH:?BRANCH is not set or empty}"
NESTJS_TIMEOUT="${NESTJS_TIMEOUT:-300}"

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash
source /usr/local/bin/bash/function/set_key_value.bash
source /usr/local/bin/bash/function/wait_until.bash

clone_and_install() {
    log_info "Cloning and installing repo"
    mkdir -p "$USER_HOME/$REPO_DIR"
    git clone --branch "$BRANCH" "$REPO_URL" "$USER_HOME/$REPO_DIR"
    cd "$USER_HOME/$REPO_DIR"
    npm ci
}

setup_receiver_socat() {
    log_info "Setup receiver"
    socat TCP-LISTEN:4777,reuseaddr,fork,bind="${HOST_IP}" EXEC:"${COMMAND_HOME}/command_receiver_ready.bash" > "$LOG_DIR/x11_socat.log" 2>&1 &
}

start_nestjs() {
    log_info "Starting NestJS app"
    exec npm run start:dev &
    nestjs_pid=$!
    trap "kill $nestjs_pid 2>/dev/null" EXIT
    HEALTH_REGEX="\"health\"[[:space:]]*:[[:space:]]*\"[[:space:]]*[0-9]+%[[:space:]]*\""
    wait_until "curl -sf http://localhost:3000/v1/health/lobby | grep -Eq '$HEALTH_REGEX'" "$NESTJS_TIMEOUT" "NestJS failed to start"
}

# === MAIN ===
log_info "Container IP: $HOST_IP"

set_key_value "$COMMAND_RESPONSE_READY_KEY" "false"
mkdir -p "$LOG_DIR" || true

if [ ! -d "$USER_HOME/$REPO_DIR/.git" ]; then
    log_info "repository not found"
    clone_and_install
else
    cd "$USER_HOME/$REPO_DIR"
    log_info "Checking repo state"
    git fetch origin "$BRANCH"
    LOCAL=$(git rev-parse "$BRANCH")
    REMOTE=$(git rev-parse "origin/$BRANCH")
    if [ "$LOCAL" != "$REMOTE" ]; then
        log_info "repository changed — resetting"
        rm -rf "$USER_HOME/$REPO_DIR"
        clone_and_install
    fi
fi

setup_receiver_socat
start_nestjs
set_key_value "$COMMAND_RESPONSE_READY_KEY" "true"
wait "$nestjs_pid"