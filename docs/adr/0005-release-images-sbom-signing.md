# ADR 0005: Runtime images, SBOM, vulnerability gate and keyless signing

## Context
fusion-node and detector must ship as container images for amd64 and arm64.
Consumers (and auditors) need to know what is inside an image and verify that
it was built by this repository's CI, unchanged.

## Decisions
1. **Bazel builds and tests; small Dockerfiles only package.** The runtime
   images copy Bazel's optimised binaries onto pinned base images: no compiler,
   non-root user, build context limited to the staged files.
2. **Native image build per architecture**, combined into one multi-arch tag.
   rules_oci was considered, but an arm64 image built on x86 needs
   cross-compilation (postponed, see ADR 0004).
3. **Compose integration test** runs the real images together on every PR.
4. **SBOM with Syft (SPDX JSON)** for every image and architecture, kept as
   CI artefacts.
5. **Grype gate:** any critical vulnerability fails the build.
6. **Push only from main; sign only digests.** cosign keyless signing with the
   workflow's GitHub OIDC identity; the signature is verified in the same job.
   No long-lived signing key exists that could leak.

## Consequences
+ Every published image is scanned, described by an SBOM and verifiably signed
+ PRs cannot publish anything
- Syft cannot see libraries statically linked into the C++ binary (protobuf,
  abseil, libc++); a Bazel-level SBOM is a future improvement
- Release builds (-c opt) need their own cache: more Actions cache usage

## Vulnerability policy
- Block on Critical. Fix High findings promptly when a fix exists
  (first scan: protobuf 5.29.3 -> 5.29.6, pip removed from the runtime image).
- Unfixable ("won't fix") findings are accepted until the distribution ships
  a fix; Dependabot proposes base image digest updates weekly.
