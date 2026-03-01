#!/usr/bin/env bash
set -e

NAMESPACE="llm-sidecar"

echo "Setting up port-forwards..."
echo ""

cleanup() {
  echo ""
  echo "Cleaning up port-forwards..."
  if [ -n "${FE_PID:-}" ]; then
    kill "${FE_PID}" 2>/dev/null || true
  fi
  if [ -n "${API_PID:-}" ]; then
    kill "${API_PID}" 2>/dev/null || true
  fi
}

trap cleanup SIGINT SIGTERM EXIT

echo "Forwarding frontend service (localhost:3000 -> frontend-service:80)..."
kubectl port-forward -n "${NAMESPACE}" svc/frontend-service 3000:80 >/dev/null 2>&1 &
FE_PID=$!

echo "Forwarding FastAPI service (localhost:8000 -> fastapi-service:8000)..."
kubectl port-forward -n "${NAMESPACE}" svc/fastapi-service 8000:8000 >/dev/null 2>&1 &
API_PID=$!

echo ""
echo "✓ Port-forwards established!"
echo ""
echo "Access points:"
echo "  Frontend: http://localhost:3000"
echo "  API:      http://localhost:8000"
echo "  Health:   http://localhost:8000/health"
echo ""
echo "Press Ctrl+C to stop port-forwarding"
echo ""

wait
