# Model Optimization Plan

## Problem we are seeing

The Gemma 4 GGUF models are usable, but the first response after starting the server is much slower than expected on this machine.

Observed behavior for `gemma-4-e4b-it-Q4_K_M`:
- first request after restart: about 1 minute 10 seconds before the model starts responding
- second request: about 1 minute 18 seconds before anything appears, then output begins to stream faster

That means the main issue is not just generation speed. The delay is happening before the first token arrives, which usually points to one or more of these:
- large prompt/context processing
- conservative or missing `llama-server` tuning
- insufficient Metal/GPU offload
- memory pressure or swapping
- server startup overhead that is being counted in the request latency

## What we are optimizing for

We want the GGUF Gemma models to feel responsive enough for interactive use on a MacBook Pro M1 Pro with 32GB unified memory.

Success looks like:
- the first token appears much sooner
- repeated requests stay consistently faster
- the 4B model feels practical for day-to-day use
- the 26B model stays available as a heavier option, but we understand it may remain slower

## Current repo approach

The repo keeps each model in its own folder with stable `start.sh` and `stop.sh` scripts.

For optimization, we should keep the changes localized to the model folder instead of spreading tuning across the repo.

## Optimization approach

1. Measure before changing anything
   - note startup time
   - note time to first token
   - note total response time
   - compare short prompts vs long prompts

2. Tune the 4B Gemma server first
   - this is the model most likely to become interactive enough for everyday use
   - change only the 4B start script first
   - keep the 26B model untouched until we know what helps

3. Prefer explicit llama.cpp flags
   - make context size explicit
   - make GPU/Metal offload explicit where appropriate
   - keep the launch command easy to inspect
   - avoid guessing; tune one setting at a time

4. Reduce avoidable latency
   - keep context size smaller unless a larger context is actually needed
   - avoid sending huge prompts unless necessary
   - keep the server warm instead of restarting often

5. Verify with repeatable tests
   - test the same prompt before and after each change
   - compare first request vs second request
   - record whether output starts streaming earlier

## Likely next changes

When we resume, the first script to patch should probably be:
- `~/Models/gguf/gemma4/gemma-4-e4b-it-Q4_K_M/start.sh`

Potential tuning areas to inspect:
- context size
- batch size
- number of GPU layers / Metal offload behavior
- KV cache settings
- any server defaults that make sense for a 4B model on Apple Silicon

## Notes

- The goal is to improve first-token latency without breaking model startup.
- We should keep changes conservative and measurable.
- If the 4B model becomes fast enough, we can compare the same tuning against the 26B model later.
