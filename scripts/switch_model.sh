#!/usr/bin/env bash
set -euo pipefail

# ???????? - ?????????
# Usage: ./scripts/switch_model.sh "<hf_model_id>"
# Or:    MODEL="<hf_model_id>" ./scripts/switch_model.sh

MODEL_ARG="${1-}"
MODEL="${MODEL:-${MODEL_ARG}}"
if [[ -z "${MODEL}" ]]; then
  echo "[ERROR] Missing model id. Usage: ./scripts/switch_model.sh '<hf_model_id>'" >&2
  exit 1
fi

# ??
CONTAINER="${CONTAINER:-kimi48b-awq}"
HOST_PORT="${HOST_PORT:-8002}"

# ?????????????????????????
# ?????? / ??? -??? Docker ????? /
MODEL_TAG="${MODEL//\//-}"
IMAGE_BASE="${IMAGE_BASE:-neosun100/kimi-linear-vllm}"
IMAGE="${IMAGE:-${IMAGE_BASE}:${MODEL_TAG}}"
echo "[INFO] Using image tag: ${IMAGE} (for model: ${MODEL})"

# ??????????????
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ?????? sudo??????????? docker???? sudo?
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
  if sudo docker ps >/dev/null 2>&1; then
    DOCKER_CMD="sudo docker"
    echo "[INFO] Using 'sudo docker' (regular docker requires sudo)" >&2
  else
    echo "[ERROR] Cannot execute 'docker' or 'sudo docker'. Please check Docker installation and permissions." >&2
    exit 1
  fi
fi

# ??????
HF_HOME="${HF_HOME:-$HOME/.cache/huggingface}"
VLLM_DOWNLOAD_DIR="${VLLM_DOWNLOAD_DIR:-$HOME/vllm_downloads}"
mkdir -p "${HF_HOME}" "${VLLM_DOWNLOAD_DIR}"
echo "[INFO] Cache directories ready: ${HF_HOME}, ${VLLM_DOWNLOAD_DIR}"

# ????????
IMAGE_EXISTS=false
if ${DOCKER_CMD} images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q "^${IMAGE}$"; then
  IMAGE_EXISTS=true
  echo "[INFO] Image '${IMAGE}' found locally"
fi

# ????????????
if [[ "${IMAGE_EXISTS}" == "false" ]]; then
  echo "[INFO] Image '${IMAGE}' not found locally"
  
  # ???? registry pull
  echo "[INFO] Attempting to pull from registry..."
  if ${DOCKER_CMD} pull "${IMAGE}" 2>/dev/null; then
    echo "[INFO] Image pulled successfully from registry"
    IMAGE_EXISTS=true
  else
    echo "[INFO] Pull failed (expected if not pushed to registry), building locally..."
    
    # ?? Dockerfile ????
    if [[ ! -f "${PROJECT_ROOT}/Dockerfile" ]]; then
      echo "[ERROR] Dockerfile not found at ${PROJECT_ROOT}/Dockerfile" >&2
      echo "[ERROR] Cannot build image. Please ensure you're in the project root." >&2
      exit 1
    fi
    
    echo "[INFO] Building image '${IMAGE}' from ${PROJECT_ROOT}/Dockerfile (this may take a while)..."
    cd "${PROJECT_ROOT}"
    if ${DOCKER_CMD} build -t "${IMAGE}" .; then
      echo "[INFO] Image built successfully"
      IMAGE_EXISTS=true
    else
      echo "[ERROR] Build failed. Check Dockerfile and build logs above." >&2
      exit 1
    fi
  fi
fi

# ??????
if [[ "${IMAGE_EXISTS}" == "false" ]]; then
  echo "[ERROR] Image '${IMAGE}' is still not available after pull/build attempt" >&2
  exit 1
fi

echo "[INFO] Switching container '${CONTAINER}' to model: ${MODEL}"

# ???????????????
if ${DOCKER_CMD} ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$"; then
  echo "[INFO] Stopping existing container '${CONTAINER}'..."
  ${DOCKER_CMD} stop "${CONTAINER}" 2>/dev/null || true
  echo "[INFO] Removing existing container '${CONTAINER}'..."
  ${DOCKER_CMD} rm "${CONTAINER}" 2>/dev/null || true
fi

# ?????
echo "[INFO] Starting container '${CONTAINER}' with model '${MODEL}'..."
echo "[INFO] Host port: ${HOST_PORT} -> Container port: 8000"

if ${DOCKER_CMD} run --gpus all -d --name "${CONTAINER}" --restart unless-stopped \
  --ipc=host -p "${HOST_PORT}:8000" \
  -v "${HF_HOME}":/root/.cache/huggingface \
  -v "${VLLM_DOWNLOAD_DIR}":/data/vllm_downloads \
  -e MODEL="${MODEL}" \
  "${IMAGE}"; then
  echo "[SUCCESS] Container '${CONTAINER}' started successfully"
  echo "[INFO] Image used: ${IMAGE} (model-specific tag)"
  echo "[INFO] You can check logs with: ${DOCKER_CMD} logs -f ${CONTAINER}"
  echo "[INFO] Test API with: curl http://localhost:${HOST_PORT}/v1/models"
  echo ""
  echo "[NOTE] If you see CUDA OOM errors, check GPU memory:"
  echo "       nvidia-smi"
  echo "       You may need to stop other containers or reduce GPU_MEM_UTIL"
else
  echo "[ERROR] Failed to start container. Check logs above." >&2
  echo "[INFO] Check container logs: ${DOCKER_CMD} logs ${CONTAINER}" >&2
  echo "[INFO] If OOM error, try: ${DOCKER_CMD} stop $(docker ps -aq) && ${DOCKER_CMD} run ..." >&2
  exit 1
fi
