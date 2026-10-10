# ADR 0003: CI on GitHub Actions with Bazel cache and affected tests

## Context
Every change must be linted, built and tested automatically. A cold build
compiles protobuf (about 11 min locally), so CI needs caching to keep
feedback fast.

## Decisions
1. **Same container locally and in CI.** CI runs ./scripts/dev.sh with the
   pinned image; there is no separate CI setup to drift.
2. **Two parallel jobs.** Lint finishes in about a minute and fails fast;
   build and test runs at the same time.
3. **Cache: GitHub Actions cache for Bazel's repository cache and disk cache.**
   Free and needs no server. Alternatives: self-hosted bazel-remote or
   BuildBuddy (shared, finer-grained), planned once the build outgrows the
   10 GB Actions cache limit.
4. **Only main writes the cache; pull requests only read it.** An untrusted
   PR cannot poison results that later builds reuse.
5. **Affected tests on PRs** via `bazel query rdeps(...)`. Changes to Bazel
   settings, the image, scripts or CI files run everything; docs-only changes
   run nothing. Main always runs the full suite.
6. **Lint tools pinned in the image** (clang-format 18, ruff, shellcheck,
   buildifier): identical results on every machine.

## Consequences
+ Fast feedback; cold vs warm timings measured in docs/performance/ci-timings.md
+ PRs cannot corrupt the shared cache
- The affected-test script is a heuristic; main's full run is the safety net
- The Actions cache is per repository and limited to 10 GB
