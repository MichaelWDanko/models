# Models

This repository holds the folder structure and helper scripts for local model servers.

When I say a model is “running,” I mean the local server process serving that model is running. The scripts in each model folder start and stop that server, usually exposing an OpenAI-compatible endpoint on localhost.

## Layout

- `mlx/` for MLX-served models
- `gguf/` for GGUF models used with `llama.cpp`
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
   - MLX for the Qwen 3.5 folder
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

### Gemma 4 E4B

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
