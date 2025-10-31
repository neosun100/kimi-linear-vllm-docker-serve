# 模型切换说明 (Model Switching Guide)

## ❗ 重要：当前设计为单模型模式

**vLLM 在启动时加载指定模型**，默认情况下一个实例只服务一个模型。

### 🔄 切换模型的方法

#### 方法 1：重启容器（推荐，简单可靠）
```bash
# 停止当前容器
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

#### 方法 2：多容器并行（同时服务多个模型）
```bash
# 容器1：Kimi-Linear (port 8002)
docker run --gpus all -d --name kimi-linear --restart unless-stopped \
  --ipc=host -p 8002:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -e MODEL="cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit" \
  neosun100/kimi-linear-vllm:latest

# 容器2：其他模型 (port 8003)
docker run --gpus all -d --name qwen-model --restart unless-stopped \
  --ipc=host -p 8003:8000 \
  -v "$HF_HOME":/root/.cache/huggingface \
  -e MODEL="Qwen/Qwen2.5-32B-Instruct-AWQ" \
  neosun100/kimi-linear-vllm:latest
```

### ❌ 不能直接做的事

**不能这样做：**
```bash
# ❌ 容器启动时只加载了 cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit
# 即使请求里写别的模型名，vLLM 也不会自动下载和加载

curl http://localhost:8002/v1/chat/completions -d '{
  "model": "Qwen/Qwen2.5-32B-Instruct-AWQ",  // ❌ 这个模型没被加载
  "messages": [...]
}'
```

**原因：**
- vLLM 在启动时就决定了要服务哪个模型
- API 请求中的 `model` 参数主要用于验证和日志，不是用来动态加载的

### ✅ 总结

- ❌ **不能**：curl 换 model ID → 自动下载切换（需要重启）
- ✅ **可以**：重启容器时用新的 `MODEL` 环境变量 → 加载新模型
- ✅ **可以**：运行多个容器，每个容器一个模型 → 通过端口区分
