#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="$SCRIPT_DIR"
PYTHON="/Users/michaeldanko/.hermes/venvs/qwen-mlx311/bin/python"
HOST="127.0.0.1"
PORT="8080"
PID_FILE="$SCRIPT_DIR/.qwen3.5-server.pid"
LOG_FILE="$SCRIPT_DIR/qwen3.5-server.log"

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "Model directory not found: $MODEL_DIR" >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  existing_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${existing_pid:-}" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "qwen3.5 server is already running (PID $existing_pid)"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup "$PYTHON" -m mlx_lm.server \
  --model "$MODEL_DIR" \
  --host "$HOST" \
  --port "$PORT" \
  >"$LOG_FILE" 2>&1 &

server_pid="$!"
echo "$server_pid" > "$PID_FILE"

for _ in {1..30}; do
  if curl -sf "http://$HOST:$PORT/v1/models" >/dev/null 2>&1; then
    echo "Started qwen3.5 server on http://$HOST:$PORT (PID $server_pid)"
    exit 0
  fi

  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "qwen3.5 server exited early. See $LOG_FILE" >&2
    rm -f "$PID_FILE"
    exit 1
  fi

  sleep 1
done

echo "qwen3.5 server is still starting. Check $LOG_FILE" >&2
exit 0
