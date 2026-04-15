#!/usr/bin/env bash
set -euo pipefail

REGISTRY="quay.io/osowski"
IMAGE_NAME="flink-agents-demo"
DATE=$(date -u +%Y%m%d)
HASH=$(git rev-parse --short HEAD)
TAG="${DATE}-${HASH}"
IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building image: ${IMAGE}"
docker build --build-arg GIT_SHA="${HASH}" -t "${IMAGE}" .

echo "Pushing image: ${IMAGE}"
docker push "${IMAGE}"

echo ""
echo "Image pushed: ${IMAGE}"
echo ""
echo "Update GitOps overlay with:"
echo "  newTag: ${TAG}"
