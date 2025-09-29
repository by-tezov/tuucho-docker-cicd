FROM node:22-slim

LABEL owner="tezov.app@gmail.com"

USER root

ENV USER_HOME=/home/backend
ENV ROOT_SSH=/root/.ssh

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat wget jq tree \
    wget unzip git bash openssh-server openssh-client \
    curl jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY setup/ssh/github/id_ed25519_github ${ROOT_SSH}/
COPY setup/ssh/github/config ${ROOT_SSH}/
RUN chmod 700 ${ROOT_SSH} && \
    chmod 600 ${ROOT_SSH}/id_ed25519_github

RUN mkdir -p ${USER_HOME} && \
    chown -R root:root ${USER_HOME} && \
    chown -R root:root ${ROOT_SSH}

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY backend-tuucho/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash
    
WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]