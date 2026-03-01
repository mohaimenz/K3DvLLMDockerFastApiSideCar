# Implementation Guide — K3d vLLM Sidecar MVP

This guide walks through building, deploying, and testing the MVP system on your MacBook M3 Pro using vLLM (CPU inference) for model serving.

**Note:** This is a learning-focused implementation. CPU inference will be slower than GPU-accelerated backends, but it's suitable for understanding the Kubernetes + sidecar architecture.

---

## Prerequisites

Ensure you have the following installed:

- **Docker Desktop** (with Kubernetes support)
- **k3d** (v5.0+)
- **kubectl** (v1.26+)
- **Node.js** (v18+) for building the frontend
- **Git**

Verify installations:

```bash
docker --version
k3d version
kubectl version --client
node --version
```

---

## Project Structure

```
K3dVllmSidecar/
├── prd.md                          # Original PRD
├── IMPLEMENTATION.md               # This guide
├── README.md                       # Quick start
├── api/                            # FastAPI sidecar
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
├── inference/                      # vLLM server + model downloader
│   ├── Dockerfile
│   ├── model-downloader.Dockerfile
│   └── download-model.py
├── frontend/                       # React UI
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   ├── main.jsx
│   ├── App.jsx
│   └── nginx.conf
├── k8s/                            # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── inference-deployment.yaml
│   ├── fastapi-service.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
└── scripts/                        # Helper scripts
    ├── create-cluster.sh
    ├── build-images.sh
    ├── deploy.sh
    ├── port-forward.sh
    └── cleanup.sh
```

---

## Step 1: Create k3d Cluster

Create a new k3d cluster with a local Docker registry:

```bash
chmod +x scripts/create-cluster.sh
./scripts/create-cluster.sh
```

This creates a cluster named `llm-mvp` with:
- 1 server node
- 1 agent node
- Local registry at `localhost:5000`

Verify the cluster is running:

```bash
k3d cluster list
kubectl cluster-info
```

---

## Step 2: Install npm Dependencies (Frontend)

The frontend requires npm packages. Install them:

```bash
cd frontend
npm install
cd ..
```

This installs Vite, React, and build tools needed to compile the React app.

---

## Step 3: Build Docker Images

Build all container images **explicitly for ARM64** (Apple Silicon) and push to the k3d registry:

```bash
chmod +x scripts/build-images.sh
./scripts/build-images.sh
```

**Important:** This script builds images using `docker buildx` with explicit `--platform linux/arm64` to ensure native ARM64 images on your M3 Pro.

**Why this matters:**
- If amd64 images are used on ARM64, Docker emulates them → extremely slow and flaky vLLM performance
- Native ARM64 builds run at full speed

The script will:
1. Check for `docker buildx` (installs if needed)
2. Build all 4 images explicitly for `linux/arm64`
3. Tag them for `localhost:5000` registry
4. Load them locally (ready to push)

Expected output:
```
Building Docker images for ARM64 (Apple Silicon)...
Target platform: linux/arm64

✓ vLLM image built (ARM64)
✓ Model downloader image built (ARM64)
✓ FastAPI image built (ARM64)
✓ Frontend image built (ARM64)
```

**Verify images are ARM64:**
```bash
docker inspect localhost:5000/vllm:latest | grep -i 'architecture\|os\|arch'
```

Then push to the registry:

```bash
docker push localhost:5000/vllm:latest
docker push localhost:5000/model-downloader:latest
docker push localhost:5000/fastapi-api:latest
docker push localhost:5000/frontend:latest
```

---

## Step 4: Deploy to Kubernetes

Deploy all manifests to the cluster:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

This applies all Kubernetes resources in order:
1. Namespace (`llm-sidecar`)
2. ConfigMap (model configuration: ID, system message)
3. PersistentVolumeClaim (10Gi for model storage)
4. Inference + FastAPI Deployment (with initContainer for model download)
5. FastAPI Service
6. Frontend Deployment
7. Frontend Service

Monitor pod status:

```bash
kubectl get pods -n llm-sidecar -w
```

