# Pinned build environment: same image for laptops and CI
FROM ubuntu:24.04@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55

# libc6-dev + libgcc-13-dev = the target system's C library headers and startup
# files (the "sysroot"). The compiler itself comes from Bazel's pinned LLVM.
# clang-format-18 and shellcheck are linters only; no compiler is installed.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git python3 libxml2 \
        libc6-dev libgcc-13-dev \
        clang-format-18 shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Bazelisk, pinned
RUN curl -fsSL -o /usr/local/bin/bazel \
      https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 \
    && chmod +x /usr/local/bin/bazel

# Lint tools, pinned: buildifier (Bazel files) and ruff (Python)
RUN curl -fsSL -o /usr/local/bin/buildifier \
      https://github.com/bazelbuild/buildtools/releases/download/v7.3.1/buildifier-linux-amd64 \
    && chmod +x /usr/local/bin/buildifier \
    && curl -fsSL https://github.com/astral-sh/ruff/releases/download/0.6.9/ruff-x86_64-unknown-linux-gnu.tar.gz \
       | tar -xz -C /usr/local/bin --strip-components=1 ruff-x86_64-unknown-linux-gnu/ruff

# Writable home and cache for any user ID (CI runners use UID 1001, laptops 1000)
RUN mkdir -p /home/ubuntu/.cache \
    && chown -R ubuntu:ubuntu /home/ubuntu/.cache \
    && chmod 1777 /home/ubuntu /home/ubuntu/.cache
USER ubuntu
WORKDIR /workspace
