FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/models/hf \
    HF_HUB_CACHE=/models/hf

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY vllm-src /app/vllm-src

RUN pip install --no-cache-dir /app/vllm-src
RUN pip install --no-cache-dir transformers huggingface_hub

EXPOSE 8001

CMD ["sh", "-c", "vllm serve \"$MODEL_ID\" --download-dir /models/hf --host 0.0.0.0 --port 8001"]