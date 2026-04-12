# Models

This repository holds the folder structure and helper scripts for local model servers.

When I say a model is “running,” I mean the local server process serving that model is running. The scripts in each model folder start and stop that server, usually exposing an OpenAI-compatible endpoint on localhost.

## Layout

- `mlx/` for MLX-served models
- `gguf/` for GGUF models used with `llama.cpp`
- Gemma 4 can be tested in both families: MLX for the experimental E4B-it and 26B-A4B 4bit builds, GGUF for the llama.cpp builds
- Qwen 3.5 currently has MLX folders for both `0.8B` and `9B`
- each model lives in its own subfolder
- each model folder uses the same script names:
  - `start.sh`
  - `stop.sh`
- the repo root has helper scripts:
  - `status_check_all_models.sh`
  - `stop_all_models.sh`

## Getting this onto another computer

1. Clone the repo.
2. Install the runtime you need:
   - `mlx-lm` for the Qwen 3.5 folders and the Gemma 4 MLX folders, ideally in the Hermes venv or another Python that can import `mlx_lm`
   - `llama.cpp` for the Gemma 4 GGUF folders
3. Download the model files into the matching model folder.
4. Run that folder’s `start.sh`.

## Download commands

### Qwen 3.5 0.8B

Download into:
`~/Models/mlx/qwen3.5/Qwen3.5-0.8B/`

Example:
```bash
hf download Qwen/Qwen3.5-0.8B --local-dir ~/Models/mlx/qwen3.5/Qwen3.5-0.8B
```

### Qwen 3.5 9B MLX 4bit

Download into:
`~/Models/mlx/qwen3.5/Qwen3.5-9B/`

Example:
```bash
python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="mlx-community/Qwen3.5-9B-MLX-4bit",
    local_dir="/Users/michaeldanko/Models/mlx/qwen3.5/Qwen3.5-9B",
    local_dir_use_symlinks=False,
)
PY
```

Hermes should point its model name at the exact local path returned by the server, or a stable served id if the MLX server exposes one.

### Gemma 4 E4B MLX

Download into:
`~/Models/mlx/gemma4/gemma-4-e4b-it-4bit/`

Hermes should point its model name at the exact local path returned by the server, not the short name. For this model, that is:
`/Users/michaeldanko/Models/mlx/gemma4/gemma-4-e4b-it-4bit`

Example:
```bash
python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="mlx-community/gemma-4-e4b-it-4bit",
    local_dir="/Users/michaeldanko/Models/mlx/gemma4/gemma-4-e4b-it-4bit",
    local_dir_use_symlinks=False,
)
PY
```

### Gemma 4 26B-A4B MLX

Download into:
`~/Models/mlx/gemma4/gemma-4-26b-a4b-it-4bit/`

Example:
```bash
python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="mlx-community/gemma-4-26b-a4b-it-4bit",
    local_dir="/Users/michaeldanko/Models/mlx/gemma4/gemma-4-26b-a4b-it-4bit",
    local_dir_use_symlinks=False,
)
PY
```

### Gemma 4 E4B GGUF

Download into:
`~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/`

Example:
```bash
hf download ggml-org/gemma-4-E4B-it-GGUF gemma-4-e4b-it-Q4_K_M.gguf \
  --local-dir ~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M
```

### Gemma 4 26B A4B

Download into:
`~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/`

Example:
```bash
hf download ggml-org/gemma-4-26B-A4B-it-GGUF gemma-4-26B-A4B-it-Q4_K_M.gguf \
  --local-dir ~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M
```

## Notes

- The repo is intended to be safe to publish publicly. Large model files, caches, logs, and pid files are ignored by git.
- The scripts are the portable part. The model payloads are downloaded separately on each machine.
- If a model changes, update the matching folder only and keep the script names the same.
- For llama.cpp models, the start script can enforce a runtime context directly with `--ctx-size`.
- For MLX models, the current server CLI does not expose a matching context override flag, so the script records the intended model context and Hermes profiles should use the same `context_length`.
