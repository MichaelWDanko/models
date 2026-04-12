#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_listener_endpoint() {
  local port="$1"
  local pid_filter="${2:-}"
  local endpoint

  if [[ -n "$pid_filter" ]]; then
    endpoint="$(lsof -nP -a -p "$pid_filter" -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $9; exit}' || true)"
  else
    endpoint="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $9; exit}' || true)"
  fi

  if [[ -n "$endpoint" ]]; then
    printf '%s' "$endpoint"
  else
    printf '*:%s' "$port"
  fi
}

check_port() {
  local label="$1"
  local port="$2"
  local pid_file="$3"
  local pid
  local endpoint
  local port_pid

  printf '%-34s' "$label"

  if [[ -f "$pid_file" ]]; then
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      endpoint="$(get_listener_endpoint "$port" "$pid")"
      echo "running (pid $pid, endpoint $endpoint)"
      return 0
    fi
  fi

  port_pid="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -n 1 || true)"
  if [[ -n "$port_pid" ]]; then
    endpoint="$(get_listener_endpoint "$port" "$port_pid")"
    echo "running (pid $port_pid, endpoint $endpoint)"
  else
    echo "stopped (endpoint *:$port)"
  fi
}

echo "Model server status"
echo
check_port "Qwen 3.5 0.8B" 8080 "$ROOT_DIR/mlx/qwen3.5/Qwen3.5-0.8B/.qwen3.5-server.pid"
check_port "Qwen 3.5 9B" 8085 "$ROOT_DIR/mlx/qwen3.5/Qwen3.5-9B/.qwen3.5-9b-server.pid"
check_port "Gemma 4 E4B MLX" 8083 "$ROOT_DIR/mlx/gemma4/gemma-4-e4b-it-4bit/.gemma-4-e4b-it-4bit.pid"
check_port "Gemma 4 26B MLX" 8084 "$ROOT_DIR/mlx/gemma4/gemma-4-26b-a4b-it-4bit/.gemma-4-26b-a4b-4bit.pid"
check_port "Gemma 4 E4B GGUF" 8081 "$ROOT_DIR/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/.gemma-4-e4b-it.pid"
check_port "Gemma 4 26B A4B" 8082 "$ROOT_DIR/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/.gemma-4-26b-a4b.pid"
