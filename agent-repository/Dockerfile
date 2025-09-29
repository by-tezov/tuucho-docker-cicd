FROM openjdk:17-jdk-slim

LABEL owner="tezov.app@gmail.com"

USER root

ENV USER_HOME=/home/repository
ENV ROOT_SSH=/root/.ssh

ENV JAVA_HOME=/usr/local/openjdk-17
ENV PATH=${PATH}:${JAVA_HOME}/bin
RUN printf "JAVA_HOME=%s\nPATH=%s\n" "$JAVA_HOME" "$PATH" >> /etc/environment

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping tree \
    wget curl jq \
    unzip zip git bash openssh-server openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY setup/ssh/agent/id_rsa_agent.pub ${ROOT_SSH}/authorized_keys
RUN chmod 600 ${ROOT_SSH}/authorized_keys

RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/Port 22/22/' /etc/ssh/sshd_config && \
    echo "AllowUsers root" >> /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd

RUN mkdir -p ${USER_HOME} && \
    chown -R root:root ${USER_HOME} && \
    chown -R root:root ${ROOT_SSH}

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY agent-android-builder/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash

WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]