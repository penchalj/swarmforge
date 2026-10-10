# ADR 0002: Protobuf contracts, file-based exchange first, gRPC later

## Context
detector (Python) and fusion-node (C++) must agree on one data format.
gRPC is the target transport, but it adds a very large dependency tree
(gRPC, BoringSSL, Abseil): much longer cold builds and several GB of disk.

## Options
1. JSON files: simple, but no schema; C++ and Python can drift apart
2. Protobuf messages exchanged via files
3. Protobuf + gRPC streaming from day one

## Decision
Option 2 now. One .proto file generates both C++ and Python code through
Bazel, so the contract is shared and type-checked. Move to gRPC (option 3)
once the remote cache exists, so its build cost is paid once, not per build.

## Consequences
+ Shared schema, fast builds, easy deterministic integration tests
- Not a live service yet; no streaming or backpressure
- The .proto contract stays the same when gRPC is added
