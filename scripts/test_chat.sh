#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-localhost}"
PORT="${PORT:-8002}"
MODEL="${MODEL:-cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit}"
MAX_TOKENS="${MAX_TOKENS:-128}"

curl -sS "http://${HOST}:${PORT}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\
    \"model\": \"${MODEL}\",\
    \"messages\": [{\"role\": \"user\", \"content\": \"?????????????\"}],\
    \"max_tokens\": ${MAX_TOKENS},\
    \"stream\": false\
  }" | jq . || true
