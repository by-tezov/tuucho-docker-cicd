FROM openjdk:17-jdk-slim

LABEL owner="tezov.app@gmail.com"

ARG NODE_VERSION=22.21.1
ARG KOTLINC_VERSION=2.2.20
ARG DANGER_VERSION=13.0.5
ARG DANGER_KOTLIN_VERSION=1.3.3

USER root

ENV USER_HOME=/home/android-danger
ENV ROOT_SSH=/root/.ssh

ENV GRADLE_HOME=/root/.gradle/wrapper/dists
ENV JAVA_HOME=/usr/local/openjdk-17

ENV PATH=${PATH}:${JAVA_HOME}/bin:/usr/local/danger-kotlin/bin:/usr/local/node/bin:/usr/local/kotlinc/bin

RUN printf "JAVA_HOME=%s\nPATH=%s\n" \
"$JAVA_HOME" "$PATH" >> /etc/environment

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping tree \
    wget curl jq \
    unzip zip xz-utils git bash openssh-server openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz; \
    mkdir -p /usr/local/node; \
    tar -xJf /tmp/node.tar.xz -C /usr/local/node --strip-components=1; \
    ln -sf /usr/local/node/bin/node /usr/local/bin/node; \
    ln -sf /usr/local/node/bin/npm /usr/local/bin/npm; \
    ln -sf /usr/local/node/bin/npx /usr/local/bin/npx; \
    rm /tmp/node.tar.xz; \
    npm install -g "danger@${DANGER_VERSION}"; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p /usr/local/lib/danger /usr/local/bin; \
    curl -sSL "https://github.com/danger/kotlin/releases/download/${DANGER_KOTLIN_VERSION}/danger-kotlin-linuxX64.tar" \
        -o /tmp/danger-kotlin.tar; \
    tar -xf /tmp/danger-kotlin.tar -C /tmp; \
    mv /tmp/bin/danger-kotlin /usr/local/bin/danger-kotlin; \
    mv /tmp/lib/danger/danger-kotlin.jar /usr/local/lib/danger/danger-kotlin.jar; \
    chmod +x /usr/local/bin/danger-kotlin; \
    rm -rf /tmp/danger-kotlin.tar /tmp/lib /tmp/bin

RUN curl -sSL https://github.com/JetBrains/kotlin/releases/download/v${KOTLINC_VERSION}/kotlin-compiler-${KOTLINC_VERSION}.zip -o /tmp/kotlinc.zip && \
    unzip -q /tmp/kotlinc.zip -d /usr/local && \
    ln -sf /usr/local/kotlinc/bin/kotlinc /usr/local/bin/kotlinc && \
    rm /tmp/kotlinc.zip

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
    if [ -d "${GRADLE_HOME}/tmp" ] && [ "$(ls -A ${GRADLE_HOME}/tmp)" ]; then \
        find ${GRADLE_HOME}/tmp -mindepth 2 -maxdepth 2 -type d | while read tmp_hash_folder; do \
            final_dir="${GRADLE_HOME}/$(basename $(dirname ${tmp_hash_folder}))/$(basename ${tmp_hash_folder})"; \
            mkdir -p "${final_dir}"; \
            zip_file_name=$(ls "${tmp_hash_folder}" | head -n 1 | sed 's/.part.*$//'); \
            tmp_tar_file="${tmp_hash_folder}/${zip_file_name}.tar.gz"; \
            cat "${tmp_hash_folder}/${zip_file_name}".part.* > "${tmp_tar_file}"; \
            tar -xzf "${tmp_tar_file}" -C "${tmp_hash_folder}"; \
            unzip -q "${tmp_hash_folder}/${zip_file_name}" -d "${final_dir}"; \
            touch "${final_dir}/${zip_file_name}.ok" "${final_dir}/${zip_file_name}.lck"; \
        done; \
        mv ${GRADLE_HOME}/tmp/CACHEDIR.TAG ${GRADLE_HOME}/; \
        rm -rf ${GRADLE_HOME}/tmp; \
    fi

RUN mkdir -p ${USER_HOME} && \
    chown -R root:root ${USER_HOME} && \
    chown -R root:root ${ROOT_SSH}

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY agent-android-danger/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash

WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]