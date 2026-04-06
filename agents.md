# Models folder guide

`~/Models` is a git-backed project for local model storage, per-model server scripts, and lightweight documentation.

The goal is to make it easy to:
- back up the folder
- copy the structure to another computer
- keep the large model payloads out of git
- keep start and stop scripts consistent

## Canonical layout

- `~/Models/mlx/`
  - MLX family folders live here
  - Example: `~/Models/mlx/qwen3.5/Qwen3.5-0.8B/`
- `~/Models/gguf/`
  - GGUF family folders live here
  - Example: `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/`

## Per-model folder convention

Each specific model gets its own folder inside the family folder.

Examples:
- `~/Models/mlx/qwen3.5/Qwen3.5-0.8B/`
- `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/`
- `~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/`

Inside each model folder:
- `start.sh`
- `stop.sh`
- the model files themselves
- optional runtime state like logs or pid files, which should be gitignored

## Rules

1. Keep one canonical home for each model.
   - Do not duplicate the same model tree in multiple places.
   - If a model changes runtime or format, move the active copy instead of keeping both.

2. Keep the script names stable.
   - Every model folder should use the same filenames: `start.sh` and `stop.sh`.
   - That makes the layout predictable across computers.

3. Keep model payloads out of git.
   - Large weights, tokenizer files, cached downloads, logs, and pid files should be ignored.
   - The repo should mostly track structure, scripts, and documentation.

4. Use Hermes profile configs to point at the active server.
   - Keep the profile `base_url` aligned with the local OpenAI-compatible endpoint.
   - Keep the profile model name aligned with the active model.

5. Update this guide when the layout changes.
   - Add new model families here.
   - Add any new conventions or helper files here.

## Current active models

- Qwen 3.5 local MLX server
  - Model folder: `~/Models/mlx/qwen3.5/Qwen3.5-0.8B/`
  - Server port: `8080`
  - Scripts: `~/Models/mlx/qwen3.5/Qwen3.5-0.8B/start.sh`, `~/Models/mlx/qwen3.5/Qwen3.5-0.8B/stop.sh`

- Gemma 4 E4B GGUF server
  - Model folder: `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/`
  - Server port: `8081`
  - Scripts: `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/start.sh`, `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/stop.sh`

- Gemma 4 26B A4B GGUF server
  - Model folder: `~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/`
  - Server port: `8082`
  - Scripts: `~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/start.sh`, `~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/stop.sh`

## Git notes

- Root `.gitignore` should exclude model artifacts and runtime state.
- The repo should retain the folder structure, scripts, and documentation.
- If you add a new model folder, give it the same `start.sh` and `stop.sh` pair and then add the model artifacts to the ignored set.