Expected output after a few minutes:

```
NAME                              READY   STATUS    RESTARTS   AGE
frontend-xxxxx                    1/1     Running   0          2m
inference-api-xxxxx               2/2     Running   0          3m
```

Wait until both pods show `2/2 Running` and `1/1 Running`.

**⚠️ First deployment may take 10-20 minutes because:**
1. The model downloader initContainer downloads the Qwen2.5-1.5B model (~2-3GB) from Hugging Face
2. vLLM loads the model into memory (1-2 minutes)
3. CPU inference startup is slower than GPU

Check logs to verify the model is downloading:

```bash
kubectl logs -n llm-sidecar deployment/inference-api -c download-model -f
```

You should see:

```
Model ID: Qwen/Qwen2.5-1.5B-Instruct
Cache directory: /models/hf
Downloading model Qwen/Qwen2.5-1.5B-Instruct...
✓ Model downloaded successfully to /models/hf/models--Qwen--Qwen2.5-1.5B-Instruct/...
```

Once download completes, check vLLM startup:

```bash
kubectl logs -n llm-sidecar deployment/inference-api -c vllm-server -f
```

You should see startup messages confirming the model is loaded.

---

## Step 5: Setup Port-Forwarding

Expose services locally via port-forwarding:

```bash
chmod +x scripts/port-forward.sh
./scripts/port-forward.sh
```

You should see:

```
✓ Port-forwards established!

Access points:
  Frontend: http://localhost:3000
  API:      http://localhost:8000
  Health:   http://localhost:8000/health

Press Ctrl+C to stop port-forwarding
```

---

## Step 6: Test the System

### Test Health Check

In a new terminal:

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{
  "status": "ok"
}
```

If you get `{"detail": "model not ready"}`, the inference container is still loading. Wait a few more minutes and retry.

### Test Generation

```bash
curl -X POST http://localhost:8000/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is Kubernetes?"}'
```

Expected response (after ~10-30 seconds):

```json
{
  "text": "Kubernetes is a container orchestration platform..."
}
```

### Access Frontend

Open your browser:

```
http://localhost:3000
```

You should see:
- A textbox with placeholder "Enter your prompt here..."
- A "Generate" button

Try entering a prompt:

```
What is Kubernetes?
```

Click "Generate" and wait for the response to appear below.

---

## Step 7: Verify Persistence

Confirm that the model persists across pod restarts.

### Restart the Inference Pod

```bash
kubectl delete pod -n llm-sidecar -l app=inference-api
```

The pod will restart automatically.

Monitor the restart:

```bash
kubectl get pods -n llm-sidecar -w
```

Once the pod comes back to `2/2 Running`, test the API again:

```bash
curl http://localhost:8000/health
```

If the health check returns `200 OK`, the model is cached and was **not** re-downloaded.

Check the logs to confirm:

```bash
kubectl logs -n llm-sidecar deployment/inference-api -c download-model --tail=20
```

You should see:

```
✓ Model already cached at /models/hf/models--Qwen--Qwen2.5-1.5B-Instruct
```

This confirms persistence is working.

---

## Understanding the Architecture

### Data Flow

```
Browser (localhost:3000)
    ↓
nginx (frontend-service)
    ↓
    ├─→ React App (loaded as HTML+JS)
    │
    └──→ API Proxy (at /api)
        ↓
kubectl port-forward (localhost:8000)
        ↓
FastAPI Service (8000)
        ↓
FastAPI Sidecar Container
        ↓
HTTP localhost:8001 (/v1/chat/completions)
        ↓
vLLM OpenAI-Compatible Server (CPU)
        ↓
