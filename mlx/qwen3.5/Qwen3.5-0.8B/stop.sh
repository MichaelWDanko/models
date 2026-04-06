#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="8080"
PID_FILE="$SCRIPT_DIR/.qwen3.5-server.pid"
MODEL_PATTERN="Qwen3.5-0.8B"

stop_pid() {
  local pid="$1"
  if [[ -z "$pid" ]]; then
    return 0
  fi

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    for _ in {1..20}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        return 0
      fi
      sleep 1
    done
    kill -9 "$pid" 2>/dev/null || true
  fi
}

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  stop_pid "$pid"
  rm -f "$PID_FILE"
  echo "Stopped qwen3.5 server (PID ${pid:-unknown})"
  exit 0
fi

port_pid="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -n 1 || true)"
if [[ -n "$port_pid" ]]; then
  stop_pid "$port_pid"
  echo "Stopped qwen3.5 server listening on port $PORT (PID $port_pid)"
  exit 0
fi

pattern_pid="$(pgrep -f "mlx_lm.server.*$MODEL_PATTERN" | head -n 1 || true)"
if [[ -n "$pattern_pid" ]]; then
  stop_pid "$pattern_pid"
  echo "Stopped qwen3.5 server matching $MODEL_PATTERN (PID $pattern_pid)"
  exit 0
fi

echo "No running qwen3.5 server found"
