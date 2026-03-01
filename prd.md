# PRD — MVP Implementation (Final Updated Version)

## Local LLM Serving on k3d using vLLM (CPU) + FastAPI Sidecar + React Frontend

This document consolidates all decisions and updates the MVP PRD to reflect the **vLLM-based architecture requirement**.

The goal remains:

> Learn Kubernetes + sidecar architecture + model serving using **vLLM** locally on Apple Silicon.

---

# 1. Project Objective

Build a minimal end-to-end system that runs entirely inside a **k3d Kubernetes cluster**:

Browser → React → FastAPI → vLLM → Model → Response

The system demonstrates:

* Kubernetes deployment patterns
* Sidecar architecture
* Model serving using vLLM
* Persistent model caching
* API orchestration
* Local development workflow

---

# 2. Architecture Overview

```text
Browser
   |
   v
Frontend Service (React)
   |
   v
FastAPI Service
   |
   v
Pod (Sidecar Pattern)
   ├── vLLM container (CPU inference)
   └── FastAPI container
   |
   v
Persistent Volume (/models)
```

Everything runs locally via **k3d**.

---

# 3. Inference Engine

## 3.1 Engine

**vLLM CPU (ARM64 / Apple Silicon compatible)**

* Runs OpenAI-compatible HTTP server
* Uses Hugging Face Transformers models
* CPU inference acceptable for MVP learning goals

Metal GPU acceleration is **not required** for this project.

---

# 4. Model Selection

## 4.1 Primary Model

```
Qwen/Qwen2.5-1.5B-Instruct
```

## 4.2 Alternative Model

```
microsoft/Phi-3.5-mini-instruct
```

Both are:

* Small instruct/chat models
* Suitable for Q&A systems
* Public Hugging Face repositories
* No authentication required

---

# 5. Model Format

Models use **native Hugging Face Transformers format**:

* SafeTensors / PyTorch weights
* NOT GGUF

This is required for vLLM compatibility.

---

# 6. Model Size Expectations

Approximate storage requirements:

* 3B model FP16: ~5–6 GB
* Cache overhead: ~1–2 GB

PVC requirement:

```
10Gi minimum
```

---

# 7. Model Download Strategy

## 7.1 InitContainer

Model download performed by a Kubernetes **initContainer**.

Implementation:

* Python container with `huggingface-hub`
* Uses `snapshot_download()` API
* Downloads into shared PVC

Cache path:

```
/models/hf
```

Environment variables:

```
HF_HOME=/models/hf
TRANSFORMERS_CACHE=/models/hf
HUGGINGFACE_HUB_CACHE=/models/hf
```

The initContainer:

* Checks if model already exists
* Downloads only if missing
* Exits before vLLM starts

---

# 8. Persistent Storage

PVC mount path:

```
/models
```

StorageClass:

```
local-path
```

Purpose:

* Model caching
* Avoid repeated downloads
* Faster restarts

---

# 9. API Design

## 9.1 FastAPI Public Endpoints

### POST /generate

Request:

```json
{
  "prompt": "string"
}
```

Response:

```json
{
  "text": "generated response"
}
```

### GET /health

```json
{
  "status": "ok"
}
```

---

# 10. FastAPI → vLLM Communication

FastAPI calls:

```
POST /v1/chat/completions
```

Internal transformation:

User request:

```json
{ "prompt": "Explain Kubernetes" }
```

Converted to:

```json
{
  "model": "MODEL_ID",
  "messages": [
    {"role": "system", "content": "SYSTEM_MESSAGE"},
    {"role": "user", "content": "Explain Kubernetes"}
  ],
  "max_tokens": 256,
  "temperature": 0.7,
  "top_p": 0.9
}
```

---

# 11. System Message Configuration

System message:

* Default provided
* Configurable via environment variable

Default:

> You are a helpful assistant. Answer clearly and directly. If unsure, say so.

---

# 12. Generation Defaults

| Parameter   | Value |
| ----------- | ----- |
| max_tokens  | 256   |
| temperature | 0.7   |
| top_p       | 0.9   |

Single final response only.

No streaming required.

---

# 13. Timeout Behavior

FastAPI → vLLM timeout:

```
120 seconds
```

---

# 14. Error Handling

| Scenario          | Behavior |
| ----------------- | -------- |
| Model loading     | HTTP 503 |
| Inference error   | HTTP 500 |
| Invalid input     | HTTP 400 |
| Unexpected format | HTTP 502 |

Frontend displays messages directly.

---

# 15. Pod Architecture

Backend Deployment contains:

Container 1 — vLLM
Container 2 — FastAPI

Shared:

* Persistent volume
* Localhost networking

---

# 16. Frontend Design

React frontend deployed separately.

Responsibilities:

* Textbox input
* Submit button
* Response display
* Loading state
* Error state

---

# 17. Frontend Service

Service port:

```
80
```

Access via:

```
kubectl port-forward
```

Two port-forwards:

* Frontend
* FastAPI

NodePort not required.

---

# 18. Resource Strategy

MVP approach:

* Specify resource **requests**
* Avoid strict **limits**

Reason:

Prevent OOM during experimentation.

---

# 19. Performance Expectations

CPU inference latency:

* Tens of seconds per request possible
* Acceptable for learning environment

Primary goal:

Infrastructure learning, not speed.

---

# 20. Container Strategy

Preferred:

```
vllm/vllm-openai
```

ARM64 tag if available.

Fallback:

Custom Python image building vLLM CPU from source.

---

# 21. Hugging Face Authentication

Models are public.

HF token:

Not required for MVP.

Optional future enhancement:

Kubernetes secret for private models.

---

# 22. Fallback Strategy (Important)

If vLLM CPU fails on Apple Silicon:

Fallback option:

* Replace inference container with llama.cpp Metal
* Keep FastAPI + React unchanged

This maintains learning continuity.

---

# 23. Kubernetes Cluster Configuration

Recommended:

* 1 server node
* 1 agent node
* Local registry enabled

---

# 24. Acceptance Criteria

System is successful when:

* Model downloads automatically.
* Model persists after restart.
* `/generate` returns output.
* `/health` returns OK.
* Frontend communicates successfully.
* Port-forward works reliably.
* No manual intervention required.

---

# 25. Out of Scope

* Streaming tokens
* Authentication
* Autoscaling
* Observability stack
* Production deployment
* Helm charts

---

# 26. Definition of Done

Project complete when:

* Kubernetes manifests work end-to-end
* Model serving functional
* Persistent storage verified
* Frontend integrated
* Documentation provided

---

# 27. Future Extensions

Possible next steps:

* GPU inference
* Metal-accelerated backend
* Streaming responses
* Conversation memory
* Authentication
* Helm packaging
* Multi-model support

---

End of Document.