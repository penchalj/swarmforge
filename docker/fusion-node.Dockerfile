# Runtime image: only the fusion_node binary on a pinned Ubuntu base.
# No compiler, no build tools. The binary is built and tested by Bazel.
FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7

LABEL org.opencontainers.image.source="https://github.com/penchalj/swarmforge" \
      org.opencontainers.image.description="SwarmForge fusion-node" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --chmod=0755 fusion_node /usr/local/bin/fusion_node

# Non-root: the "ubuntu" user (UID 1000) already exists in this base image.
USER ubuntu
ENTRYPOINT ["/usr/local/bin/fusion_node"]
