#!/bin/bash

set -euo pipefail

# === CONFIGURATION ===
SOURCE_FOLDER_PATH="/var/lib/docker/volumes/jenkins_volume/_data"
DESTINATION_FOLDER_PATH="/home/tezov/Local/by-tezov/cicd/jenkins/setup/backup"
CLEAR_CONTENT="true"
ENABLE_TAR="true"

# === FUNCTIONS ===
source "setup/bash/function/log.bash"

error() {
    log_error "$1"
    exit 1
}

check_variables() {
    [[ -z "$SOURCE_FOLDER_PATH" ]] && error "SOURCE_FOLDER_PATH is not set"
    [[ -z "$DESTINATION_FOLDER_PATH" ]] && error "DESTINATION_FOLDER_PATH is not set"
    [[ ! -d "$SOURCE_FOLDER_PATH" ]] && error "SOURCE_FOLDER_PATH does not exist"
    mkdir -p "$DESTINATION_FOLDER_PATH"
}

rotate_backup() {
    [[ "$ENABLE_TAR" != "true" ]] && return
    local last_dir="$DESTINATION_FOLDER_PATH/last"
    local previous_dir="$DESTINATION_FOLDER_PATH/previous"
    if [[ -d "$last_dir" ]] && [[ "$(ls -A "$last_dir")" ]]; then
        log_info "Rotating backups"
        rm -rf "$previous_dir"
        mv "$last_dir" "$previous_dir"
    fi
    mkdir -p "$last_dir"
}

prepare_last_untar() {
    local untar_dir="$DESTINATION_FOLDER_PATH/last_untar"
    rm -rf "$untar_dir"
    mkdir -p "$untar_dir"
}

create_temp_dir() {
    TMP_DIR=$(mktemp -d)
    log_info "Created temp dir: $TMP_DIR"
}

copy_source() {
    log_info "Copying source to temp"
    cp -a "$SOURCE_FOLDER_PATH/." "$TMP_DIR/"
}

cleanup_unwanted() {
    log_info "Removing unwanted files and folders"
    rm -rf "$TMP_DIR/.ssh"
    rm -rf "$TMP_DIR/.cache"
    rm -rf "$TMP_DIR/caches"
    rm -rf "$TMP_DIR/logs"
    rm -rf "$TMP_DIR/war"
    rm -rf "$TMP_DIR/workspace"
}

clean_builds() {
    [[ "$CLEAR_CONTENT" != "true" ]] && return
    log_info "Cleaning builds content"
    find "$TMP_DIR/jobs" -type d -path "*/jobs/*/builds" | while read -r builds_dir; do
        find "$builds_dir" -mindepth 1 -maxdepth 1 ! -name "permalinks" -exec rm -rf {} +
    done
}

create_archive() {
    local last_dir="$DESTINATION_FOLDER_PATH/last"
    log_info "Creating split archive"
    tar -C "$TMP_DIR" -czf - . | split -b 30M - "$last_dir/jenkins.tar.part."
}

move_without_tar() {
    local untar_dir="$DESTINATION_FOLDER_PATH/last_untar"
    log_info "Moving backup without tar"
    mv "$TMP_DIR"/* "$untar_dir/"
}

cleanup() {
    log_info "Cleaning temp directory"
    rm -rf "$TMP_DIR"
}

fix_permissions() {
    log_info "Fix permissions"
    local target_user="${SUDO_USER:-$USER}"
    chown -R "$target_user:$target_user" "$DESTINATION_FOLDER_PATH"
    chmod -R u+rwX "$DESTINATION_FOLDER_PATH"
}

# === MAIN ===
check_variables
rotate_backup
if [[ "$ENABLE_TAR" != "true" ]]; then
    prepare_last_untar
fi
create_temp_dir
copy_source
cleanup_unwanted
clean_builds
if [[ "$ENABLE_TAR" == "true" ]]; then
    create_archive
else
    move_without_tar
fi
cleanup
fix_permissions
log_info "Backup completed"