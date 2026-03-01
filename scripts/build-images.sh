#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="127.0.0.1:5001"
PLATFORM="linux/arm64"

echo "Building and pushing images to ${REGISTRY} (${PLATFORM})..."
echo ""

docker buildx create --use --name arm64-builder >/dev/null 2>&1 || docker buildx use arm64-builder >/dev/null 2>&1

build_and_push () {
  local name="$1"
  local dockerfile="$2"
  local context="$3"

  echo "Building: ${name}"
  docker buildx build \
    --platform "${PLATFORM}" \
    -t "${REGISTRY}/${name}:latest" \
    -f "${dockerfile}" \
    --load \
    "${context}"

  echo "Pushing: ${REGISTRY}/${name}:latest"
  docker push "${REGISTRY}/${name}:latest" >/dev/null
  echo "✓ Pushed: ${REGISTRY}/${name}:latest"
  echo ""
}

build_and_push "vllm" "${PROJECT_DIR}/inference/Dockerfile" "${PROJECT_DIR}/inference"
build_and_push "model-downloader" "${PROJECT_DIR}/inference/model-downloader.Dockerfile" "${PROJECT_DIR}/inference"
build_and_push "fastapi-api" "${PROJECT_DIR}/api/Dockerfile" "${PROJECT_DIR}/api"
build_and_push "frontend" "${PROJECT_DIR}/frontend/Dockerfile" "${PROJECT_DIR}/frontend"

echo "Done."