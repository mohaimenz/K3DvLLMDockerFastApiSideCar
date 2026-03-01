FROM python:3.11-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    && rm -rf /var/lib/apt/lists/*

# Install huggingface-hub
RUN pip install --no-cache-dir huggingface-hub

# Create model download script
RUN mkdir -p /scripts

COPY download-model.py /scripts/download-model.py

# Set environment variables
ENV HF_HOME=/models/hf \
    TRANSFORMERS_CACHE=/models/hf \
    HUGGINGFACE_HUB_CACHE=/models/hf

CMD ["python", "/scripts/download-model.py"]
