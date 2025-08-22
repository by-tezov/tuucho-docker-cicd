#!/bin/bash

# === CONFIGURATION ===
HOST_IP=$(hostname -i)

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash

# === MAIN ===
log_info "Container IP: $HOST_IP"
exec /usr/sbin/sshd -D
