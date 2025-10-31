#!/usr/bin/env bash
set -euo pipefail

# Convenience launcher for the example model in your message
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="QuantTrio/Qwen3-VL-235B-A22B-Thinking-AWQ" \
  "${SCRIPT_DIR}/switch_model.sh"
