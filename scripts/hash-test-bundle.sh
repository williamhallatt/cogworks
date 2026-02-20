#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path> [<path> ...]" >&2
  exit 2
fi

python3 - "$ROOT_DIR" "$@" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
inputs = sys.argv[2:]
files = []
for rel in inputs:
    p = (root / rel).resolve()
    if not p.exists():
        raise SystemExit(f"path not found: {rel}")
    if p.is_file():
        files.append(p)
    else:
        files.extend([x for x in p.rglob("*") if x.is_file()])

h = hashlib.sha256()
for p in sorted(files):
    rel = p.relative_to(root).as_posix()
    h.update(rel.encode("utf-8"))
    h.update(b"\0")
    h.update(hashlib.sha256(p.read_bytes()).hexdigest().encode("utf-8"))
    h.update(b"\n")
print(h.hexdigest())
PY
