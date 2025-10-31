#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/switch_model.sh "<hf_model_id>"
# Or set env:
#   MODEL="<hf_model_id>" ./scripts/switch_model.sh

MODEL_ARG="${1-}"
MODEL="${MODEL:-${MODEL_ARG}}"
if [[ -z "${MODEL}" ]]; then
  echo "[ERROR] Missing model id. Usage: ./scripts/switch_model.sh '<hf_model_id>'" >&2
  exit 1
fi

# Consistent with Kimi setup
CONTAINER="${CONTAINER:-kimi48b-awq}"
HOST_PORT="${HOST_PORT:-8002}"
IMAGE="${IMAGE:-neosun100/kimi-linear-vllm:latest}"

# Caches (left side can be changed if you prefer different locations)
HF_HOME="${HF_HOME:-$HOME/.cache/huggingface}"
VLLM_DOWNLOAD_DIR="${VLLM_DOWNLOAD_DIR:-$HOME/vllm_downloads}"
mkdir -p "${HF_HOME}" "${VLLM_DOWNLOAD_DIR}"

echo "[INFO] Switching container '${CONTAINER}' to model: ${MODEL}"

# Stop/remove existing container if present
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  docker stop "${CONTAINER}" || true
  docker rm   "${CONTAINER}" || true
fi

# Run with consistent mounts and ports
set -x
exec docker run --gpus all -d --name "${CONTAINER}" --restart unless-stopped \
  --ipc=host -p "${HOST_PORT}:8000" \
  -v "${HF_HOME}":/root/.cache/huggingface \
  -v "${VLLM_DOWNLOAD_DIR}":/data/vllm_downloads \
  -e MODEL="${MODEL}" \
  "${IMAGE}"
