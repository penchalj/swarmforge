# Runtime image: only the fusion_node binary on a pinned Ubuntu base.
# No compiler, no build tools. The binary is built and tested by Bazel.
FROM ubuntu:24.04@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55

LABEL org.opencontainers.image.source="https://github.com/penchalj/swarmforge" \
      org.opencontainers.image.description="SwarmForge fusion-node" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --chmod=0755 fusion_node /usr/local/bin/fusion_node

# Non-root: the "ubuntu" user (UID 1000) already exists in this base image.
USER ubuntu
ENTRYPOINT ["/usr/local/bin/fusion_node"]
