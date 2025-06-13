#!/usr/bin/env bash
GIT_DIR=$(git rev-parse --show-toplevel)
docker run -it --rm \
           -v $GIT_DIR:$GIT_DIR \
           -v ${HOME}:${HOME} \
           -v /dev/:/dev/ \
           -v /etc/passwd:/etc/passwd:ro \
           -v /etc/shadow:/etc/shadow:ro \
           -v /etc/group:/etc/group:ro \
           -v /tmp:/tmp \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           -v /var/run/dbus:/var/run/dbus \
           -v /usr/share/git/completion:/usr/share/git/completion \
           -h $(hostnamectl hostname)_docker \
           -e DISPLAY=$DISPLAY \
           --privileged \
           -i -w $PWD -t -u $(id -u):$(id -g) --rm \
           --group-add=root \
           icestorm \
           /bin/bash

#           --group-add=plugdev \
#           --group-add=sudo \

