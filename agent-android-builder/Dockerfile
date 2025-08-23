FROM openjdk:17-jdk-slim

LABEL owner="tezov.app@gmail.com"

ARG COMMAND_LINE_TOOL_VERSION=11076708
ARG ANDROID_SDK_VERSION=android-35
ARG BUILD_TOOLS_VERSION=34.0.0

USER root

ENV USER_HOME=/home/android
ENV ROOT_SSH=/root/.ssh

ENV GRADLE_HOME=/root/.gradle/wrapper/dists
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
    dos2unix procps iputils-ping \
    unzip git bash openssh-server openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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

COPY setup/gradle/ ${GRADLE_HOME}/tmp/
RUN set -eux; \
    find ${GRADLE_HOME}/tmp -mindepth 2 -maxdepth 2 -type d | while read tmp_hash_folder; do \
        final_dir="${GRADLE_HOME}/$(basename $(dirname ${tmp_hash_folder}))/$(basename ${tmp_hash_folder})"; \
        mkdir -p "${final_dir}"; \
        zip_file_name=$(ls "${tmp_hash_folder}" | head -n 1 | sed 's/.part.*$//'); \
        tmp_tar_file="${tmp_hash_folder}/${zip_file_name}.tar.gz"; \
        cat "${tmp_hash_folder}/${zip_file_name}".part.* > "${tmp_tar_file}"; \
        tar -xzf "${tmp_tar_file}" -C "${tmp_hash_folder}"; \
        unzip -q "${tmp_hash_folder}/${zip_file_name}" -d "${final_dir}"; \
        touch "${final_dir}/${zip_file_name}.ok" "${final_dir}/${zip_file_name}.lck"; \
    done \
    && mv ${GRADLE_HOME}/tmp/CACHEDIR.TAG ${GRADLE_HOME}/ \
    && rm -rf ${GRADLE_HOME}/tmp

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