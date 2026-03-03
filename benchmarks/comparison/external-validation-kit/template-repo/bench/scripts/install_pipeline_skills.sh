#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 --protocol <path> --pipeline <id> --workspace-root <path> --codex-home <path> --out <path> --mode <real|offline>" >&2
}

PROTOCOL=""
PIPELINE=""
WORKSPACE_ROOT=""
CODEX_HOME_DIR=""
OUT=""
MODE="real"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --protocol) PROTOCOL="$2"; shift 2 ;;
    --pipeline) PIPELINE="$2"; shift 2 ;;
    --workspace-root) WORKSPACE_ROOT="$2"; shift 2 ;;
    --codex-home) CODEX_HOME_DIR="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$PROTOCOL" || -z "$PIPELINE" || -z "$WORKSPACE_ROOT" || -z "$CODEX_HOME_DIR" || -z "$OUT" ]]; then
  usage
  exit 2
fi

mkdir -p "$(dirname "$OUT")" "$CODEX_HOME_DIR"

python3 - "$PROTOCOL" "$PIPELINE" "$WORKSPACE_ROOT" "$CODEX_HOME_DIR" "$OUT" "$MODE" <<'PY'
import json
import os
import shlex
import subprocess
import sys
from datetime import datetime, UTC
from pathlib import Path

protocol = Path(sys.argv[1]).resolve()
pipeline = sys.argv[2]
workspace_root = Path(sys.argv[3]).resolve()
codex_home = Path(sys.argv[4]).resolve()
out = Path(sys.argv[5]).resolve()
mode = sys.argv[6]
repo_root = protocol.parents[2]

cfg = json.loads(protocol.read_text(encoding='utf-8'))
pl = cfg.get('pipelines', {}).get(pipeline, {})
exec_mode = pl.get('execution_mode', 'protocol_prompt')
install = pl.get('skill_install', {}) if isinstance(pl.get('skill_install'), dict) else {}

payload = {
    'timestamp_utc': datetime.now(UTC).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'pipeline': pipeline,
    'execution_mode': exec_mode,
    'mode': mode,
    'workspace_root': str(workspace_root),
    'codex_home': str(codex_home),
    'command': None,
    'exit_code': 0,
    'success': True,
    'status': 'skipped',
    'reason': 'pipeline is not skill_installed',
    'expected_skills': install.get('expected_skills', []),
    'detected_skills': [],
}

if mode == 'offline':
    payload['status'] = 'skipped-offline'
    payload['reason'] = 'offline mode smoke run'
    out.write_text(json.dumps(payload, indent=2), encoding='utf-8')
    sys.exit(0)

if exec_mode != 'skill_installed':
    out.write_text(json.dumps(payload, indent=2), encoding='utf-8')
    sys.exit(0)

source = install.get('source', '')
if not source:
    payload['status'] = 'failed'
    payload['success'] = False
    payload['exit_code'] = 2
    payload['reason'] = 'missing skill_install.source'
    out.write_text(json.dumps(payload, indent=2), encoding='utf-8')
    sys.exit(2)

source_path = Path(source)
if not source_path.is_absolute():
    source_path = (repo_root / source_path).resolve()

install_flags = install.get('install_flags', ['-a', 'codex', '-y'])
if not isinstance(install_flags, list):
    install_flags = ['-a', 'codex', '-y']

cmd = ['npx', 'skills', 'add', str(source_path)] + [str(x) for x in install_flags]
for skill in install.get('expected_skills', []):
    cmd += ['--skill', str(skill)]

payload['command'] = ' '.join(shlex.quote(x) for x in cmd)
payload['status'] = 'attempted'
payload['reason'] = ''

env = os.environ.copy()
env['CODEX_HOME'] = str(codex_home)
# Keep HOME isolated as well for agents that resolve paths from HOME.
env['HOME'] = str(codex_home / 'home')
Path(env['HOME']).mkdir(parents=True, exist_ok=True)

proc = subprocess.run(cmd, cwd=str(workspace_root), env=env, capture_output=True, text=True)
payload['exit_code'] = proc.returncode
payload['stdout_log'] = str((out.parent / 'skill-install.stdout.log'))
payload['stderr_log'] = str((out.parent / 'skill-install.stderr.log'))
(out.parent / 'skill-install.stdout.log').write_text(proc.stdout or '', encoding='utf-8')
(out.parent / 'skill-install.stderr.log').write_text(proc.stderr or '', encoding='utf-8')

candidate_roots = [
    codex_home / 'skills',
    workspace_root / '.codex' / 'skills',
    workspace_root / '.agents' / 'skills',
]

detected = []
for root in candidate_roots:
    if root.exists():
        for p in sorted(root.glob('*/SKILL.md')):
            detected.append(str(p.parent.name))
payload['detected_skills'] = sorted(set(detected))

expected = [str(x) for x in install.get('expected_skills', [])]
if proc.returncode != 0:
    payload['success'] = False
    payload['status'] = 'failed'
    payload['reason'] = 'skills add exited non-zero'
elif expected and any(s not in payload['detected_skills'] for s in expected):
    payload['success'] = False
    payload['status'] = 'failed'
    payload['reason'] = 'expected skill slug not detected after install'
else:
    payload['success'] = True
    payload['status'] = 'installed'
    payload['reason'] = 'ok'

out.write_text(json.dumps(payload, indent=2), encoding='utf-8')
sys.exit(0 if payload['success'] else 1)
PY
