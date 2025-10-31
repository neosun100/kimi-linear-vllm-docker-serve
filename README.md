# Kimi-Linear-48B-A3B: vLLM Docker Image Project (English)

This repository is a pure Docker image project for serving the Kimi-Linear-48B-A3B-Instruct (AWQ-4bit) model via vLLM. vLLM is used as a component inside the image; this project focuses on building, running, and publishing the image.

- Other languages: [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md)

## Features
- Based on `vllm/vllm-openai:nightly`
- Installs `fla-core` for Kimi-Linear compatibility
- OpenAI-compatible API
- Environment overrides for `TP`, context length (128K → 1M), GPU memory utilization, and concurrency
- Makefile for convenient `build/run/push`

## Build
```bash
docker build -t neosun100/kimi-linear-vllm:latest .
```

## Run
```bash
export HF_HOME="$HOME/.cache/huggingface"
export VLLM_DOWNLOAD_DIR="$HOME/vllm_downloads"
mkdir -p "$HF_HOME" "$VLLM_DOWNLOAD_DIR"

docker run --gpus all -d --name kimi48b-awq --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  neosun100/kimi-linear-vllm:latest
```

## Health check & chat
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

### Curl testing cookbook
- List models (expect JSON with model id):
```bash
curl -sS http://localhost:8002/v1/models | jq .
```

- Non-stream chat (waits for full response):
```bash
curl -sS http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [
      {"role": "user", "content": "Give me a one-sentence fun fact about space."}
    ],
    "max_tokens": 128,
    "stream": false
  }' | jq .
```

- Stream chat (tokens stream incrementally):
```bash
curl -sN http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [
      {"role": "user", "content": "Write a single witty one-liner."}
    ],
    "stream": true
  }'
```

### Scripted tests (recommended)
```bash
# List models
HOST=localhost PORT=8002 ./scripts/test_models.sh

# Non-stream chat (Chinese prompt by default)
HOST=localhost PORT=8002 MAX_TOKENS=128 ./scripts/test_chat.sh

# Stream chat (prints tokens progressively)
HOST=localhost PORT=8002 ./scripts/test_stream.sh
```

## Environment overrides
- `MODEL` (default: `cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit`)
- `PORT` (default: `8000`)
- `TP` (default: `4`)
- `MAX_LEN` (default: `131072`) → step up to `1048576` for 1M
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

## Push
### Docker Hub
```bash
# docker login
docker push neosun100/kimi-linear-vllm:latest
```

### GitHub Container Registry (optional)
```bash
# gh auth login (write:packages)
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
- `fla-core` is installed in-image for Kimi-Linear support.
- Start with 128K for stability; escalate to 1M as resources allow.
- We avoid explicit `--quantization` so vLLM auto-detects AWQ for this model.
