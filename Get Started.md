# Get Started

This folder contains the local model files I use with Hermes.

## Model profiles and ports

I keep different runtimes in different subfolders under `~/Models`.

- `~/Models/mlx/qwen3.5/` -> Qwen 3.5 0.8B for MLX on `127.0.0.1:8080`
  - the old path `~/Models/qwen3.5/Qwen3.5-0.8B` is now a symlink for compatibility
- `~/Models/gguf/gemma4/` -> Gemma 4 GGUF files for `llama.cpp`
  - `gemma-4-e4b-it-Q4_K_M.gguf` on `127.0.0.1:8081`
  - `gemma-4-26B-A4B-it-Q4_K_M.gguf` on `127.0.0.1:8082`

Each profile only works if its matching server process is running.

## Before you start

Make sure both runtimes are available:

```bash
command -v llama-server
~/.hermes/venvs/qwen-mlx311/bin/python -c 'import mlx_lm; print(mlx_lm.__version__)'
```

If you ever need to confirm a server is up, check the port with `lsof`.

Copy and paste these commands:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
lsof -nP -iTCP:8081 -sTCP:LISTEN
lsof -nP -iTCP:8082 -sTCP:LISTEN
```

## Switch to llama.cpp / GGUF

Gemma 4 does not work with the MLX runtime I have here, so the reliable path is GGUF plus `llama.cpp`.

### 1. Install llama.cpp

```bash
brew install llama.cpp
```

### 2. Download the GGUF files for Gemma 4

```bash
mkdir -p ~/Models/gguf/gemma4

hf download ggml-org/gemma-4-E4B-it-GGUF gemma-4-e4b-it-Q4_K_M.gguf \
  --local-dir ~/Models/gguf/gemma4

hf download ggml-org/gemma-4-26B-A4B-it-GGUF gemma-4-26B-A4B-it-Q4_K_M.gguf \
  --local-dir ~/Models/gguf/gemma4
```

### 3. Start the servers

Open one terminal per model you want to run.

### Qwen 0.8B, keep using MLX

```bash
~/.hermes/venvs/qwen-mlx311/bin/python -m mlx_lm server \
  --model ~/Models/mlx/qwen3.5/Qwen3.5-0.8B \
  --host 127.0.0.1 \
  --port 8080
```

### Gemma 4 E4B

```bash
llama-server \
  -m ~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M.gguf \
  --host 127.0.0.1 \
  --port 8081
```

### Gemma 4 26B A4B

```bash
llama-server \
  -m ~/Models/gguf/gemma4/gemma-4-26B-A4B-it-Q4_K_M.gguf \
  --host 127.0.0.1 \
  --port 8082
```

## Important note about Gemma 4

The GGUF files are the right model format for llama.cpp. The old MLX model files can stay on disk, but these Hermes profiles should point at the llama.cpp server instead.

## How to tell if a server is running

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
lsof -nP -iTCP:8081 -sTCP:LISTEN
lsof -nP -iTCP:8082 -sTCP:LISTEN
```

If a port shows a listening process, that model server is running.

## Stop a model server

### Stop by port

Find the PID first:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Then stop it:

```bash
kill <PID>
```

Repeat for 8081 or 8082 as needed.

### Stop by model name

If you want to stop a specific server without looking up the PID:

```bash
pkill -f 'mlx_lm.server.*Qwen3.5-0.8B'
pkill -f 'llama-server.*gemma-4-e4b-it-Q4_K_M.gguf'
pkill -f 'llama-server.*gemma-4-26B-A4B-it-Q4_K_M.gguf'
```

## Quick usage flow

1. Start the server for the model you want.
2. Use the matching Hermes profile.
3. Stop the server when you are done.

## Memory note

Do not run both Gemma servers at the same time unless you know you have enough headroom. On a 32 GB Mac, one local model at a time is the safer default.
