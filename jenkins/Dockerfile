FROM jenkins/jenkins:2.528.3-lts-jdk21

LABEL owner="tezov.app@gmail.com"

USER root

ENV JENKINS_OPTS="--httpPort=80 --prefix=/jenkins"
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

ENV JENKINS_HOME=/var/jenkins_home
ENV USER_HOME=/home/jenkins
ENV JENKINS_HELPER_FILES=${USER_HOME}/helper
ENV COMMAND_HOME=${USER_HOME}/command
ENV JENKINS_SSH=${USER_HOME}/.ssh

RUN apt-get update && apt-get install -y \
    dos2unix procps iputils-ping socat tree \
    curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY jenkins/setup/backup ${JENKINS_HOME}/tmp
RUN cat ${JENKINS_HOME}/tmp/jenkins.tar.part.* > ${JENKINS_HOME}/tmp/jenkins.tar.gz && \
    tar -xzf ${JENKINS_HOME}/tmp/jenkins.tar.gz -C ${JENKINS_HOME}/ --strip-components=1 && \
    rm -rf ${JENKINS_HOME}/tmp

COPY setup/ssh/github/id_ed25519_github ${JENKINS_SSH}/
COPY setup/ssh/github/config ${JENKINS_SSH}/
RUN chmod 700 ${JENKINS_SSH} && \
    chmod 600 ${JENKINS_SSH}/id_ed25519_github && \
    ln -s ${JENKINS_SSH} ${JENKINS_HOME}/.ssh

COPY jenkins/setup/command/command_sender.bash ${COMMAND_HOME}/
RUN dos2unix ${COMMAND_HOME}/command_sender.bash && \
    chmod +x ${COMMAND_HOME}/command_sender.bash && \
    ln -s ${COMMAND_HOME}/command_sender.bash /usr/bin/docker && \
    chown jenkins:jenkins /usr/bin/docker

COPY jenkins/setup/helper/ ${JENKINS_HELPER_FILES}/

RUN chown -R jenkins:jenkins ${USER_HOME} && \ 
    chown -R jenkins:jenkins ${JENKINS_HOME}

USER jenkins
RUN git config --global user.name "tezov.jenkins" && \
    git config --global user.email "tezov.app@gmail.com"
WORKDIR ${JENKINS_HOME}
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
