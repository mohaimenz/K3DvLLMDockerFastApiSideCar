#!/bin/bash

set -e

echo "Cleaning up k3d cluster resources..."
echo ""

echo "Deleting namespace (this will delete all resources)..."
kubectl delete namespace llm-sidecar || true

echo ""
echo "✓ Cleanup complete!"
