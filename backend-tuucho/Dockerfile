FROM node:22-slim

LABEL owner="tezov.app@gmail.com"

USER root

ENV USER_HOME=/home/backend
ENV COMMAND_HOME=${USER_HOME}/command
ENV ROOT_SSH=/root/.ssh

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat tree \
    wget curl jq \
    unzip zip git bash openssh-server openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN git config --global user.email "tezov.app@gmail.com" && \
    git config --global user.name "tezov jenkins"

COPY setup/ssh/github/id_ed25519_github ${ROOT_SSH}/
COPY setup/ssh/github/config ${ROOT_SSH}/
RUN chmod 700 ${ROOT_SSH} && \
    chmod 600 ${ROOT_SSH}/id_ed25519_github

RUN mkdir -p ${USER_HOME} && \
    chown -R root:root ${USER_HOME} && \
    chown -R root:root ${ROOT_SSH}

COPY docker-host/setup/command/command_receiver_ready.bash ${COMMAND_HOME}/
RUN dos2unix ${COMMAND_HOME}/command_receiver_ready.bash && \
    chmod +x ${COMMAND_HOME}/command_receiver_ready.bash

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash
#IMPORT GET VALUE FUNCTION
COPY setup/bash/function/get_key_value.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/get_key_value.bash
#IMPORT SET VALUE FUNCTION
COPY setup/bash/function/set_key_value.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/set_key_value.bash
#IMPORT WAIT_UNTIL FUNCTION
COPY setup/bash/function/wait_until.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/wait_until.bash

COPY backend-tuucho/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash
    
WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]