FROM node:22-slim

LABEL owner="tezov.app@gmail.com"

USER root

ENV USER_HOME=/home/android-qa
ENV COMMAND_HOME=${USER_HOME}/command
ENV ROOT_SSH=/root/.ssh

ENV GRADLE_HOME=/root/.gradle/wrapper/dists

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat tree \
    openjdk-17-jdk wget curl jq \
    unzip zip git bash openssh-server openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN git config --global user.email "tezov.app@gmail.com" && \
    git config --global user.name "tezov jenkins"

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

COPY agent-android-qa/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \
    chmod +x /usr/local/bin/entrypoint.bash
    
WORKDIR ${USER_HOME}
ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]