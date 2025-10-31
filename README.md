# Kimi-Linear-48B-A3B Docker Deployment with vLLM (EN/简体/繁體/日本語)

[English](#english) | [简体中文](#简体中文) | [繁體中文](#繁體中文) | [日本語](#日本語)

---

## English

### Overview
This project demonstrates a production-friendly way to deploy the Kimi-Linear-48B-A3B-Instruct (AWQ-4bit) model with vLLM inside Docker, exposing an OpenAI-compatible API. It covers required dependencies (including `fla-core`), GPU tuning, and a clear path to scale context length from 128K up to 1M tokens.

Model: `cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit`
Engine: vLLM (`vllm/vllm-openai:nightly`)

### Prerequisites
- Docker with NVIDIA runtime and working GPUs (e.g., 4× L40S)
- Internet access to Hugging Face

### Quick Start
```bash
export HF_HOME="$HOME/.cache/huggingface"
export VLLM_DOWNLOAD_DIR="$HOME/vllm_downloads"
mkdir -p "$HF_HOME" "$VLLM_DOWNLOAD_DIR"

sudo docker pull vllm/vllm-openai:nightly

sudo docker run --gpus all -d --name kimi48b-awq --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  -e HF_HUB_ENABLE_HF_TRANSFER=1 \
  --entrypoint /bin/bash vllm/vllm-openai:nightly -lc "\
    pip install -U fla-core >/dev/null 2>&1 && \
    vllm serve cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit \
      --port 8000 \
      --tensor-parallel-size 4 \
      --max-model-len 131072 \
      --dtype half \
      --gpu-memory-utilization 0.5 \
      --max-num-seqs 64 \
      --download-dir /data/vllm_downloads \
      --trust-remote-code"
```

Health check:
```bash
curl http://localhost:8002/v1/models
```
Chat test:
```bash
curl http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [{"role": "user", "content": "Hi, introduce yourself."}],
    "max_tokens": 128
  }'
```

### Scale to 1M Context Length
- Start at `--max-model-len 131072`, then step up: `262144 → 524288 → 1048576`
- If OOM at startup/warmup:
  - Lower `--gpu-memory-utilization` (e.g., 0.6→0.5→0.45)
  - Lower `--max-num-seqs` (e.g., 256→128→64)

### Notes
- For Kimi Linear, install `fla-core >= 0.4.0` inside the container.
- Removing explicit `--quantization` lets vLLM auto-detect AWQ for this model, avoiding conflicts with metadata.

---

## 简体中文

### 简介
该项目在 Docker 中使用 vLLM 部署 Kimi-Linear-48B-A3B-Instruct（AWQ-4bit），并提供 OpenAI 兼容 API。内容包含依赖安装（含 `fla-core`）、GPU 调优，以及从 128K 到 1M 上下文的渐进式扩展方案。

### 快速开始
参考英文部分的启动命令；若显存不足，先降低 `--gpu-memory-utilization` 和 `--max-num-seqs`，再逐步提升 `--max-model-len`。

---

## 繁體中文

### 簡介
本專案示範在 Docker 內以 vLLM 佈署 Kimi-Linear-48B-A3B-Instruct（AWQ-4bit），並暴露 OpenAI 相容 API。包含相依套件（含 `fla-core`）、GPU 調校，及從 128K 擴展至 1M 的實務流程。

### 快速開始
請參考英文啟動指令；若發生 OOM，優先下調 `--gpu-memory-utilization` 與 `--max-num-seqs`，再逐步提升 `--max-model-len`。

---

## 日本語

### 概要
本プロジェクトは、Docker 上で vLLM を用いて Kimi-Linear-48B-A3B-Instruct（AWQ-4bit）を OpenAI 互換 API として提供する実装です。`fla-core` の導入、GPU チューニング、そして 128K から 1M までのコンテキスト長拡張を網羅します。

### クイックスタート
英語セクションのコマンドを参照してください。OOM が出る場合は `--gpu-memory-utilization` と `--max-num-seqs` を下げ、安定後に `--max-model-len` を段階的に引き上げてください。
