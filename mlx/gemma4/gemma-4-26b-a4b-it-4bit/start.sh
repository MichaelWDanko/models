#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="$SCRIPT_DIR"
MODEL_REPO="mlx-community/gemma-4-26b-a4b-it-4bit"
HOST="127.0.0.1"
PORT="8084"
PID_FILE="$SCRIPT_DIR/.gemma-4-26b-a4b-4bit.pid"
LOG_FILE="$SCRIPT_DIR/gemma-4-26b-a4b-4bit.log"
EXPECTED_CONTEXT_LENGTH="${EXPECTED_CONTEXT_LENGTH:-262144}"

PYTHON_CANDIDATES=(
  "${PYTHON_BIN:-}"
  "${MLX_PYTHON_BIN:-}"
  "$HOME/.hermes/hermes-agent/venv/bin/python"
  "$(command -v python3 2>/dev/null || true)"
)

PYTHON_BIN=""
for candidate in "${PYTHON_CANDIDATES[@]}"; do
  [[ -n "$candidate" ]] || continue

  candidate_path="$candidate"
  if [[ "$candidate" != */* ]]; then
    candidate_path="$(command -v "$candidate" 2>/dev/null || true)"
  fi

  if [[ -n "$candidate_path" && -x "$candidate_path" ]]; then
    if "$candidate_path" -c 'import mlx_lm' >/dev/null 2>&1; then
      PYTHON_BIN="$candidate_path"
      break
    fi
  fi
done

if [[ -z "$PYTHON_BIN" ]]; then
  echo "No Python interpreter with mlx_lm installed was found." >&2
  echo "Set PYTHON_BIN or MLX_PYTHON_BIN, or install mlx-lm into one of these interpreters:" >&2
  printf '  - %s\n' "$HOME/.hermes/hermes-agent/venv/bin/python" >&2
  printf '  - %s\n' "$(command -v python3 2>/dev/null || true)" >&2
  exit 1
fi

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "Model directory not found: $MODEL_DIR" >&2
  exit 1
fi

if [[ ! -f "$MODEL_DIR/config.json" ]]; then
  echo "Model files are missing from $MODEL_DIR." >&2
  echo "Download the MLX model snapshot first. See $MODEL_DIR/README.md for the exact huggingface_hub snapshot_download command." >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  existing_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${existing_pid:-}" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "gemma-4-26b-a4b-4bit server is already running (PID $existing_pid)"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

{
  echo "Starting gemma-4-26b-a4b-4bit MLX server with:"
  echo "  model repo: $MODEL_REPO"
  echo "  model dir:  $MODEL_DIR"
  echo "  python:     $PYTHON_BIN"
  echo "  host:       $HOST"
  echo "  port:       $PORT"
  echo "  context:    $EXPECTED_CONTEXT_LENGTH (model config; MLX server does not expose a context override flag)"
  echo "  log:        $LOG_FILE"
} | tee -a "$LOG_FILE"

nohup "$PYTHON_BIN" -m mlx_lm.server \
  --model "$MODEL_DIR" \
  --host "$HOST" \
  --port "$PORT" \
  >>"$LOG_FILE" 2>&1 &

server_pid="$!"
echo "$server_pid" > "$PID_FILE"

for _ in {1..30}; do
  if curl -sf "http://$HOST:$PORT/v1/models" >/dev/null 2>&1; then
    echo "Started gemma-4-26b-a4b-4bit on http://$HOST:$PORT (PID $server_pid)"
    exit 0
  fi

  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "gemma-4-26b-a4b-4bit server exited early. See $LOG_FILE" >&2
    rm -f "$PID_FILE"
    exit 1
  fi

  sleep 1
done

echo "gemma-4-26b-a4b-4bit server is still starting. Check $LOG_FILE" >&2
exit 0
