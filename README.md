# K3d vLLM Sidecar
A minimal end-to-end system for running local LLMs on Kubernetes (k3d) using vLLM with FastAPI and React.

**Note:** vLLM fails to run on Apple Silicon local Docker environmentv as it is not built for Apple Silicon. Hence, tried to buld the wheel from source (adviced by the vLLM team) for Apple silicon devices. It builts successfully in the Mac local venv. However, Kubernetes pod runs inside a Linux container, it can't access it. Hence, I tried to build vLLM inside the Docker/Kubernetes image (by copying the source to Inference/vllm-source folder and then create the image), so that Kubernetes can run it. Unfortunately, vLLM fails to build inside the Linux ARM64 container.

My next step would be replacing vllm-server container with a lightweight Transformers-based inference server and see if the application can be served.

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

## Requirements
- MacBook M3 Pro
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

##Features ✓

- [x] Model downloads automatically on first deployment
- [x] Model persists across pod restarts (no re-download)
- [x] Health endpoint for monitoring
- [x] Sidecar pattern (FastAPI + inference in same pod)
- [x] Persistent storage with local-path provisioner
- [x] React frontend for user input
- [x] port-forward for local development
- [x] Pure Kubernetes YAML (no Helm needed)


## License

MIT

---

For questions or issues, refer to [IMPLEMENTATION.md](IMPLEMENTATION.md#troubleshooting).
