#!/bin/bash
set -e

# === CONFIGURATION ===
COMMAND_LINE_TOOL_VERSION=14742923
ANDROID_SDK_VERSION="android-36"
BUILD_TOOLS_VERSION=36.1.0
ANDROID_AVD_VERSION="android-36"

TEMP_DIR=$(mktemp -d)
DESTINATION_FOLDER_PATH="/home/tezov/Local/by-tezov/cicd/setup/android"

CHUNK_SIZE="30M"

CMDLINE_TOOLS_DIR="$TEMP_DIR/cmdline-tools/latest"
PLATFORM_TOOLS_DIR="$TEMP_DIR/platform-tools"
BUILD_TOOLS_DIR="$TEMP_DIR/build-tools/$BUILD_TOOLS_VERSION"
PLATFORMS_DIR="$TEMP_DIR/platforms/$ANDROID_SDK_VERSION"
SYSTEM_IMAGES_DIR="$TEMP_DIR/system-images/$ANDROID_AVD_VERSION"
EMULATOR_DIR="$TEMP_DIR/emulator"

# === FUNCTIONS ===
source "setup/bash/function/log.bash"

exists() {
    [ -d "$1" ]
}

rotate_backup() {
    local last_dir="$DESTINATION_FOLDER_PATH/last"
    local previous_dir="$DESTINATION_FOLDER_PATH/previous"

    if [[ -d "$last_dir" ]] && [[ "$(ls -A "$last_dir" 2>/dev/null)" ]]; then
        log_info "Rotating backups"
        rm -rf "$previous_dir"
        mv "$last_dir" "$previous_dir"
    fi

    mkdir -p "$last_dir"
}

download_cmdline_tools() {
    if ! exists "$CMDLINE_TOOLS_DIR"; then
        log_info "cmdline-tools not found. Downloading..."

        wget "https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOL_VERSION}_latest.zip" \
            -O "$TEMP_DIR/cmdline-tools.zip"

        mkdir -p "$TEMP_DIR/tmp-cmdline"
        unzip "$TEMP_DIR/cmdline-tools.zip" -d "$TEMP_DIR/tmp-cmdline"

        mkdir -p "$CMDLINE_TOOLS_DIR"
        mv "$TEMP_DIR/tmp-cmdline/cmdline-tools/"* "$CMDLINE_TOOLS_DIR"

        rm -rf "$TEMP_DIR/tmp-cmdline" "$TEMP_DIR/cmdline-tools.zip"

        log_info "cmdline-tools installed"
    else
        log_info "cmdline-tools already installed."
    fi
}

install_sdk_component() {
    local path="$1"
    local install_cmd="$2"
    local success_msg="$3"

    if ! exists "$path"; then
        log_info "Installing $success_msg..."
        sdkmanager "$install_cmd"
        log_info "$success_msg installed"
    else
        log_info "$success_msg already installed."
    fi
}

bundle_dir() {
    local SRC_DIR="$1"
    local OUT_NAME="$2"
    local REL_PATH="$3"

    if [ "$REL_PATH" = "." ]; then
        REL_PATH=""
    elif [ "$REL_PATH" = "$OUT_NAME" ]; then
        REL_PATH="$REL_PATH"
    else
        REL_PATH="$REL_PATH/$OUT_NAME"
    fi

    local DEST_DIR="$DESTINATION_FOLDER_PATH/last/$REL_PATH"
    mkdir -p "$DEST_DIR"
    log_info "Bundling ${OUT_NAME}.tar.part.*"
    (
        cd "$SRC_DIR"
        tar -czf - . | split -b "$CHUNK_SIZE" - "$DEST_DIR/${OUT_NAME}.tar.part."
    )
}

setup_sdk_environment() {
    export PATH="$CMDLINE_TOOLS_DIR/bin:$PATH"
    log_info "PATH updated for sdkmanager"
    yes | sdkmanager --licenses > /dev/null
    log_info "Licenses accepted"
}

copy_licenses() {
    log_info "Copying licenses"
    cp -a "$TEMP_DIR/licenses" "$DESTINATION_FOLDER_PATH/last/" 2>/dev/null || true
}

cleanup_temp() {
    log_info "Cleaning temporary workspace"
    rm -rf "$TEMP_DIR"
}

# === MAIN ===
mkdir -p "$TEMP_DIR" "$DESTINATION_FOLDER_PATH"

download_cmdline_tools
setup_sdk_environment

install_sdk_component "$PLATFORM_TOOLS_DIR" "platform-tools" "platform-tools"
install_sdk_component "$BUILD_TOOLS_DIR" "build-tools;$BUILD_TOOLS_VERSION" "build-tools"
install_sdk_component "$EMULATOR_DIR" "emulator" "emulator"
install_sdk_component "$PLATFORMS_DIR" "platforms;$ANDROID_SDK_VERSION" "platforms"
install_sdk_component "$SYSTEM_IMAGES_DIR" "system-images;$ANDROID_AVD_VERSION;google_apis;x86_64" "system image"

rotate_backup

bundle_dir "$BUILD_TOOLS_DIR" "$BUILD_TOOLS_VERSION" "build-tools"
bundle_dir "$CMDLINE_TOOLS_DIR" "$COMMAND_LINE_TOOL_VERSION" "cmdline-tools"
bundle_dir "$EMULATOR_DIR" "emulator" "emulator"
bundle_dir "$PLATFORM_TOOLS_DIR" "platform-tools" "platform-tools"
bundle_dir "$PLATFORMS_DIR" "$ANDROID_SDK_VERSION" "platforms"
bundle_dir "$SYSTEM_IMAGES_DIR" "$ANDROID_AVD_VERSION" "system-images"

copy_licenses
cleanup_temp

log_info "Android predownload packaging completed"clear
