#!/bin/bash

# === CONFIGURATION ===
source /usr/local/bin/keys.bash
HOST_IP=$(hostname -i)
LOG_DIR="$HOME/log"
EMULATOR_NAME="${EMULATOR_NAME:-emulator}"
ANDROID_AVD_VERSION="${ANDROID_AVD_VERSION:-30}"
EMULATOR_TIMEOUT="${EMULATOR_TIMEOUT:-300}"
ADB_SERVER_PORT="${ADB_SERVER_PORT:-}"

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash
source /usr/local/bin/bash/function/set_key_value.bash
source /usr/local/bin/bash/function/wait_until.bash

run_emulator() {
    log_info "Creating emulator"
    echo "no" | avdmanager create avd --force -n "$EMULATOR_NAME" \
        -k "system-images;android-$ANDROID_AVD_VERSION;google_apis;x86_64" --device "pixel_3a"

    log_info "Starting emulator"
    exec emulator -avd "$EMULATOR_NAME" \
        -no-metrics -no-boot-anim -noaudio -no-snapshot \
        -gpu swiftshader_indirect -memory 2048 -netdelay none -netspeed full \
        -grpc-use-token -port 5554 &
    emulator_pid=$!

    wait_until "adb -s emulator-5554 shell getprop dev.bootcomplete | grep -m 1 '1'" "$EMULATOR_TIMEOUT" "Emulator failed to boot."
    sleep 5
    log_info "Emulator started"
}

setup_emulator() {
    log_info "Setup emulator"
    # setup emulator
    adb shell "settings put global window_animation_scale 0.0"
    adb shell "settings put global transition_animation_scale 0.0"
    adb shell "settings put global animator_duration_scale 0.0"
    log_info "Emulator configured"
}

setup_adb_socat() {
    log_info "Setup adb"
    if [ -z "$ADB_SERVER_PORT" ]; then
        log_error "ADB_SERVER_PORT is not set."
        exit 1
    fi
    socat TCP-LISTEN:"$ADB_SERVER_PORT",reuseaddr,fork,bind="${HOST_IP}" TCP:127.0.0.1:5555 > "$LOG_DIR/adb_socat.log" 2>&1 &
}

setup_receiver_socat() {
    log_info "Setup receiver"
    socat TCP-LISTEN:4777,reuseaddr,fork,bind="${HOST_IP}" EXEC:"${COMMAND_HOME}/command_receiver_ready.bash" > "$LOG_DIR/x11_socat.log" 2>&1 &
}

setup_x11_socat() {
    log_info "Setup X11"
    DISPLAY_NUM=$(echo "$DISPLAY" | grep -oE ':[0-9]+' | tr -d ':')
    if [ -z "$DISPLAY_NUM" ]; then
    echo "Could not extract display number from DISPLAY=$DISPLAY"
        exit 1
    fi
    XSOCK="/host-x11/X$DISPLAY_NUM"
    TCP_PORT=$((6000 + DISPLAY_NUM))
    socat TCP-LISTEN:$TCP_PORT,reuseaddr,fork UNIX-CONNECT:$XSOCK &
}

cleanup() {
    set_key_value "$COMMAND_RESPONSE_READY_KEY" "false"
    rm -rf "${ANDROID_AVD_HOME:-}"/* "${ANDROID_HOME:-}/.temp" /tmp/android* ~/log || true
    mkdir -p "$LOG_DIR" || true
}

# === MAIN ===
trap 'log_info "Caught stop signal, shutting down..."; exit 0' SIGINT SIGTERM SIGHUP
log_info "Container IP: $HOST_IP"
cleanup
setup_receiver_socat
setup_x11_socat
run_emulator
setup_emulator
setup_adb_socat
set_key_value "$COMMAND_RESPONSE_READY_KEY" "true"
wait "$emulator_pid"
