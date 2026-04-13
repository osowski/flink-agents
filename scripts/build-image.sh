#!/usr/bin/env bash
set -euo pipefail

REGISTRY="quay.io/osowski"
IMAGE_NAME="flink-agents-demo"
TAG=$(git rev-parse --short HEAD)
IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building image: ${IMAGE}"
docker build --build-arg GIT_SHA="${TAG}" -t "${IMAGE}" .

echo "Pushing image: ${IMAGE}"
docker push "${IMAGE}"

echo ""
echo "Image pushed: ${IMAGE}"
echo ""
echo "Update GitOps overlay with:"
echo "  newTag: ${TAG}"
