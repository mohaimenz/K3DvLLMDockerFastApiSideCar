FROM vllm/vllm-openai:latest

# HF cache goes onto the PVC mounted at /models
ENV HF_HOME=/models/hf \
    TRANSFORMERS_CACHE=/models/hf \
    HUGGINGFACE_HUB_CACHE=/models/hf

EXPOSE 8001

CMD [python -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_ID}" \
    --download-dir /models/hf \
    --port 8001 \
    --host 0.0.0.0 \
    --dtype auto \
    --device cpu]
