FROM openjdk:17-jdk-slim

LABEL owner="tezov.app@gmail.com"

ARG COMMAND_LINE_TOOL_VERSION=11076708
ARG ANDROID_SDK_VERSION=35
ARG BUILD_TOOLS_VERSION=34.0.0

USER root

ENV USER_HOME=/home/android
ENV ROOT_SSH=/root/.ssh

ENV JAVA_HOME=/usr/local/openjdk-17
ENV ANDROID_HOME=${USER_HOME}/library/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_SDK=${ANDROID_HOME}

ENV PATH=${PATH}:${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}

RUN printf "JAVA_HOME=%s\nANDROID_HOME=%s\nANDROID_SDK_HOME=%s\nANDROID_SDK_ROOT=%s\nANDROID_SDK=%s\nPATH=%s\n" \
    "$JAVA_HOME" "$ANDROID_HOME" "$ANDROID_SDK_HOME" "$ANDROID_SDK_ROOT" "$ANDROID_SDK" "$PATH" \
    >> /etc/environment

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping wget \
    unzip git bash openssh-server openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOL_VERSION}_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d /tmp && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv /tmp/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

RUN yes | sdkmanager --licenses && sdkmanager \
    "platform-tools" \
    "build-tools;${BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_SDK_VERSION}"

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

RUN chown -R root:root ${USER_HOME} && \
    chown -R root:root ${ROOT_SSH}

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY agent-android-builder/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash

WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]