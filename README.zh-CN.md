# Kimi-Linear-48B-A3B?? Docker ?????vLLM ?????

?????? **? Docker ??** ???????? vLLM????? Kimi-Linear-48B-A3B-Instruct?AWQ-4bit???? OpenAI ?? API????????????????????????????? 128K ? 1M ????????????

## ??
- ?? `vllm/vllm-openai:nightly`
- ????? `fla-core`
- ???????? TP/?????/?????/??????????
- ?? Makefile ????/??/??

## ????
```bash
docker build -t neosun100/kimi-linear-vllm:latest .
```

## ????
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

## ???????????????
```bash
curl http://localhost:8002/v1/models

curl http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [{"role":"user","content":"???"}],
    "max_tokens": 64
  }'
```

### Curl ????
- ??????? JSON?
```bash
curl -sS http://localhost:8002/v1/models | jq .
```

- ???????????????
```bash
curl -sS http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [
      {"role": "user", "content": "?????????????"}
    ],
    "max_tokens": 128,
    "stream": false
  }' | jq .
```

- ????????????
```bash
curl -sN http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit",
    "messages": [
      {"role": "user", "content": "????????????"}
    ],
    "stream": true
  }'
```

### ????
```bash
# ????
HOST=localhost PORT=8002 ./scripts/test_models.sh

# ?????????????
HOST=localhost PORT=8002 MAX_TOKENS=128 ./scripts/test_chat.sh

# ??????????
HOST=localhost PORT=8002 ./scripts/test_stream.sh
```

## ???????????? -e ???
- `MODEL`????`cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit`?
- `PORT`????`8000`?
- `TP`????`4`?
- `MAX_LEN`????`131072`??????? `1048576`?
- `GPU_MEM_UTIL`????`0.5`?
- `MAX_NUM_SEQS`????`64`?
- `DOWNLOAD_DIR`????`/data/vllm_downloads`?

???
```bash
docker run --gpus all -d --name kimi48b-awq -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  -e MAX_LEN=1048576 -e GPU_MEM_UTIL=0.45 -e MAX_NUM_SEQS=32 \
  neosun100/kimi-linear-vllm:latest
```

## ????
### Docker Hub
```bash
# docker login
docker push neosun100/kimi-linear-vllm:latest
```

### GitHub Container Registry????
```bash
# gh auth login??? write:packages?
docker tag neosun100/kimi-linear-vllm:latest ghcr.io/neosun100/kimi-linear-vllm:latest
docker push ghcr.io/neosun100/kimi-linear-vllm:latest
```

## Makefile ??
```bash
make build
make run HOST_PORT=8002
make logs
make stop
make push
make ghcr-push
```

## ??
- ????? `fla-core` ??? Kimi-Linear ? tokenizer/??
- ???? 128K ????????? 1M
- ????? `--quantization`?? vLLM ???? AWQ

## 模型切换（重要）

vLLM 会在「启动时」加载并占用显存来服务一个模型，请注意：
- ❌ 仅在 curl 请求里更换 `model` 字段，**不会**触发自动下载/加载新模型；仍然只会服务启动时加载的那个模型。
- ✅ 切换模型有两种实用方式：
  - 方式一（推荐）：重启容器，并用新的 `MODEL` 环境变量
  - 方式二：同时运行多个容器（每个容器一个模型，用不同端口区分）

### 方式一：重启容器切换模型
```bash
# 停止并删除旧容器
docker stop kimi48b-awq
docker rm kimi48b-awq

# 用新模型重启（通过 -e MODEL=... 覆盖）
docker run --gpus all -d --name kimi48b-awq --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  -e MODEL="your-new-model-id" \
  neosun100/kimi-linear-vllm:latest
```

### 方式二：多容器并行（同时服务多个模型）
```bash
# 容器1：Kimi-Linear (port 8002)
docker run --gpus all -d --name kimi-linear --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -e MODEL="cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit" \
  neosun100/kimi-linear-vllm:latest

# 容器2：例如 Qwen (port 8003)
docker run --gpus all -d --name qwen-model --restart unless-stopped \
  --ipc=host -p 8003:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -e MODEL="Qwen/Qwen2.5-32B-Instruct-AWQ" \
  neosun100/kimi-linear-vllm:latest
```

### FAQ
- 为什么必须重启？因为引擎在启动时就初始化显存与权重；换模型需要释放并重新初始化。
- 我能否只改 curl 的 `model` 参数？不行，它主要用于校验/日志，并不会触发模型热切换。

更多说明参见：`docs/MODEL_SWITCHING.md`
