# Model Optimization Plan

## Problem we are seeing

The Gemma 4 GGUF models are usable, but direct chat through Hermes feels much slower than direct server use.

Observed behavior so far:
- `gemma-4-26B-A4B-it-Q4_K_M` direct in the web UI feels strong
- a 1,000-word story request returned:
  - 2,136 tokens
  - 1m 13s total
  - 29.04 t/s
- a simple Hermes chat prompt like `Hi, how are you?` can feel much slower and may show much larger context growth

That points to a wrapper-versus-server question, not just a raw model speed question.

The main possibilities are:
- Hermes is sending a much larger hidden prompt than the web UI
- Hermes compression or memory steps are adding latency
- the server is being used differently in the two paths
- context size or batching is hurting prompt prefill in one path but not the other
- the web UI is a cleaner baseline than the Hermes chat loop

## What we are optimizing for

We want the GGUF Gemma models to feel responsive enough for interactive use on a MacBook Pro M1 Pro with 32GB unified memory.

Success looks like:
- the first token appears much sooner
- repeated requests stay consistently faster
- we can explain the latency gap between Hermes and direct server use
- the 4B model feels practical for day-to-day use
- the 26B model stays available as a heavier option, but we understand it may remain slower

## A/B testing goal

We want a clean comparison between:
- A: direct model-server usage
- B: Hermes chat through the same running model server

The current known-good server for comparison is:
- `Gemma 4 26B - running (pid 36037, port 8082)`

Use that running server as the baseline whenever possible so we are comparing the wrapper path instead of changing the model runtime at the same time.

## A/B test rules

1. Keep the server constant
   - use the already running 26B server on port 8082
   - do not restart or retune it during the baseline test unless it crashes

2. Keep prompts identical
   - use the same exact text in both paths
   - start with a tiny prompt and a medium prompt

3. Record the same metrics each time
   - time to first token
   - total response time
   - tokens generated
   - tokens per second
   - approximate input/context size if available

4. Change only one variable at a time
   - first compare UI path, not server flags
   - later compare server flags only after the baseline is established

## Baseline prompts

Use these prompts first:
- `Hi, how are you?`
- `Reply with exactly one word: banana`
- `Write a 300-word story about a robot learning to garden`

These give us three useful views:
- tiny chat prompt
- tiny controlled output
- medium generation task

## Baseline comparison matrix

| Test | Path | Server | Prompt | What to capture |
| --- | --- | --- | --- | --- |
| A1 | Web UI direct | 26B server on 8082 | `Hi, how are you?` | first token time, total time, token count, t/s |
| A2 | Hermes chat | same 26B server on 8082 | `Hi, how are you?` | same metrics plus any visible context growth |
| B1 | Web UI direct | 26B server on 8082 | `Reply with exactly one word: banana` | same metrics |
| B2 | Hermes chat | same 26B server on 8082 | `Reply with exactly one word: banana` | same metrics |
| C1 | Web UI direct | 26B server on 8082 | 300-word story prompt | same metrics |
| C2 | Hermes chat | same 26B server on 8082 | 300-word story prompt | same metrics |

## How to interpret results

- If direct web UI is consistently fast but Hermes is slow, Hermes is the source of the overhead.
- If both paths are slow on the same prompt, the server flags need more tuning.
- If Hermes is only slow on tiny prompts, the wrapper likely has a large fixed overhead before generation starts.
- If Hermes is slow mainly on repeated turns, context accumulation or compression is the likely culprit.

## Current repo approach

The repo keeps each model in its own folder with stable `start.sh` and `stop.sh` scripts.

For optimization, keep the changes localized to the model folder instead of spreading tuning across the repo.

## Optimization approach

1. Measure before changing anything
   - note startup time
   - note time to first token
   - note total response time
   - compare short prompts vs long prompts

2. Compare Hermes versus direct server usage first
   - use the already running 26B server as the baseline
   - do not tune server flags until we know where the slowdown comes from

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

Potential tuning areas to inspect after the A/B baseline is established:
- context size
- batch size
- number of GPU layers / Metal offload behavior
- KV cache settings
- any server defaults that make sense for a 4B model on Apple Silicon

## Findings log

### 2026-04-07
- Direct web UI against `gemma-4-26B-A4B-it-Q4_K_M` is performing well.
- Example story prompt result: 2,136 tokens in 1m 13s at 29.04 t/s.
- This suggests the raw server is probably healthy enough for interactive use.
- The next test should compare direct UI against Hermes with identical prompts before changing more server flags.
- MLX experiment folders were added for Gemma 4 E4B-it 4bit and 26B-A4B 4bit so we can re-test MLX now that `mlx_lm` has Gemma 4 support again.
- New finding on 2026-04-08: direct curl to the 4B MLX server answered `Hi how are you?` in about 1.6s, while `hermes chat -q` on the same model took about 53s.
- Server logs showed the Hermes request carried a much larger prompt, around 17,753 tokens, so the latency gap is coming from Hermes prompt construction and context size, not the MLX model itself.
- The Hermes profile banner also showed 73 tools, 77 skills, and 2 MCP servers enabled, which likely contributes to the large prompt and slow prefill.
- New finding on the 26B MLX model: `Hi, how are you?` completed in about 1m 33s with 17,757 input tokens and 174 output tokens, so the slowdown is still prompt prefill heavy rather than a server startup issue.
- The 26B model was serving correctly; the long latency matches a large hidden session prompt, not a missing file or broken server.

## Notes

- The goal is to improve first-token latency without breaking model startup.
- We should keep changes conservative and measurable.
- The current default flags in the 4B start script are:
  - `--parallel 1`
  - `--ctx-size 32768`
  - `--batch-size 1024`
  - `--ubatch-size 256`
  - `--gpu-layers all`
  - `--flash-attn auto`
  - `--reasoning off`
- If the 4B model becomes fast enough, we can compare the same tuning against the 26B model later.

## Bookmarks

- https://x.com/zaph0id/status/2040650225703080143?s=12
  - Worth reviewing for Gemma 4 optimization ideas before patching `start.sh`.
