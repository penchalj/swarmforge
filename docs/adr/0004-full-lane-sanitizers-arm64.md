# ADR 0004: Full lane with sanitizers, native arm64 and QEMU edge smoke test

## Context
The software runs on x86 servers and ARM edge devices. Memory errors and
undefined behaviour in C++ are dangerous in autonomous systems and are often
invisible in normal tests.

## Decisions
1. **ASan and UBSan on every PR and on main**, as parallel jobs. All code,
   including third-party libraries, is instrumented; any finding fails CI.
2. **Canary tests prove the sanitizers work.** A deliberately broken test
   must fail under each sanitizer; if it ever passes, CI fails.
3. **arm64 is built and tested natively** on GitHub's arm64 runners, using the
   same Dockerfile built as a multi-arch image.
4. **QEMU edge smoke test:** the arm64 binary is run on an emulated arm64
   Ubuntu on an x86 runner, simulating deployment to an edge device.

## Alternatives considered
- **Cross-compiling with the LLVM toolchain:** needs a separate arm64 sysroot
  (glibc and libstdc++ for arm64) wired into toolchains_llvm. Postponed to
  Phase 3, where the Yocto SDK provides a proper arm64 sysroot.
- **Building under QEMU:** emulated compilation of protobuf would take hours.

## Consequences
+ Real arm64 build and test results; memory and UB bugs caught before merge
+ Measured locally: ASan full build about 5.5 min; both canaries fail as expected
+ Each sanitizer lane has its own cache (more Actions cache usage, 10 GB limit)
- ASan stack traces show addresses only until llvm-symbolizer is wired in
- Native arm64 runners depend on GitHub offering them for public repositories
