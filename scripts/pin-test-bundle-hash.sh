#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <round-manifest-path>" >&2
  exit 2
fi

manifest="$1"
if [[ ! -f "$manifest" ]]; then
  echo "Manifest not found: $manifest" >&2
  exit 2
fi

python3 - "$manifest" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1]).resolve()
root = manifest_path.parent.parent.parent.parent.resolve()  # tests/datasets/recursive-round -> repo root
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
paths = manifest.get('test_bundle', {}).get('bundle_paths')
if not isinstance(paths, list) or not paths:
    raise SystemExit('test_bundle.bundle_paths must be a non-empty list in manifest')

files = []
for rel in paths:
    p = (root / rel).resolve()
    if not p.exists():
        raise SystemExit(f'Path not found: {rel}')
    if p.is_file():
        files.append(p)
    else:
        files.extend([x for x in p.rglob('*') if x.is_file()])

h = hashlib.sha256()
for p in sorted(files):
    rel = p.relative_to(root).as_posix()
    h.update(rel.encode('utf-8'))
    h.update(b'\0')
    h.update(hashlib.sha256(p.read_bytes()).hexdigest().encode('utf-8'))
    h.update(b'\n')
val = h.hexdigest()
manifest.setdefault('test_bundle', {})['expected_sha256'] = val
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(val)
PY
