# Runtime image for the Python detector. The protobuf Python package must match
# the Bazel-generated code: protobuf 29.x <-> Python package 5.29.x (>= 5.29.3).
FROM python:3.12-slim@sha256:a6e34c598f2467ed0e9a8d349809fcd8b5c603269512df273a0bb1784edc11b1

LABEL org.opencontainers.image.source="https://github.com/penchalj/swarmforge" \
      org.opencontainers.image.description="SwarmForge synthetic detector" \
      org.opencontainers.image.licenses="Apache-2.0"

RUN pip install --no-cache-dir protobuf==5.29.6 \
    && pip uninstall -y pip \
    && mkdir -p /data && chown nobody:nogroup /data

WORKDIR /app
COPY app/ /app/

USER nobody
ENTRYPOINT ["python", "-m", "detector.sim_detector"]
