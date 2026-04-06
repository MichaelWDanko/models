# Agents guide for this repo

This repository is a git-backed home for local model servers, helper scripts, and a small amount of documentation. Keep it safe to publish publicly.

## Core patterns

- One model per folder.
  - Each model lives in its own subfolder inside the family folder.
  - Example: `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/`
- Stable script names.
  - Every model folder uses `start.sh` and `stop.sh`.
- Root status and bulk stop scripts.
  - `~/Models/check_all_models_status.sh` reports the status of all known models.
  - `~/Models/stop_all_models.sh` stops all known models by calling the existing per-model stop scripts.
  - Update these scripts whenever a new model is added.
- Model payloads stay out of git.
  - Large weights, caches, pid files, and logs are ignored.
  - Git should track structure, scripts, and docs only.
- Running a model means running its local server.
  - The scripts start and stop the server process for that model.
- Use the matching Hermes profile.
  - Keep the profile `base_url` pointed at the right localhost port.
  - Keep the profile model name aligned with the serving model.

## Current layout

- `mlx/` for MLX-served models
- `gguf/` for GGUF models served with `llama.cpp`

Current examples:
- `~/Models/mlx/qwen3.5/Qwen3.5-0.8B/`
- `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/`
- `~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M/`

## Repo files that should remain tracked

- `README.md`
- `agents.md`
- `check_all_models_status.sh`
- `stop_all_models.sh`
- `mlx/**/start.sh`
- `mlx/**/stop.sh`
- `gguf/**/start.sh`
- `gguf/**/stop.sh`

## Files that should stay untracked

- model weights and tokenizer files
- `.cache/`
- `*.log`
- `*.pid`
- generated metadata like `.gitattributes` inside model downloads

## Commit pattern

Use conventional commits for this repo.

Format:
`type(scope): short summary`

Examples:
- `docs(models): add repo guide`
- `chore(models): remove unused model files`
- `feat(models): add start and stop scripts`

Guidelines:
- keep the subject short and direct
- use lowercase types
- prefer `docs`, `chore`, `feat`, `fix`, `refactor`, or `test`
- if the change only updates docs or structure, use `docs` or `chore`

## When updating the repo

1. Keep the repo public-safe.
2. Keep model-specific changes inside that model’s folder.
3. Update the README and this guide if the layout changes.
4. Commit the change with a conventional commit message.
