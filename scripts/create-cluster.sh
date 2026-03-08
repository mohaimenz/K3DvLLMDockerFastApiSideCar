#!/usr/bin/env bash
set -e

CLUSTER_NAME="llm-mvp"
REGISTRY_NAME="llm-mvp-registry"
REGISTRY_PORT="5001"
REGISTRY_URL="http://127.0.0.1:${REGISTRY_PORT}"

echo "Creating k3d cluster with local registry..."
echo ""

# Check if cluster already exists (safe for iterative development)
if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${CLUSTER_NAME}"; then
  echo "Cluster '${CLUSTER_NAME}' already exists"
  echo "Registry available at: ${REGISTRY_URL}"
  exit 0
fi

# Create cluster with managed registry exposed on host
k3d cluster create "${CLUSTER_NAME}" \
  --servers 1 \
  --agents 1 \
  --registry-create "${REGISTRY_NAME}:0.0.0.0:${REGISTRY_PORT}" \
  --wait

echo ""
echo "Cluster created successfully"
echo "Registry available at: ${REGISTRY_URL}"
echo ""

# Ensure buildx exists (helpful for ARM64 builds on Apple Silicon)
docker buildx create --use >/dev/null 2>&1 || true

# Verify registry is healthy
echo "Verifying registry health..."
sleep 2
if curl -s "${REGISTRY_URL}/v2/_catalog" >/dev/null 2>&1; then
  echo "Registry is healthy"
else
  echo "Registry not yet responding (may take a moment)"
fi

echo ""
echo "Next steps:"
echo "1. Build images: ./scripts/build-images.sh"
echo "2. Deploy:       ./scripts/deploy.sh"
echo "3. Port-forward: ./scripts/port-forward.sh"
echo ""