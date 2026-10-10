# CI timings (measured)

| Run | Cache state | Build and test job | Notes |
|-----|-------------|--------------------|-------|
| 1 | cold | 15 min | LLVM download + protobuf compile |
| 2 | warm | 4 min  | restored repository + disk cache |
