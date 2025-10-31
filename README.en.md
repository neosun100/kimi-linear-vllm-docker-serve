# Kimi-Linear-48B-A3B: vLLM Docker Image Project

This repository is a self-contained Docker image project for serving the Kimi-Linear-48B-A3B-Instruct (AWQ-4bit) model via vLLM. vLLM is used inside the container as a component, while this project focuses on building, running, and publishing the Docker image itself.

## Features
- Based on `vllm/vllm-openai:nightly`
- Installs `fla-core` for Kimi-Linear compatibility
- OpenAI-compatible API
- Easy environment overrides for TP, context length (128K ? 1M), GPU memory utilization, and concurrency
- Makefile for build/run/push convenience

## Build the image
```bash
docker build -t neosun100/kimi-linear-vllm:latest .
```

## Run the container
```bash
# Host caches for faster cold start
export HF_HOME="$HOME/.cache/huggingface"
export VLLM_DOWNLOAD_DIR="$HOME/vllm_downloads"
mkdir -p "$HF_HOME" "$VLLM_DOWNLOAD_DIR"

# Start
docker run --gpus all -d --name kimi48b-awq --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  neosun100/kimi-linear-vllm:latest
```

## Health check and chat
```bash
curl http://localhost:8002/v1/models

curl http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [{"role":"user","content":"Hi!"}],
    "max_tokens": 64
  }'
```

## Environment overrides
You can override these at runtime via `-e KEY=VALUE`:
- `MODEL` (default: `cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit`)
- `PORT` (default: `8000`)
- `TP` (default: `4`)
- `MAX_LEN` (default: `131072`) ? step up to `1048576` for 1M
- `GPU_MEM_UTIL` (default: `0.5`)
- `MAX_NUM_SEQS` (default: `64`)
- `DOWNLOAD_DIR` (default: `/data/vllm_downloads`)

Example:
```bash
docker run --gpus all -d --name kimi48b-awq -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  -e MAX_LEN=1048576 -e GPU_MEM_UTIL=0.45 -e MAX_NUM_SEQS=32 \
  neosun100/kimi-linear-vllm:latest
```

## Push to registries
### Docker Hub
```bash
# Login first
# docker login

docker push neosun100/kimi-linear-vllm:latest
```

### GitHub Container Registry (optional)
```bash
# gh auth login (with write:packages)
docker tag neosun100/kimi-linear-vllm:latest ghcr.io/neosun100/kimi-linear-vllm:latest
docker push ghcr.io/neosun100/kimi-linear-vllm:latest
```

## Makefile shortcuts
```bash
make build
make run HOST_PORT=8002
make logs
make stop
make push
make ghcr-push
```

## Notes
- The image installs `fla-core` to support the Kimi-Linear tokenizer/components.
- We avoid explicit `--quantization` so vLLM auto-detects AWQ for this model.
- Start with 128K context for stability; then escalate to 1M with caution.
