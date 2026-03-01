# K3d vLLM Sidecar MVP

A minimal end-to-end system for running local LLMs on Kubernetes (k3d) using vLLM with FastAPI and React.

## Quick Start

```bash
# 1. Create cluster
./scripts/create-cluster.sh

# 2. Build and deploy
./scripts/build-images.sh
./scripts/deploy.sh

# 3. Port-forward
./scripts/port-forward.sh

# 4. Open browser
open http://localhost:3000
```

Then enter a prompt and see the response!

## System Overview

```
Browser → React Frontend (nginx) → FastAPI Sidecar → vLLM (CPU) → Persistent Model Storage
```

### Key Components

- **Model**: Qwen2.5-1.5B-Instruct (Hugging Face Transformers format, ~2-3GB)
- **Inference**: vLLM OpenAI-compatible server running on CPU
- **API**: FastAPI sidecar for request/response normalization (calls `/v1/chat/completions`)
- **Frontend**: React UI with Vite
- **Storage**: Persistent Volume (local-path) survives pod restarts
- **Download**: Kubernetes initContainer downloads model from Hugging Face on first run
- **Orchestration**: Kubernetes (k3d) with sidecar pattern

## Project Structure

```
.
├── prd.md                          # Product requirements & decisions
├── IMPLEMENTATION.md               # Detailed step-by-step guide
├── README.md                       # This file
├── api/                            # FastAPI application
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── inference/                      # vLLM + model downloader
│   ├── Dockerfile                  # vLLM server
│   ├── model-downloader.Dockerfile # Model downloader
│   └── download-model.py           # Python script for downloading
├── frontend/                       # React UI
│   ├── Dockerfile
│   ├── App.jsx
│   ├── index.html
│   ├── main.jsx
│   ├── nginx.conf
│   ├── package.json
│   └── vite.config.js
├── k8s/                            # Kubernetes manifests
│   ├── configmap.yaml              # Model config
│   ├── fastapi-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── inference-deployment.yaml
│   ├── namespace.yaml
│   └── pvc.yaml
└── scripts/                        # Helper scripts
    ├── build-images.sh
    ├── cleanup.sh
    ├── create-cluster.sh
    ├── deploy.sh
    └── port-forward.sh
```

## Requirements

- MacBook M3 Pro (36 GB RAM recommended)
- Docker Desktop
- k3d v5.0+
- kubectl v1.26+
- Node.js v18+

## Detailed Guide

See [IMPLEMENTATION.md](IMPLEMENTATION.md) for:
- Complete setup instructions
- Step-by-step deployment
- Testing & verification
- Troubleshooting
- Acceptance criteria

## API Reference

### POST /generate
Generate text from a prompt.

**Request:**
```json
{
  "prompt": "What is Kubernetes?"
}
```

**Response:**
```json
{
  "text": "Kubernetes is a container orchestration platform..."
}
```

### GET /health
Health check for the model server.

**Response:**
```json
{
  "status": "ok"
}
```

Returns `503` if the model is still loading.

## Performance

On Apple M3 Pro with CPU inference via vLLM:
- Model download: 3-5 minutes (first deployment only)
- Model load: 1-2 minutes
- First inference: 15-30 seconds
- Subsequent: 10-20 seconds per request
- Memory: ~4-6GB peak

**Note:** CPU inference is slower than Metal GPU, but this MVP prioritizes learning Kubernetes architecture over inference speed.

## MVP Features ✓

- [x] Model downloads automatically on first deployment
- [x] Model persists across pod restarts (no re-download)
- [x] Health endpoint for monitoring
- [x] Sidecar pattern (FastAPI + inference in same pod)
- [x] Persistent storage with local-path provisioner
- [x] React frontend for user input
- [x] port-forward for local development
- [x] Pure Kubernetes YAML (no Helm needed)

## Out of Scope (Post-MVP)

- Streaming responses
- Authentication
- Multiple models
- Autoscaling
- Production deployment
- Metrics/observability

## License

MIT

---

For questions or issues, refer to [IMPLEMENTATION.md](IMPLEMENTATION.md#troubleshooting).
