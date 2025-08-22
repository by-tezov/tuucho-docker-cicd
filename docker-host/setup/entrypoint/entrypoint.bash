#!/bin/bash

# === CONFIGURATION ===
HOST_IP=$(hostname -i)

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash

# === MAIN ===
log_info "Container IP: $HOST_IP"
socat TCP-LISTEN:4777,fork,bind="${HOST_IP}" EXEC:"${COMMAND_HOME}/command_receiver_docker.bash"
