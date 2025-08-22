FROM node:22-slim

LABEL owner="tezov.app@gmail.com"

ARG COMMAND_LINE_TOOL_VERSION=11076708
ARG ANDROID_SDK_VERSION=35
ARG BUILD_TOOLS_VERSION=34.0.0

USER root

ENV USER_HOME=/home/appium
ENV HOME_ANDROID=/home/android

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=${USER_HOME}/library/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_SDK=${ANDROID_HOME}

ENV PATH=${PATH}:${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}

RUN apt-get update && apt-get install -y \
    procps iputils-ping \
    openjdk-17-jdk curl wget unzip bash && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#RUN echo "Java path: $(readlink -f $(which java))"

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-${COMMAND_LINE_TOOL_VERSION}_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d /tmp && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv /tmp/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

RUN yes | sdkmanager --licenses && sdkmanager \
    "platform-tools" \
    "build-tools;${BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_SDK_VERSION}"

RUN npm install -g appium@2.11.3
RUN npm install -g appium-doctor@1.16.2
RUN appium driver install uiautomator2@3.8.1

COPY android-appium/setup/appium-adb-plugin ${USER_HOME}/appium-adb-plugin
RUN cd ${USER_HOME}/appium-adb-plugin && npm install
RUN appium plugin install --source=local ${USER_HOME}/appium-adb-plugin

RUN mkdir -p ${HOME_ANDROID} && \
    chown -R root:root ${USER_HOME}

WORKDIR ${USER_HOME}
ENTRYPOINT ["appium", "--allow-cors", "--use-plugins=adb-plugin"]
