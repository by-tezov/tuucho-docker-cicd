FROM node:22-slim

LABEL owner="tezov.app@gmail.com"

USER root

ENV USER_HOME=/home/qa
ENV COMMAND_HOME=${USER_HOME}/command
ENV ROOT_SSH=/root/.ssh

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=${PATH}:${JAVA_HOME}/bin

RUN printf "export JAVA_HOME=%s\nexport PATH=%s\n" \
    "$JAVA_HOME" "$PATH" \
    >> /etc/environment

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat wget jq\
    openjdk-17-jdk wget unzip git bash openssh-server openssh-client \
    curl jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#RUN echo "Java path: $(readlink -f $(which java))"

COPY setup/ssh/agent/id_rsa_agent.pub ${ROOT_SSH}/authorized_keys
RUN chmod 600 ${ROOT_SSH}/authorized_keys

RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/Port 22/22/' /etc/ssh/sshd_config && \
    echo "AllowUsers root" >> /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd

COPY setup/ssh/github/id_ed25519_github ${ROOT_SSH}/
COPY setup/ssh/github/config ${ROOT_SSH}/
RUN chmod 700 ${ROOT_SSH} && \
    chmod 600 ${ROOT_SSH}/id_ed25519_github

RUN mkdir -p ${USER_HOME} && \
    chown -R root:root ${USER_HOME} && \
    chown -R root:root ${ROOT_SSH}

COPY docker-host/setup/command/command_sender.bash ${COMMAND_HOME}/
RUN dos2unix ${COMMAND_HOME}/command_sender.bash && \
    chmod +x ${COMMAND_HOME}/command_sender.bash && \
    ln -s ${COMMAND_HOME}/command_sender.bash /usr/bin/docker && \
    chown root:root /usr/bin/docker

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY agent-android-qa/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash
    
WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]