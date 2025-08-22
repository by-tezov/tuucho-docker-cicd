#!/bin/bash

# === CONFIGURATION ===
HOST_IP=$(hostname -i)

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash

# === MAIN ===
log_info "Container IP: $HOST_IP"

if [ -z "$APPIUM_SERVICE" ]; then
  echo "Error: APPIUM_SERVICE environnement variable is not set. it Should be container_name:port in docker compose file"
  exit 1
fi

socat TCP-LISTEN:4723,reuseaddr,fork,bind=127.0.0.1 TCP:${APPIUM_SERVICE} > /home/qa/socat.log 2>&1 &

exec /usr/sbin/sshd -D
