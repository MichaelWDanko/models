#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_port() {
  local label="$1"
  local port="$2"
  local pid_file="$3"

  printf '%-34s' "$label"

  if [[ -f "$pid_file" ]]; then
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "running (pid $pid, port $port)"
      return 0
    fi
  fi

  local port_pid
  port_pid="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -n 1 || true)"
  if [[ -n "$port_pid" ]]; then
    echo "running (pid $port_pid, port $port)"
  else
    echo "stopped (port $port)"
  fi
}

echo "Model server status"
echo
check_port "Qwen 3.5 0.8B" 8080 "$ROOT_DIR/mlx/qwen3.5/Qwen3.5-0.8B/.qwen3.5-server.pid"
check_port "Gemma 4 E4B" 8081 "$ROOT_DIR/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/.gemma-4-e4b-it.pid"
check_port "Gemma 4 26B A4B" 8082 "$ROOT_DIR/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/.gemma-4-26b-a4b.pid"
