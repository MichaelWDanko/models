#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_FILE="$SCRIPT_DIR/gemma-4-e4b-it-Q4_K_M.gguf"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$(command -v llama-server || true)}"
HOST="127.0.0.1"
PORT="8081"
PID_FILE="$SCRIPT_DIR/.gemma-4-e4b-it.pid"
LOG_FILE="$SCRIPT_DIR/gemma-4-e4b-it.log"

if [[ -z "$LLAMA_SERVER_BIN" ]]; then
  echo "llama-server not found in PATH" >&2
  exit 1
fi

if [[ ! -x "$LLAMA_SERVER_BIN" ]]; then
  echo "llama-server not found or not executable: $LLAMA_SERVER_BIN" >&2
  exit 1
fi

if [[ ! -f "$MODEL_FILE" ]]; then
  echo "Model file not found: $MODEL_FILE" >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  existing_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${existing_pid:-}" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "gemma-4-e4b-it server is already running (PID $existing_pid)"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup "$LLAMA_SERVER_BIN" \
  -m "$MODEL_FILE" \
  --host "$HOST" \
  --port "$PORT" \
  >"$LOG_FILE" 2>&1 &

server_pid="$!"
echo "$server_pid" > "$PID_FILE"

for _ in {1..30}; do
  if curl -sf "http://$HOST:$PORT/v1/models" >/dev/null 2>&1; then
    echo "Started gemma-4-e4b-it on http://$HOST:$PORT (PID $server_pid)"
    exit 0
  fi

  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "gemma-4-e4b-it server exited early. See $LOG_FILE" >&2
    rm -f "$PID_FILE"
    exit 1
  fi

  sleep 1
done

echo "gemma-4-e4b-it server is still starting. Check $LOG_FILE" >&2
exit 0
