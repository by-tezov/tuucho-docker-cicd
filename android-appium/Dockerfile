FROM node:22-slim

LABEL owner="tezov.app@gmail.com"

ARG COMMAND_LINE_TOOL_VERSION=11076708
ARG ANDROID_SDK_VERSION=android-35
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
    openjdk-17-jdk curl unzip bash && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#RUN echo "Java path: $(readlink -f $(which java))"

COPY setup/android/ ${ANDROID_HOME}/tmp/
RUN set -eux; \
    #cmdline-tools
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest; \
    cat ${ANDROID_HOME}/tmp/cmdline-tools/${COMMAND_LINE_TOOL_VERSION}/${COMMAND_LINE_TOOL_VERSION}.tar.part.* \
      | tar -xzf - -C ${ANDROID_HOME}/cmdline-tools/latest --strip-components=1; \
    #platform-tools
    mkdir -p ${ANDROID_HOME}/platform-tools; \
    cat ${ANDROID_HOME}/tmp/platform-tools/platform-tools.tar.part.* \
      | tar -xz -C ${ANDROID_HOME}/platform-tools --strip-components=1; \
    #build-tools
    mkdir -p ${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}; \
    cat ${ANDROID_HOME}/tmp/build-tools/${BUILD_TOOLS_VERSION}/${BUILD_TOOLS_VERSION}.tar.part.* \
      | tar -xz -C ${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION} --strip-components=1; \
    #platforms
    mkdir -p ${ANDROID_HOME}/platforms/${ANDROID_SDK_VERSION}; \
    cat ${ANDROID_HOME}/tmp/platforms/${ANDROID_SDK_VERSION}/${ANDROID_SDK_VERSION}.tar.part.* \
      | tar -xz -C ${ANDROID_HOME}/platforms/${ANDROID_SDK_VERSION} --strip-components=1; \
    #licenses
    cp -r ${ANDROID_HOME}/tmp/licenses ${ANDROID_HOME}/licenses; \
    #cleanup
    rm -rf ${ANDROID_HOME}/tmp

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
