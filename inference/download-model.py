#!/usr/bin/env python3
"""
Model downloader for vLLM.
Downloads Hugging Face models to persistent storage on first run.
Subsequent runs use cached models.
"""

import os
import sys
from pathlib import Path
from huggingface_hub import snapshot_download

# Configuration
MODEL_ID = os.getenv("MODEL_ID", "Qwen/Qwen2.5-1.5B-Instruct")
CACHE_DIR = os.getenv("HF_HOME", "/models/hf")

def download_model():
    """Download model if not already present."""
    cache_path = Path(CACHE_DIR) / ("models--" + MODEL_ID.replace("/", "--"))
    
    print(f"Model ID: {MODEL_ID}")
    print(f"Cache directory: {CACHE_DIR}")
    print(f"Expected cache path: {cache_path}")
    
    # Check if model already exists
    if cache_path.exists():
        print(f"✓ Model already cached at {cache_path}")
        return True
    
    print(f"Downloading model {MODEL_ID}...")
    
    try:
        # Create cache directory if needed
        Path(CACHE_DIR).mkdir(parents=True, exist_ok=True)
        
        # Download the model
        model_path = snapshot_download(
            repo_id=MODEL_ID,
            cache_dir=CACHE_DIR,
            resume_download=True,
            local_files_only=False
        )
        
        print(f"✓ Model downloaded successfully to {model_path}")
        return True
    
    except Exception as e:
        print(f"✗ Model download failed: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    success = download_model()
    sys.exit(0 if success else 1)
