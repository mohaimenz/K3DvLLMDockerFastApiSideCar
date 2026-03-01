# ✅ DEPLOYMENT READY - GO CHECKLIST

## Pre-Deployment Verification

### ✅ File Structure (23 files)
- api/: app.py, Dockerfile, requirements.txt
- inference/: Dockerfile, model-downloader.Dockerfile, download-model.py
- frontend/: App.jsx, Dockerfile, package.json, nginx.conf, index.html, main.jsx, vite.config.js
- k8s/: 7 YAML manifests
- scripts/: 5 executable shells
- Documentation: prd.md, IMPLEMENTATION.md, README.md

### ✅ Configuration Consistency
- Model: Qwen/Qwen2.5-1.5B-Instruct (11 references across files)
- Namespace: llm-sidecar
- Ports: vLLM (8001), FastAPI (8000), Frontend (80)
- Registry: localhost:5000 (4 image references in K8s)
- PVC: 10Gi local-path storage

### ✅ Critical Fixes Applied
- ✅ Image registry paths updated (localhost:5000)
- ✅ vLLM readinessProbe: /v1/models (checks model load)
- ✅ vLLM livenessProbe: TCP socket (version-agnostic)
- ✅ Readiness initial delay: 180s (CPU-friendly)
- ✅ imagePullPolicy: Always (dev iteration support)
- ✅ download-model.py Path bug fixed
- ✅ Unnecessary VOLUME removed from Dockerfile
- ✅ cleanup.sh made idempotent with || true

### ✅ Scripts Verified
- create-cluster.sh ✓ executable
- build-images.sh ✓ executable
- deploy.sh ✓ executable (updated with kubectl rollout status)
- port-forward.sh ✓ executable (trap cleanup)
- cleanup.sh ✓ executable (idempotent)

### ✅ YAML Manifests Valid
- configmap.yaml ✓
- pvc.yaml ✓
- namespace.yaml ✓
- inference-deployment.yaml ✓
- fastapi-service.yaml ✓
- frontend-deployment.yaml ✓
- frontend-service.yaml ✓

## DEPLOYMENT WORKFLOW

### Step 1: Create Kubernetes Cluster
```bash
./scripts/create-cluster.sh
```
**Expected output:**
- k3d cluster created
- Registry available at localhost:5000
- Docker buildx configured for ARM64

**Time: ~2 minutes**

---

### Step 2: Build Container Images
```bash
./scripts/build-images.sh
```
**Builds 4 images:**
- localhost:5000/vllm:latest
- localhost:5000/model-downloader:latest
- localhost:5000/fastapi-api:latest
- localhost:5000/frontend:latest

**Expected output:**
- All images built for linux/arm64
- All images pushed to registry

**Time: ~5-10 minutes (first run)**

---

### Step 3: Deploy to Kubernetes
```bash
./scripts/deploy.sh
```
**Applies in order:**
1. llm-sidecar namespace
2. ConfigMap (model-id, system-message)
3. PVC (10Gi storage)
4. Inference pod (model-downloader + vllm + fastapi)
5. FastAPI service
6. Frontend pod
7. Frontend service

**Expected output:**
- All pods running/ready
- Services created

**Time: ~2-3 minutes**

---

### Step 4: Setup Port-Forwarding
```bash
./scripts/port-forward.sh
```
**Establishes local access:**
- Frontend: http://localhost:3000
- API: http://localhost:8000
- Health: http://localhost:8000/health

**Ctrl+C to stop** (clean trap cleanup)

**Time: immediate**

---

### Step 5: Test in Browser
Open: **http://localhost:3000**

1. Type a prompt: "Hello, what is machine learning?"
2. Click "Generate"
3. Wait for response (first request ~15-30s, subsequent ~10-20s on CPU)

---

## Debugging Commands

### Check pods
```bash
kubectl get pods -n llm-sidecar
kubectl describe pod inference-api-xxx -n llm-sidecar
```

### Check model download
```bash
kubectl logs -n llm-sidecar -l app=inference-api -c download-model
```

### Check vLLM server
```bash
kubectl logs -n llm-sidecar -l app=inference-api -c vllm-server
```

### Check FastAPI
```bash
kubectl logs -n llm-sidecar -l app=inference-api -c fastapi-sidecar
```

### Test health endpoint
```bash
curl http://localhost:8000/health
```

### Test generate endpoint
```bash
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt":"What is AI?"}'
```

---

## Cleanup After Testing
```bash
./scripts/cleanup.sh
```
**Deletes:**
- llm-sidecar namespace (cascades to all resources)
- All pods
- Services
- PVC

---

## Timeline Estimate (M3 Pro)
| Phase | Duration |
|-------|----------|
| Cluster creation | 1-2 min |
| Image build | 5-10 min |
| Kubernetes deploy | 1-2 min |
| Model download | 3-5 min (~2-3GB) |
| vLLM startup | 1-2 min |
| **Total** | **10-22 min** |

---

## ✅ STATUS: READY FOR DEPLOYMENT

All validation checks passed. No blockers identified.

**Ready to execute:** `./scripts/create-cluster.sh`
