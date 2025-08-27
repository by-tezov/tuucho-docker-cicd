FROM nginx:1.28.0

LABEL owner="tezov.app@gmail.com"

ENV ETC_NGINX=/etc/nginx
ENV ETC_NGINX_LETSENCRYPT=${ETC_NGINX}/letsencrypt

ENV VAR_LOG=/var/log/nginx
ENV VAR_WWW=/var/www
ENV VAR_WWW_ROOT=${VAR_WWW}/root

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat net-tools iproute2 tree \
    python3 python3-pip python3-venv cron && \
    python3 -m venv /opt/certbot-venv && \
    /opt/certbot-venv/bin/pip install --no-cache-dir certbot && \
    ln -s /opt/certbot-venv/bin/certbot /usr/bin/certbot && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY nginx/setup/www/ ${VAR_WWW}/
COPY nginx/setup/nginx/ ${ETC_NGINX}/
COPY nginx/setup/letsencrypt/ ${ETC_NGINX_LETSENCRYPT}/
RUN mkdir -p ${ETC_NGINX}/site-enabled && \
    mkdir -p ${VAR_LOG} && \
    touch ${VAR_LOG}/server_access.log && \
    touch ${VAR_LOG}/server_error.log && \
    chown -R nginx:nginx ${ETC_NGINX} && \ 
    chown -R nginx:nginx ${VAR_LOG} && \
    chown -R nginx:nginx ${VAR_WWW}

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY nginx/setup/entrypoint/entrypoint.bash /usr/local/bin/entrypoint.bash
RUN chmod +x /usr/local/bin/entrypoint.bash && \ 
    chown -R nginx:nginx /usr/local/bin/entrypoint.bash

WORKDIR ${VAR_LOG}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]
