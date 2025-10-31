#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-localhost}"
PORT="${PORT:-8002}"

curl -sS "http://${HOST}:${PORT}/v1/models" | jq . || curl -sS "http://${HOST}:${PORT}/v1/models"
