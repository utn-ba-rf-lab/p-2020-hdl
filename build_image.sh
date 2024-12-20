#!/usr/bin/env bash
GIT_DIR=$(git rev-parse --show-toplevel)
docker build -f $GIT_DIR/docker/Dockerfile --build-arg REBUILD=`date +%s` -t icestorm .
