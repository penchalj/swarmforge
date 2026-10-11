# CI timings (measured)

| Run | Cache state | Build and test job | Notes |
|-----|-------------|--------------------|-------|
| 1 | cold | 15 min | LLVM download + protobuf compile |
| 2 | warm | 4 min  | restored repository + disk cache |

## Full lane

| Job | Cold (first PR run) | Warm (cache restored) | Notes |
|-----|---------------------|-----------------------|-------|
| Sanitizers (asan) | 13 min 39 s | __ | full rebuild with ASan, protobuf included |
| Sanitizers (ubsan) | 12 min 35 s | __ | full rebuild with UBSan |
| Build and test (arm64) | 9 min 14 s | __ | native arm64 runner |
| Edge smoke test (QEMU) | 24 s | __ | arm64 binary on emulated arm64 Ubuntu |
| Whole PR (parallel) | about 14 min | __ | limited by the slowest job |
