#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$PROJECT_DIR/k8s"
NAMESPACE="llm-sidecar"

echo "Deploying to k3d cluster..."

echo "Applying namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

echo "Applying ConfigMap..."
kubectl apply -f "$K8S_DIR/configmap.yaml"

echo "Applying PVC..."
kubectl apply -f "$K8S_DIR/pvc.yaml"

echo "Applying inference + FastAPI deployment..."
kubectl apply -f "$K8S_DIR/inference-deployment.yaml"

echo "Applying FastAPI service..."
kubectl apply -f "$K8S_DIR/fastapi-service.yaml"

echo "Applying frontend deployment..."
kubectl apply -f "$K8S_DIR/frontend-deployment.yaml"

echo "Applying frontend service..."
kubectl apply -f "$K8S_DIR/frontend-service.yaml"

echo ""
echo "Waiting for deployments to be ready..."

kubectl rollout status -n "$NAMESPACE" deployment/inference-api --timeout=300s
kubectl rollout status -n "$NAMESPACE" deployment/frontend --timeout=120s

echo ""
echo "Pods:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "Services:"
kubectl get services -n "$NAMESPACE"
