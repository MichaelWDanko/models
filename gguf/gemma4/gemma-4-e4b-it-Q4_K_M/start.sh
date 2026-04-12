#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_FILE="$SCRIPT_DIR/gemma-4-e4b-it-Q4_K_M.gguf"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$(command -v llama-server || true)}"
HOST="127.0.0.1"
PORT="8081"
PID_FILE="$SCRIPT_DIR/.gemma-4-e4b-it.pid"
LOG_FILE="$SCRIPT_DIR/gemma-4-e4b-it.log"

# Conservative llama.cpp defaults for interactive use on Apple Silicon.
# The linked optimization note pointed at reducing parallel server slots to
# shrink Gemma 4's cache footprint, so we start with a single slot and keep
# the other knobs explicit and easy to tune.
LLAMA_PARALLEL="${LLAMA_PARALLEL:-1}"
LLAMA_CTX_SIZE="${LLAMA_CTX_SIZE:-131072}"
LLAMA_BATCH_SIZE="${LLAMA_BATCH_SIZE:-1024}"
LLAMA_UBATCH_SIZE="${LLAMA_UBATCH_SIZE:-256}"
LLAMA_GPU_LAYERS="${LLAMA_GPU_LAYERS:-all}"
LLAMA_FLASH_ATTN="${LLAMA_FLASH_ATTN:-auto}"
LLAMA_REASONING="${LLAMA_REASONING:-off}"
LLAMA_PERF="${LLAMA_PERF:-on}"
LLAMA_METRICS="${LLAMA_METRICS:-on}"
LLAMA_LOG_TIMESTAMPS="${LLAMA_LOG_TIMESTAMPS:-on}"
LLAMA_LOG_PREFIX="${LLAMA_LOG_PREFIX:-on}"

LLAMA_EXTRA_FLAGS=()
if [[ "$LLAMA_PERF" == "on" ]]; then
  LLAMA_EXTRA_FLAGS+=(--perf)
fi
if [[ "$LLAMA_METRICS" == "on" ]]; then
  LLAMA_EXTRA_FLAGS+=(--metrics)
fi
if [[ "$LLAMA_LOG_TIMESTAMPS" == "on" ]]; then
  LLAMA_EXTRA_FLAGS+=(--log-timestamps)
fi
if [[ "$LLAMA_LOG_PREFIX" == "on" ]]; then
  LLAMA_EXTRA_FLAGS+=(--log-prefix)
fi

log_config() {
  {
    echo "Starting gemma-4-e4b-it with:"
    echo "  model: $MODEL_FILE"
    echo "  server: $LLAMA_SERVER_BIN"
    echo "  host: $HOST"
    echo "  port: $PORT"
    echo "  parallel: $LLAMA_PARALLEL"
    echo "  ctx-size: $LLAMA_CTX_SIZE"
    echo "  batch-size: $LLAMA_BATCH_SIZE"
    echo "  ubatch-size: $LLAMA_UBATCH_SIZE"
    echo "  gpu-layers: $LLAMA_GPU_LAYERS"
    echo "  flash-attn: $LLAMA_FLASH_ATTN"
    echo "  reasoning: $LLAMA_REASONING"
    echo "  perf: $LLAMA_PERF"
    echo "  metrics: $LLAMA_METRICS"
    echo "  log-timestamps: $LLAMA_LOG_TIMESTAMPS"
    echo "  log-prefix: $LLAMA_LOG_PREFIX"
    echo "  log: $LOG_FILE"
  } | tee -a "$LOG_FILE"
}

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

log_config

nohup "$LLAMA_SERVER_BIN" \
  -m "$MODEL_FILE" \
  --host "$HOST" \
  --port "$PORT" \
  --parallel "$LLAMA_PARALLEL" \
  --ctx-size "$LLAMA_CTX_SIZE" \
  --batch-size "$LLAMA_BATCH_SIZE" \
  --ubatch-size "$LLAMA_UBATCH_SIZE" \
  --gpu-layers "$LLAMA_GPU_LAYERS" \
  --flash-attn "$LLAMA_FLASH_ATTN" \
  --reasoning "$LLAMA_REASONING" \
  "${LLAMA_EXTRA_FLAGS[@]}" \
  --cont-batching \
  >>"$LOG_FILE" 2>&1 &

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
