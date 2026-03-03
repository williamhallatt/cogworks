FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Optional: install jsonschema for protocol validation helpers.
RUN pip install --no-cache-dir jsonschema

CMD ["bash"]
