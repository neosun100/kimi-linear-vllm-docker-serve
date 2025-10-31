#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-localhost}"
PORT="${PORT:-8002}"
MODEL="${MODEL:-cyankiwi/Kimi-Linear-48B-A3B-Instruct-AWQ-4bit}"

curl -sN "http://${HOST}:${PORT}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{\
    \"model\": \"${MODEL}\",\
    \"messages\": [{\"role\": \"user\", \"content\": \"?????????\"}],\
    \"stream\": true\
  }" | sed -u 's/\\n/\n/g'
