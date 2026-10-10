# ADR 0001: Bazel 8 + hermetic LLVM + pinned build image

## Context
C++/Python monorepo targeting x86_64 and aarch64. Builds must be fast,
cacheable and identical on every laptop and CI runner.

## Options
1. CMake + system compiler
2. Bazel + system compiler
3. Bazel + pinned LLVM toolchain + pinned container image (sysroot)

## Decision
Option 3. Bazel 8.8.1 (pinned in .bazelversion), LLVM 17.0.6 via
toolchains_llvm, built inside an Ubuntu 24.04 image with no system compiler.

## Consequences
+ Same compiler and C library everywhere; host OS no longer matters
+ Enables remote caching, affected-target builds, cross-compilation
- About 6 GB toolchain per machine; steeper learning curve
- Next step: downloaded sysroot for full hermeticity (needed for aarch64)
