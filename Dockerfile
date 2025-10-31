# Minimal, self-contained image for serving Kimi-Linear-48B-A3B via vLLM
FROM vllm/vllm-openai:nightly

# Defaults (can be overridden at runtime via -e)
ENV MODEL="cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit" \
    PORT=8000 \
    TP=4 \
    MAX_LEN=131072 \
    GPU_MEM_UTIL=0.5 \
    MAX_NUM_SEQS=64 \
    DOWNLOAD_DIR=/data/vllm_downloads \
    HF_HUB_ENABLE_HF_TRANSFER=1

# Kimi Linear requires fla-core
RUN pip install -U fla-core

# Expose API port
EXPOSE 8000

# Serve; allow env overrides for key knobs
ENTRYPOINT ["/bin/bash","-lc"]
CMD ["vllm serve ${MODEL} --port ${PORT} --tensor-parallel-size ${TP} --max-model-len ${MAX_LEN} --dtype half --gpu-memory-utilization ${GPU_MEM_UTIL} --max-num-seqs ${MAX_NUM_SEQS} --download-dir ${DOWNLOAD_DIR} --trust-remote-code"]
