import httpx
import logging
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLM API Sidecar")

# Request and response models
class GenerateRequest(BaseModel):
    prompt: str

class GenerateResponse(BaseModel):
    text: str

class HealthResponse(BaseModel):
    status: str

# Configuration
INFERENCE_HOST = os.getenv("INFERENCE_HOST", "localhost")
INFERENCE_PORT = os.getenv("INFERENCE_PORT", "8001")
INFERENCE_TIMEOUT = 120  # seconds
MODEL_ID = os.getenv("MODEL_ID", "Qwen/Qwen2.5-1.5B-Instruct")
SYSTEM_MESSAGE = os.getenv(
    "SYSTEM_MESSAGE",
    "You are a helpful assistant. Answer clearly and directly. If unsure, say so."
)

@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(
                f"http://{INFERENCE_HOST}:{INFERENCE_PORT}/health"
            )
            if response.status_code == 200:
                return {"status": "ok"}
            else:
                raise HTTPException(
                    status_code=503,
                    detail="model not ready"
                )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail="model not ready"
        )

@app.post("/generate", response_model=GenerateResponse)
async def generate(request: GenerateRequest):
    """Generate text from prompt using vLLM."""
    try:
        # Prepare request for vLLM's OpenAI-compatible endpoint
        payload = {
            "model": MODEL_ID,
            "messages": [
                {"role": "system", "content": SYSTEM_MESSAGE},
                {"role": "user", "content": request.prompt}
            ],
            "max_tokens": 256,
            "temperature": 0.7,
            "top_p": 0.9
        }

        async with httpx.AsyncClient(timeout=INFERENCE_TIMEOUT) as client:
            response = await client.post(
                f"http://{INFERENCE_HOST}:{INFERENCE_PORT}/v1/chat/completions",
                json=payload
            )

        if response.status_code == 200:
            data = response.json()
            
            # Extract text from OpenAI-format response
            try:
                text = data["choices"][0]["message"]["content"]
            except (KeyError, IndexError, TypeError) as e:
                logger.error(f"Unexpected vLLM response format: {data}")
                raise HTTPException(
                    status_code=502,
                    detail="Unexpected inference response format"
                )
            
            # Normalize and return
            return {
                "text": text.strip()
            }
        
        elif response.status_code == 503:
            raise HTTPException(
                status_code=503,
                detail="model not ready"
            )
        else:
            logger.error(f"vLLM error: {response.status_code} - {response.text}")
            raise HTTPException(
                status_code=500,
                detail="Inference error"
            )

    except httpx.TimeoutException:
        logger.error("Inference timeout")
        raise HTTPException(
            status_code=500,
            detail="Inference timeout"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "LLM API Sidecar is running"}

