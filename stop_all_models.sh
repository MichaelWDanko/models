#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scripts=(
  "$ROOT_DIR/mlx/qwen3.5/Qwen3.5-0.8B/stop.sh"
  "$ROOT_DIR/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/stop.sh"
  "$ROOT_DIR/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/stop.sh"
)

for script in "${scripts[@]}"; do
  if [[ -x "$script" ]]; then
    "$script"
  else
    echo "Missing stop script: $script" >&2
  fi
done
