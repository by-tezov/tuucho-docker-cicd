#!/bin/bash

# === CONFIGURATION ===
HOST_IP=$(hostname -i)
REPO_DIR="remote"
REPO_URL="git@github.com:by-tezov/tuucho-backend.git"
BRANCH="master"

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash

clone_and_install() {
    log_info "Cloning and installing repo"
    mkdir -p "$USER_HOME/$REPO_DIR"
    git clone --branch "$BRANCH" "$REPO_URL" "$USER_HOME/$REPO_DIR"
    cd "$USER_HOME/$REPO_DIR"
    npm ci
}

# === MAIN ===
log_info "Container IP: $HOST_IP"

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

log_info "Starting app"
npm run start:dev
