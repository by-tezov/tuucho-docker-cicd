FROM openjdk:17-jdk-slim

LABEL owner="tezov.app@gmail.com"

ARG COMMAND_LINE_TOOL_VERSION=11076708
ARG ANDROID_SDK_VERSION=35
ARG BUILD_TOOLS_VERSION=34.0.0
ARG ANDROID_AVD_VERSION=34
ENV ANDROID_AVD_VERSION=${ANDROID_AVD_VERSION}

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV EMULATOR_NAME=simulator-${ANDROID_AVD_VERSION}

ENV USER_HOME=/home/android
ENV COMMAND_HOME=${USER_HOME}/command

ENV JAVA_HOME=/usr/local/openjdk-17
ENV ANDROID_HOME=${USER_HOME}/library
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_SDK=${ANDROID_HOME}
ENV ANDROID_AVD_HOME=${ANDROID_HOME}/avd

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV PATH=${PATH}:${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}:${ANDROID_HOME}/emulator

RUN printf "export JAVA_HOME=%s\nexport ANDROID_HOME=%s\nexport ANDROID_SDK_HOME=%s\nexport ANDROID_SDK_ROOT=%s\nexport ANDROID_SDK=%s\nexport ANDROID_AVD_HOME=%s\nexport PATH=%s\n" \
    "$JAVA_HOME" "$ANDROID_HOME" "$ANDROID_SDK_HOME" "$ANDROID_SDK_ROOT" "$ANDROID_SDK" "$ANDROID_AVD_HOME" "$PATH" \
    >> /etc/bash.bashrc

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat \
    iproute2 net-tools sudo wget unzip bzip2 bash locales \
    wmctrl libpulse-dev libdrm-dev libxcb1 libxcb-render0 libxcb-shape0 libxcb-xfixes0 \
    libx11-xcb1 libxrender1 libxext6 libxi6 libxrandr2 libxcursor1 \
    libxdamage1 libxcomposite1 libgl1-mesa-glx libgl1-mesa-dri \
    libfontconfig1 libdbus-1-3 libdbus-glib-1-2 libfreetype6 libxfixes3 \
    libxcb-cursor0 libxkbfile1 libxkbcommon-dev libgbm-dev \
    libasound-dev libegl1-mesa libnss3 libxshmfence-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOL_VERSION}_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d /tmp && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && mkdir -p ${ANDROID_AVD_HOME} && \
    mv /tmp/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

RUN yes | sdkmanager --licenses && sdkmanager --no_https \
    "platform-tools" \
    "emulator" \
    "build-tools;${BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_SDK_VERSION}" \
    "system-images;android-${ANDROID_AVD_VERSION};google_apis;x86_64"

RUN chown -R root:root ${USER_HOME}

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

COPY android-simulator-standalone/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash

WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]