#!/usr/bin/env bash
# Installs a pinned crane (go-containerregistry) into /usr/local/bin.
# crane re-tags an existing image without changing its digest.
set -euo pipefail

version="v0.20.2"
case "$(uname -m)" in
  x86_64) arch=x86_64 ;;
  aarch64) arch=arm64 ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

curl -fsSL "https://github.com/google/go-containerregistry/releases/download/${version}/go-containerregistry_Linux_${arch}.tar.gz" |
  sudo tar -xz -C /usr/local/bin crane
crane version
