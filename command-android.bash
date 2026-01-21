#!/bin/bash
set -e

# Configuration
LOCAL="Local/cicd-predownload"
COMMAND_LINE_TOOL_VERSION=14742923
ANDROID_SDK_VERSION="android-36"
BUILD_TOOLS_VERSION="36.1.0"
ANDROID_AVD_VERSION="android-36"

# Paths
BASE_DIR="$HOME/$LOCAL"
CMDLINE_TOOLS_DIR="$BASE_DIR/cmdline-tools/latest"
PLATFORM_TOOLS_DIR="$BASE_DIR/platform-tools"
BUILD_TOOLS_DIR="$BASE_DIR/build-tools/$BUILD_TOOLS_VERSION"
PLATFORMS_DIR="$BASE_DIR/platforms/$ANDROID_SDK_VERSION"
SYSTEM_IMAGES_DIR="$BASE_DIR/system-images/$ANDROID_AVD_VERSION"
EMULATOR_DIR="$BASE_DIR/emulator"
TAR_DIR="$BASE_DIR/tar"

mkdir -p "$BASE_DIR" "$TAR_DIR"

# Function to check if a directory exists
exists() {
    [ -d "$1" ]
}


# Download and setup cmdline-tools if not present
if ! exists "$CMDLINE_TOOLS_DIR"; then
    echo "cmdline-tools not found. Downloading..."
    wget "https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOL_VERSION}_latest.zip" -O "$BASE_DIR/cmdline-tools.zip"

    mkdir -p "$BASE_DIR/cmdline-tools"
    unzip "$BASE_DIR/cmdline-tools.zip" -d "$BASE_DIR/tmp-cmdline"
    mkdir -p "$CMDLINE_TOOLS_DIR"
    mv "$BASE_DIR/tmp-cmdline/cmdline-tools/"* "$CMDLINE_TOOLS_DIR"

    rm -rf "$BASE_DIR/tmp-cmdline" "$BASE_DIR/cmdline-tools.zip"
else
    echo "cmdline-tools already installed."
fi

# Export PATH for sdkmanager
export PATH="$CMDLINE_TOOLS_DIR/bin:$PATH"

# Accept licenses
yes | sdkmanager --licenses > /dev/null

# Install platform-tools if not present
if ! exists "$PLATFORM_TOOLS_DIR"; then
    echo "Installing platform-tools..."
    sdkmanager "platform-tools"
else
    echo "platform-tools already installed."
fi

# Install build-tools if not present
if ! exists "$BUILD_TOOLS_DIR"; then
    echo "Installing build-tools $BUILD_TOOLS_VERSION..."
    sdkmanager "build-tools;$BUILD_TOOLS_VERSION"
else
    echo "build-tools $BUILD_TOOLS_VERSION already installed."
fi

# Install emulator if not present
if ! exists "$EMULATOR_DIR"; then
    echo "Installing Android emulator..."
    sdkmanager "emulator"
else
    echo "Android emulator already installed."
fi

# Install platforms if not present
if ! exists "$PLATFORMS_DIR"; then
    echo "Installing platform $ANDROID_SDK_VERSION..."
    sdkmanager "platforms;$ANDROID_SDK_VERSION"
else
    echo "Platform $ANDROID_SDK_VERSION already installed."
fi

# Install system image if not present
if ! exists "$SYSTEM_IMAGES_DIR"; then
    echo "Installing system image $ANDROID_AVD_VERSION..."
    sdkmanager "system-images;$ANDROID_AVD_VERSION;google_apis;x86_64"
else
    echo "System image $ANDROID_AVD_VERSION already installed."
fi

SETUP_DIR="$BASE_DIR/_setup-android-tar"
CHUNK_SIZE="30M"

mkdir -p "$SETUP_DIR"

bundle_dir() {
    local SRC_DIR="$1"
    local OUT_NAME="$2"
    local REL_PATH="$3"

    local DEST_DIR
    if [ "$REL_PATH" = "." ]; then
        DEST_DIR="$SETUP_DIR"
    elif [ "$REL_PATH" = "$OUT_NAME" ]; then
        DEST_DIR="$SETUP_DIR/$REL_PATH"
    else
        DEST_DIR="$SETUP_DIR/$REL_PATH/$OUT_NAME"
    fi

    mkdir -p "$DEST_DIR"
    echo "Bundling $SRC_DIR -> $DEST_DIR/${OUT_NAME}.tar.part.*"

    (
        cd "$SRC_DIR" || exit 1
        tar -czf - . | split -b "$CHUNK_SIZE" - "$DEST_DIR/${OUT_NAME}.tar.part."
    )
}

# build-tools
bundle_dir "$BUILD_TOOLS_DIR" "$BUILD_TOOLS_VERSION" "build-tools"

# cmdline-tools
bundle_dir "$CMDLINE_TOOLS_DIR" "$COMMAND_LINE_TOOL_VERSION" "cmdline-tools"

# emulator
bundle_dir "$EMULATOR_DIR" "emulator" "emulator"

# licenses
echo "Copying licenses..."
cp -a "$BASE_DIR/licenses" "$SETUP_DIR/"

# platform-tools
bundle_dir "$PLATFORM_TOOLS_DIR" "platform-tools" "platform-tools"

# platforms
bundle_dir "$PLATFORMS_DIR" "$ANDROID_SDK_VERSION" "platforms"

# system-images
bundle_dir "$SYSTEM_IMAGES_DIR" "$ANDROID_AVD_VERSION" "system-images"


# for gradle, should do a script too. Can be take inside .gradle/wrapper
#zip -r - gradle-9.0.0-bin | split -b 30M - gradle-9.0.0-bin.zip.part.
