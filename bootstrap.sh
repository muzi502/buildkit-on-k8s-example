#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

BUILDER_NAME=kube
NAMESPACE=buildkit
BUILDX_VERSION=v0.10.4

if ! kubectl get node | grep -q "arch=amd64"; then
    echo "No amd64 nodes found"
    exit 1
fi

if ! kubectl get node | grep -q "arch=arm64"; then
    echo "No arm64 nodes found"
    exit 1
fi

# install buildx plugin
mkdir -p $HOME/.docker/cli-plugins
wget https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-amd64
mv buildx-$BUILDX_VERSION.linux-amd64 $HOME/.docker/cli-plugins/docker-buildx
chmod +x $HOME/.docker/cli-plugins/docker-buildx
docker buildx version

# deploy buildkit on kubernetes
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

docker buildx create \
    --bootstrap \
    --name=${BUILDER_NAME} \
    --driver=kubernetes \
    --platform=linux/amd64 \
    --node=builder-amd64 \
    --driver-opt=namespace=buildkit,replicas=2,nodeselector="kubernetes.io/arch=amd64"

docker buildx create \
    --append \
    --bootstrap \
    --name=${BUILDER_NAME} \
    --driver=kubernetes \
    --platform=linux/arm64 \
    --node=builder-arm64 \
    --driver-opt=namespace=buildkit,replicas=2,nodeselector="kubernetes.io/arch=arm64"

docker buildx use ${BUILDER_NAME}
docker buildx inspect ${BUILDER_NAME}
kubectl create cm buildx.config --from-file=data=$HOME/.docker/buildx/instances/${BUILDER_NAME}
