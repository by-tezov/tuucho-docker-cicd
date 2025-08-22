#!/bin/bash

# === CONFIGURATION ===
SERVER_HOSTNAME="server.tezov.com"
EMAIL="tezov.app@gmail.com"
LETSENCRYPT_LIVE_DIR="/etc/letsencrypt/live/$SERVER_HOSTNAME"
NGINX_KEYS_DIR="/etc/nginx/letsencrypt/certificats"
NGINX_SITE_AVAILABLE_DIR="/etc/nginx/site-available"
NGINX_SITE_ENABLED_DIR="/etc/nginx/site-enabled"
CERTBOT_OPTS="--standalone --non-interactive --agree-tos"
NGINX_ACCESS_LOG="/var/log/nginx/server_access.log"
NGINX_ERROR_LOG="/var/log/nginx/server_error.log"

SUCCESS=0
KEY_FILE_INVALID=100
KEY_EXPIRED=101

# === FUNCTIONS ===
source /usr/local/bin/bash/function/log.bash

check_ssl_expiration() {
    log_info "Checking SSL certificate expiration"
    local fullchain_file="$NGINX_KEYS_DIR/fullchain.pem"
    if [ ! -f "$fullchain_file" ]; then
        log_error "SSL certificate file not found: $fullchain_file"
        return $KEY_FILE_INVALID
    fi
    local expiration_date
    expiration_date=$(openssl x509 -enddate -noout -in "$fullchain_file" | cut -d= -f2)
    local expiration_timestamp
    expiration_timestamp=$(date --date="$expiration_date" +%s)
    local current_timestamp
    current_timestamp=$(date +%s)
    if [ "$expiration_timestamp" -lt "$current_timestamp" ]; then
        log_warn "SSL certificate has expired."
        return $KEY_EXPIRED
    else
        log_info "SSL certificate is valid. Expiration date: $expiration_date"
        return $SUCCESS
    fi
}

request_certificat() {
    log_info "Requesting new SSL certificate"
    certbot certonly $CERTBOT_OPTS --email "$EMAIL" -d "$SERVER_HOSTNAME"
}

move_letsencrypt_keys() {
    log_info "Moving Let's Encrypt keys"

    local fullchain_file="$LETSENCRYPT_LIVE_DIR/fullchain.pem"
    local privkey_file="$LETSENCRYPT_LIVE_DIR/privkey.pem"

    local fullchain_file_exist=$( [ -f "$fullchain_file" ] && echo true || echo false )
    local privkey_file_exist=$( [ -f "$privkey_file" ] && echo true || echo false )

    log_info "Fullchain file exists: $fullchain_file_exist"
    log_info "Privkey file exists: $privkey_file_exist"

    if [ "$fullchain_file_exist" = "false" ] || [ "$privkey_file_exist" = "false" ]; then
        log_error "Missing fullchain or privkey files in Let's Encrypt directory."
        exit 1
    fi

    cp "$fullchain_file" "$NGINX_KEYS_DIR/fullchain.pem"
    cp "$privkey_file" "$NGINX_KEYS_DIR/privkey.pem"
    rm -rf "$LETSENCRYPT_LIVE_DIR"
}

setup_nginx_conf() {
    log_info "Updating nginx configuration symlinks"
    local ssl_check_code=$1

    rm -f "$NGINX_SITE_ENABLED_DIR/jenkins.conf" || true
    rm -f "$NGINX_SITE_ENABLED_DIR/jenkins-localhost.conf" || true

    ln -s "$NGINX_SITE_AVAILABLE_DIR/jenkins-localhost.conf" "$NGINX_SITE_ENABLED_DIR/jenkins-localhost.conf"

    if [ "$ssl_check_code" -eq "$SUCCESS" ]; then
        log_info "Loading SSL nginx config"
        ln -s "$NGINX_SITE_AVAILABLE_DIR/jenkins-with-ssl.conf" "$NGINX_SITE_ENABLED_DIR/jenkins.conf"
    else
        log_warn "Loading no-SSL nginx config"
        ln -s "$NGINX_SITE_AVAILABLE_DIR/jenkins-no-ssl.conf" "$NGINX_SITE_ENABLED_DIR/jenkins.conf"
    fi
}

# === MAIN ===

# *********************************************
# Certificats is disable for now, need to fix
#check_ssl_expiration
#result_code=$?
#case $result_code in
#    $KEY_EXPIRED)
#        request_certificat
#        move_letsencrypt_keys
#        ;;
#esac
# *********************************************

result_code=$KEY_FILE_INVALID
setup_nginx_conf "$result_code"
service nginx start > /dev/null &
tail -f "$NGINX_ACCESS_LOG" "$NGINX_ERROR_LOG"