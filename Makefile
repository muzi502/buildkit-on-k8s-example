# Ensure Make is run with bash shell as some syntax below is bash-specific
SHELL             := /usr/bin/env bash
ROOT_DIR          := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PLATFORM          ?= linux/amd64,linux/arm64
IMAGE_ID          ?= $(shell cat ${ROOT_DIR}/Dockerfile | sha256sum | cut -c 1-12)
IMAGE_NAME        ?= ghcr.io/muzi502/jenkins-agent-pod-image:$(IMAGE_ID)

.PHONY: build-image
build-image:
	docker buildx build \
		--push \
		--platform $(PLATFORM) \
		-t $(IMAGE_NAME) \
		-f $(ROOT_DIR)/Dockerfile \
		$(ROOT_DIR)
