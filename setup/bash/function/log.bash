#!/bin/bash

# Define color codes
COLOR_BLUE="\033[1;34m"
COLOR_ORANGE="\033[0;33m"
COLOR_RED="\033[1;31m"
COLOR_NC="\033[0m"

log_info()  { echo -e "${COLOR_BLUE}[INFO] $*${COLOR_NC}"; }
log_warn()  { echo -e "${COLOR_ORANGE}[WARN] $*${COLOR_NC}"; }
log_error() { echo -e "${COLOR_RED}[ERROR] $*${COLOR_NC}"; }