FROM alpine:latest

LABEL owner="tezov.app@gmail.com"
    
USER root
ENV COMMAND_HOME=/root/command
    
RUN apk add --no-cache dos2unix && \
    apk add --no-cache bash && \
    apk add --no-cache socat && \
    apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community docker
    
COPY docker-host/setup/command/command_receiver_docker.bash ${COMMAND_HOME}/
RUN dos2unix ${COMMAND_HOME}/command_receiver_docker.bash && \
    chmod +x ${COMMAND_HOME}/command_receiver_docker.bash

#IMPORT LOG FUNCTION
COPY setup/bash/function/log.bash /usr/local/bin/bash/function/
RUN dos2unix /usr/local/bin/bash/function/log.bash

COPY docker-host/setup/entrypoint/ /usr/local/bin/
RUN dos2unix /usr/local/bin/entrypoint.bash && \ 
    chmod +x /usr/local/bin/entrypoint.bash

ENTRYPOINT ["/usr/local/bin/entrypoint.bash"]
    