Model at /models/hf/models--Qwen--Qwen2.5-1.5B-Instruct (Persistent Volume)
```

### Kubernetes Resources

1. **namespace**: Isolated `llm-sidecar` namespace
2. **PersistentVolumeClaim**: 10Gi `local-path` storage for model cache
3. **ConfigMap**: Model ID and system message configuration
4. **inference-api Deployment**: Pod with 3 containers
   - **download-model** initContainer: Downloads model from Hugging Face on first run
   - **vllm-server** container: OpenAI-compatible API server (port 8001)
   - **fastapi-sidecar** container: Public API wrapper (port 8000)
5. **fastapi-service**: ClusterIP service routing to FastAPI
6. **frontend Deployment**: Static React build served via nginx
7. **frontend-service**: ClusterIP service routing to nginx

---

## Troubleshooting

### Pod Not Starting

Check events:

```bash
kubectl describe pod -n llm-sidecar -l app=inference-api
```

Look for `ImagePullBackOff` or `ErrImagePull`:

```bash
# List images in k3d
docker images | grep localhost:5000
```

If images aren't found, rebuild and push:

```bash
./scripts/build-images.sh
docker push localhost:5000/vllm:latest
docker push localhost:5000/model-downloader:latest
docker push localhost:5000/fastapi-api:latest
```

### Model Download Stuck

The model download can take 10-20 minutes depending on network speed. Check the download progress:

```bash
kubectl logs -n llm-sidecar deployment/inference-api -c download-model -f
```

Wait patiently for the model to finish downloading. If you see errors after waiting:

```bash
kubectl delete pod -n llm-sidecar -l app=inference-api
```

The pod will restart and retry the download.

### API Returns 503 (Model Not Ready)

This is normal during startup. The inference server takes 1-2 minutes to load the 3.5GB model.

Wait and retry:

```bash
sleep 30 && curl http://localhost:8000/health
```

If it persists after 5 minutes, check vLLM startup logs:

```bash
kubectl logs -n llm-sidecar deployment/inference-api -c vllm-server -f
```

### Frontend Shows "Failed to connect"

Ensure port-forwarding is running:

```bash
ps aux | grep "port-forward"
```

If not, restart it:

```bash
./scripts/port-forward.sh
```

Then refresh the browser: `Ctrl+R`

---

## Performance Notes

On your MacBook M3 Pro with CPU inference via vLLM:

- **First request latency**: 30-60 seconds (model loading + CPU generation)
- **Subsequent requests**: 20-40 seconds (CPU generation only)
- **Model load time**: 2-3 minutes on first deployment (HF download + model initialization)
- **Memory usage**: ~8-10GB peak (model weights in memory)
- **Inference speed**: Slower than GPU, but suitable for learning Kubernetes patterns

**Note:** CPU inference is much slower than Metal GPU acceleration. This is intentional for the learning goal. For production, use GPU acceleration.

**Why vLLM on CPU?** This MVP focuses on learning Kubernetes + sidecar architecture. The inference speed is acceptable for testing the system end-to-end.

---

## Running Acceptance Test

Follow these steps to complete the MVP acceptance criteria:

```bash
# 1. Start cluster and wait for pods
./scripts/create-cluster.sh
sleep 30
./scripts/deploy.sh
sleep 300  # Wait for model to download and load

# 2. Setup port-forwarding in a background terminal
./scripts/port-forward.sh &

# 3. Test health
curl http://localhost:8000/health

# 4. Open frontend
open http://localhost:3000

# 5. Enter prompt in browser
# Prompt: "What is Kubernetes?"

# 6. Verify response appears

# 7. Restart pod
kubectl delete pod -n llm-sidecar -l app=inference-api
sleep 60  # Wait for restart

# 8. Verify model was not re-downloaded
kubectl logs -n llm-sidecar deployment/inference-api -c download-model --tail=5

# 9. Test health again
curl http://localhost:8000/health
```

✓ **Acceptance test complete** when all steps succeed without manual intervention.

---

## Cleanup

To tear down the entire system:

```bash
# Delete all Kubernetes resources
./scripts/cleanup.sh

# Delete the k3d cluster
k3d cluster delete llm-mvp
```

---

## Next Steps (Post-MVP)

Future enhancements:
- Streaming token responses
- Conversation memory
- Authentication
- Multiple model support
- Helm charts
- CI/CD pipeline

---

**MVP System Ready!**
