#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.gemma-4-e4b-it-4bit.pid"
MODEL_PATTERN="gemma-4-e4b-it-4bit"

stop_pid() {
  local pid="$1"
  if [[ -z "$pid" ]]; then
    return 0
  fi

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    for _ in {1..10}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 1
    done

    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
}

if [[ -f "$PID_FILE" ]]; then
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${pid:-}" ]]; then
    stop_pid "$pid"
  fi
  rm -f "$PID_FILE"
fi

pattern_pid="$(pgrep -f "mlx_lm.server.*$MODEL_PATTERN" | head -n 1 || true)"
if [[ -n "$pattern_pid" ]]; then
  stop_pid "$pattern_pid"
fi

echo "Stopped gemma-4-e4b-it-4bit (if it was running)"
