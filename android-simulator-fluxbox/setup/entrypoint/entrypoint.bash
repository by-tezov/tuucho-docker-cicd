#!/bin/bash

# === CONFIGURATION ===
source /usr/local/bin/keys.bash
HOST_IP=$(hostname -i)
LOG_DIR="$HOME/log"
XVFB_DISPLAY="${XVFB_DISPLAY:-:1}"
XVFB_SCREEN="${XVFB_SCREEN:-0}"
XVFB_RESOLUTION="${XVFB_RESOLUTION:-800x600x24}"
IFS='x' read -r XVFB_RESOLUTION_WIDTH XVFB_RESOLUTION_HEIGHT _ <<< "$XVFB_RESOLUTION"
XVFB_TIMEOUT="${XVFB_TIMEOUT:-20}"
FLUXBOX_TIMEOUT="${FLUXBOX_TIMEOUT:-20}"
VNC_TIMEOUT="${VNC_TIMEOUT:-20}"
EMULATOR_NAME="${EMULATOR_NAME:-emulator}"
ANDROID_AVD_VERSION="${ANDROID_AVD_VERSION:-30}"
EMULATOR_TIMEOUT="${EMULATOR_TIMEOUT:-120}"
ADB_SERVER_PORT="${ADB_SERVER_PORT:-}"

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash
source /usr/local/bin/bash/function/set_key_value.bash
source /usr/local/bin/bash/function/wait_until.bash

launch_xvfb() {
    log_info "Starting Xvfb"
    export DISPLAY="$XVFB_DISPLAY"
    Xvfb "$DISPLAY" -screen "$XVFB_SCREEN" "$XVFB_RESOLUTION" > "$LOG_DIR/xvfb.log" 2>&1 &
    wait_until "xdpyinfo -display $DISPLAY" "$XVFB_TIMEOUT" "Xvfb failed to start."
    log_info "Xvfb started"
}

launch_fluxbox() {
    log_info "Starting Fluxbox"
    fluxbox -rc ~/.fluxbox/init -display "$DISPLAY" > "$LOG_DIR/fluxbox.log" 2>&1 &
    wait_until "wmctrl -m" "$FLUXBOX_TIMEOUT" "Fluxbox failed to start."
    log_info "Fluxbox started"
}

launch_vnc_server() {
    log_info "Starting VNC server"
    x11vnc -ncache_cr -display "$DISPLAY" -forever -nopw > "$LOG_DIR/vnc.log" 2>&1 &
    wait_until "netstat -tnlp | grep -q 'x11vnc'" "$VNC_TIMEOUT" "VNC server failed to start."
    log_info "VNC server started"
}

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
    
    #log_info "Listing open windows:"
    #wmctrl -l

    local window_id
    # close warning windows
    window_id=$(xdotool search --name "nested virtualization" | head -n 1 || true)
    if [[ -z "$window_id" ]]; then
        log_warn "Emulator warning window not found, skipping emulator warning window validation."
    else
        xdotool windowactivate --sync "$window_id"
        sleep 1
        xdotool key Return
    fi

    # move emulator to center
    window_id=$(xdotool search --name "^Android Emulator" | head -n 1 || true)
    if [[ -z "$window_id" ]]; then
        log_warn "Emulator window not found, skipping emulator window centering."
    else
        xdotool windowactivate --sync "$window_id"
        sleep 1
        local emulator_width=0
        local emulator_height=0
        while IFS='=' read -r key value; do
            case "$key" in
                WIDTH) emulator_width=$value ;;
                HEIGHT) emulator_height=$value ;;
            esac
        done <<< "$(xdotool getwindowgeometry --shell "$window_id")"
        local x=$(( (XVFB_RESOLUTION_WIDTH - emulator_width) / 2 ))
        local y=$(( (XVFB_RESOLUTION_HEIGHT - emulator_height) / 2 ))
        xdotool windowmove "$window_id" "$x" "$y"
    fi

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
    socat TCP-LISTEN:4777,reuseaddr,fork,bind="${HOST_IP}" EXEC:"${COMMAND_HOME}/command_receiver_ready.bash" &
}

cleanup() {
    set_key_value "$COMMAND_RESPONSE_READY_KEY" "false"
    pkill -f Xvfb || true
    pkill -f fluxbox || true
    pkill -f x11vnc || true
    rm -f /tmp/.X*-lock /tmp/.X11-unix/X* || true
    rm -rf ~/.fluxbox /root/.fluxbox "${ANDROID_AVD_HOME:-}"/* "${ANDROID_HOME:-}/.temp" /tmp/android* ~/log || true
    mkdir -p "$LOG_DIR" || true
}

# === MAIN ===
trap 'log_info "Caught stop signal, shutting down..."; exit 0' SIGINT SIGTERM SIGHUP
log_info "Container IP: $HOST_IP"
cleanup
setup_receiver_socat
launch_xvfb
launch_fluxbox
launch_vnc_server
run_emulator
setup_emulator
setup_adb_socat
set_key_value "$COMMAND_RESPONSE_READY_KEY" "true"
wait "$emulator_pid"
