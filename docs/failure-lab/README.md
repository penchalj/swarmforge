# Failure Lab: real failures from building SwarmForge

| # | Symptom | Root cause | Fix | Prevention |
|---|---------|-----------|-----|-----------|
| 1 | "This rule has been removed from Bazel" | Unpinned Bazel; Bazelisk fetched 9.3.0, which removed native cc rules used by toolchains_llvm 1.4.0 | Pin Bazel 8 | Exact version in .bazelversion; CI check |
| 2 | "No space left on device" during toolchain fetch | LLVM toolchain needs about 6 GB extracted | Freed disk | Disk check in forge doctor; CI cache |
| 3 | ld.lld: libxml2.so.2 not found | Prebuilt LLVM depends on a host library; Ubuntu 26.04 ships only libxml2.so.16 | Build in pinned Ubuntu 24.04 image | One image for dev and CI |
| 4 | 'features.h' file not found | Toolchain brings the compiler, not the C library headers (sysroot) | Add libc6-dev and libgcc-13-dev to image | Pinned image; later a downloaded sysroot |
| 5 | protobuf port.cc: "variable does not have a constant initializer" | Protobuf 30+ needs constexpr std::string; libc++ 17 (LLVM 17) allocates during constant evaluation | Pin protobuf 29.3 | Upgrade toolchain to LLVM 19+ before moving to protobuf 30+; record version compatibility in an ADR |
| 6 | Dependabot proposed Ubuntu 24.04 -> 26.04 for all images | Automatic OS major upgrades would break the pinned LLVM 17 toolchain (libxml2.so.2, see #3) | Closed the PR; Dependabot limited to digest updates for OS and Python | OS upgrades are planned together with a toolchain upgrade |
| 7 | format.sh failed: "Permission denied" on dist/app/proto/detection_pb2.py | Generated, read-only release files in dist/ were picked up by the formatters | Excluded dist/ in lint.sh and format.sh | Generated output is never linted, like bazel-* |
| 8 | Rapid merges cancelled waiting main runs despite cancel-in-progress: false | GitHub keeps only one waiting run per concurrency group; newer runs replace waiting ones | Per-commit concurrency group on main | Every main commit gets its own complete run |
