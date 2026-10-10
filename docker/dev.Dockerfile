# Pinned build environment: same image for laptops and CI
FROM ubuntu:24.04

# libc6-dev + libgcc-13-dev = the target system's C library headers and startup
# files (the "sysroot"). The compiler itself comes from Bazel's pinned LLVM.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git python3 libxml2 \
        libc6-dev libgcc-13-dev \
    && rm -rf /var/lib/apt/lists/*

# Bazelisk, pinned
RUN curl -fsSL -o /usr/local/bin/bazel \
      https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 \
    && chmod +x /usr/local/bin/bazel

# Ubuntu 24.04 images already contain user "ubuntu" (UID 1000)
RUN mkdir -p /home/ubuntu/.cache && chown -R ubuntu:ubuntu /home/ubuntu/.cache
USER ubuntu
WORKDIR /workspace
