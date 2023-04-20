FROM python:3.10-slim
ARG BUILDER_NAME=kube
COPY --from=docker.io/library/docker:20.10.12-dind-rootless /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker.io/docker/buildx-bin:v0.10 /buildx /usr/libexec/docker/cli-plugins/docker-buildx
RUN apt-get update && \
    apt-get install -yqq jq sshpass openssh-client make git rsync wget && \
    rm -rf /var/lib/apt/lists/*
