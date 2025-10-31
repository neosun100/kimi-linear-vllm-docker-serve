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

### 示例：切换到 QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ

以下示例演示如何停止当前容器，并以新模型 `QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ` 重新启动：
```bash
# 1) 停止并删除当前容器
docker stop kimi48b-awq || true
docker rm kimi48b-awq || true

# 2) 以新模型重启（注意：根据你的端口映射调整 -p）
# 如果你按 README 推荐使用宿主 8002 -> 容器 8000：
docker run --gpus all -d --name kimi48b-awq --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
  -e MODEL="QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ" \
  neosun100/kimi-linear-vllm:latest

# 如果你要直接用宿主 8000（宿主 8000 未被占用时）：
# docker run --gpus all -d --name kimi48b-awq --restart unless-stopped \
#   --ipc=host -p 8000:8000 \
#   -v "$HF_HOME":/root/.cache/huggingface \
#   -v "$VLLM_DOWNLOAD_DIR":/data/vllm_downloads \
#   -e MODEL="QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ" \
#   neosun100/kimi-linear-vllm:latest
```

重启后，用 curl 进行验证（根据你的端口选择 8002 或 8000）：
```bash
# 宿主 8002 -> 容器 8000（推荐映射）
curl -sS http://localhost:8002/v1/models | jq . || true

curl -sS http://localhost:8002/v1/chat/completions \
  -H "Content-Type: application/json" \
  --data '{
    "model": "QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ",
    "messages": [
      {"role": "user", "content": "What is the capital of France?"}
    ]
  }' | jq . || true

# 如使用宿主 8000 端口映射，则将 8002 改为 8000
```

### 一键脚本（推荐，全自动）
已提供**全自动化**可执行脚本，无需任何前置操作，一键执行即可：

```bash
# 直接运行，脚本会自动处理所有情况：
# - 自动检测是否需要 sudo
# - 自动创建缓存目录
# - 自动检查镜像，不存在则先尝试 pull，失败则自动构建
# - 自动停止并删除旧容器
# - 自动启动新容器

./scripts/switch_model.sh "QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ"

# 或使用固定示例脚本（内部已指定该模型）
./scripts/switch_to_qwen3_vl_235b.sh

# 可选：自定义容器名与宿主端口
CONTAINER=my-llm HOST_PORT=18002 ./scripts/switch_model.sh "QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ"
```

**脚本自动化特性**：
- ✅ **自动检测 sudo**：如果普通用户无法执行 docker，自动使用 `sudo docker`
- ✅ **自动镜像管理**：本地不存在时先尝试从 registry pull，失败则自动本地构建（需要 Dockerfile）
- ✅ **自动目录创建**：自动创建 `$HF_HOME` 和 `$VLLM_DOWNLOAD_DIR` 缓存目录
- ✅ **自动容器管理**：自动停止并删除同名旧容器，避免冲突
- ✅ **一致的挂载配置**：与 Kimi 模型完全相同的卷挂载和端口配置
- ✅ **多容器支持**：通过 `CONTAINER` 和 `HOST_PORT` 环境变量支持同时运行多个模型

**使用提示**：
- 首次构建镜像可能需要较长时间（下载基础镜像、安装依赖等），请耐心等待
- 脚本执行成功后会显示容器日志查看和 API 测试命令
- 所有卷挂载路径与之前的 Kimi 配置完全一致，可复用缓存
