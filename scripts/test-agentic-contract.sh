#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

pass() {
  echo "PASS  $1"
}

fail() {
  echo "FAIL  $1" >&2
  FAILURES=$((FAILURES + 1))
}

require_file() {
  local path="$1"
  if [[ -f "$ROOT_DIR/$path" ]]; then
    pass "$path exists"
  else
    fail "$path missing"
  fi
}

require_dir() {
  local path="$1"
  if [[ -d "$ROOT_DIR/$path" ]]; then
    pass "$path exists"
  else
    fail "$path missing"
  fi
}

require_pattern() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if rg -q --fixed-strings -- "$pattern" "$ROOT_DIR/$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

forbid_pattern() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if rg -q --fixed-strings -- "$pattern" "$ROOT_DIR/$path"; then
    fail "$label"
  else
    pass "$label"
  fi
}

require_file "skills/cogworks/SKILL.md"
require_file "skills/cogworks/agentic-runtime.md"
require_file "skills/cogworks/claude-adapter.md"
require_file "skills/cogworks/copilot-adapter.md"
require_file "skills/cogworks/role-profiles.json"
require_file "skills/cogworks-encode/SKILL.md"
require_file "README.md"
require_file "TESTING.md"
require_file "tests/agentic-smoke/README.md"
require_dir "tests/agentic-smoke/fixtures/api-auth-smoke"
require_dir ".claude/agents"
require_file ".claude/agents/cogworks-intake-analyst.md"
require_file ".claude/agents/cogworks-synthesizer.md"
require_file ".claude/agents/cogworks-composer.md"
require_file ".claude/agents/cogworks-validator.md"
require_file "scripts/render-agentic-role-bindings.py"
require_file "scripts/validate-agentic-run.sh"
require_file "scripts/run-agentic-quality-compare.py"
require_file "scripts/compare-engine-performance.py"

require_pattern "skills/cogworks/SKILL.md" '--engine agentic' 'orchestrator exposes --engine agentic'
require_pattern "skills/cogworks/SKILL.md" 'execution_surface' 'orchestrator records execution_surface'
require_pattern "skills/cogworks/SKILL.md" 'specialist_profile_source' 'orchestrator records specialist_profile_source'
require_pattern "skills/cogworks/SKILL.md" 'dispatch-manifest.json' 'orchestrator requires dispatch-manifest.json'
require_pattern "skills/cogworks/SKILL.md" 'role-profiles.json' 'orchestrator resolves canonical role profiles'
require_pattern "skills/cogworks/SKILL.md" 'copilot-adapter.md' 'orchestrator references Copilot adapter'
require_pattern "skills/cogworks/SKILL.md" 'native-subagents' 'orchestrator uses native-subagents contract'
require_pattern "skills/cogworks/SKILL.md" '../../.claude/agents/cogworks-intake-analyst.md' 'orchestrator resolves Claude role binding'
require_pattern "skills/cogworks/SKILL.md" 'skill-packaging` is incomplete until non-empty `SKILL.md`, `reference.md`, and `metadata.json` exist' 'orchestrator blocks packaging pass until final files exist'
require_pattern "skills/cogworks/SKILL.md" 'do not auto-classify local files or local directories as trusted' 'orchestrator forbids implicit trust for local sources'
require_pattern "skills/cogworks/SKILL.md" 'do not describe ordinary domain guidance as prompt injection' 'orchestrator avoids over-classifying ordinary source prose as prompt injection'

require_pattern "skills/cogworks/agentic-runtime.md" 'execution_surface' 'runtime defines execution_surface'
require_pattern "skills/cogworks/agentic-runtime.md" 'native-subagents' 'runtime defines native-subagents adapter'
require_pattern "skills/cogworks/agentic-runtime.md" 'single-agent-fallback' 'runtime defines single-agent-fallback adapter'
require_pattern "skills/cogworks/agentic-runtime.md" 'canonical-role-specs' 'runtime defines canonical-role-specs profile source'
require_pattern "skills/cogworks/agentic-runtime.md" 'role-profiles.json' 'runtime points to canonical role profiles'
require_pattern "skills/cogworks/agentic-runtime.md" 'copilot-inline-prompt' 'runtime supports Copilot inline bindings'
require_pattern "skills/cogworks/agentic-runtime.md" 'dispatch-manifest.json' 'runtime requires dispatch-manifest.json'
require_pattern "skills/cogworks/agentic-runtime.md" 'profile_id' 'runtime dispatch contract records profile_id'
require_pattern "skills/cogworks/agentic-runtime.md" 'binding_type' 'runtime dispatch contract records binding_type'
require_pattern "skills/cogworks/agentic-runtime.md" 'binding_ref' 'runtime dispatch contract records binding_ref'
require_pattern "skills/cogworks/agentic-runtime.md" 'model_policy' 'runtime dispatch contract records model_policy'
require_pattern "skills/cogworks/agentic-runtime.md" 'Each specialist-owned stage must write its own `stage-status.json` before returning `pass`.' 'runtime assigns stage-status ownership to specialist stages'
require_pattern "skills/cogworks/agentic-runtime.md" 'must not rewrite a successful specialist-authored `stage-status.json`' 'runtime prevents coordinator from rewriting successful stage statuses'

require_pattern "skills/cogworks/claude-adapter.md" 'execution_surface = claude-cli' 'Claude adapter declares claude-cli surface'
require_pattern "skills/cogworks/claude-adapter.md" 'execution_adapter = native-subagents' 'Claude adapter declares native-subagents mode'
require_pattern "skills/cogworks/claude-adapter.md" 'specialist_profile_source = canonical-role-specs' 'Claude adapter uses canonical role specs'
require_pattern "skills/cogworks/claude-adapter.md" 'execution_adapter = single-agent-fallback' 'Claude adapter defines fallback adapter'
require_pattern "skills/cogworks/claude-adapter.md" 'role-profiles.json' 'Claude adapter references canonical role profiles'
require_pattern "skills/cogworks/claude-adapter.md" '.claude/agents/cogworks-composer.md' 'Claude adapter maps composer to generated agent file'
require_pattern "skills/cogworks/claude-adapter.md" 'compact summary contract' 'Claude adapter enforces compact summary contract'

require_pattern "skills/cogworks/copilot-adapter.md" 'execution_surface = copilot-cli' 'Copilot adapter declares copilot-cli surface'
require_pattern "skills/cogworks/copilot-adapter.md" 'execution_adapter = native-subagents' 'Copilot adapter supports native-subagents when available'
require_pattern "skills/cogworks/copilot-adapter.md" 'execution_adapter = single-agent-fallback' 'Copilot adapter defines fallback adapter'
require_pattern "skills/cogworks/copilot-adapter.md" 'inherit-session-model' 'Copilot adapter records inherit-session-model policy'
require_pattern "skills/cogworks/copilot-adapter.md" 'copilot-inline-prompt' 'Copilot adapter uses inline prompt bindings'
require_pattern "skills/cogworks/copilot-adapter.md" 'There is no v1 `.copilot/agents/` file format contract.' 'Copilot adapter does not invent a .copilot agent-file format'

require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "intake-analyst"' 'role profiles define intake-analyst'
require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "synthesizer"' 'role profiles define synthesizer'
require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "composer"' 'role profiles define composer'
require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "validator"' 'role profiles define validator'
require_pattern "skills/cogworks/role-profiles.json" '"binding_type": "claude-agent-file"' 'role profiles define Claude bindings'
require_pattern "skills/cogworks/role-profiles.json" '"binding_type": "copilot-inline-prompt"' 'role profiles define Copilot bindings'
require_pattern "skills/cogworks/role-profiles.json" '"model_policy": "inherit-session-model"' 'role profiles define Copilot model policy'

require_pattern "scripts/render-agentic-role-bindings.py" 'role-profiles.json' 'renderer reads canonical role profiles'
require_pattern "scripts/render-agentic-role-bindings.py" 'Derived from skills/cogworks/role-profiles.json' 'renderer emits derived-file marker'
require_pattern "scripts/render-agentic-role-bindings.py" 'bindings"]["claude-cli"]' 'renderer derives Claude bindings from canonical role profiles'

require_pattern ".claude/agents/cogworks-intake-analyst.md" '<!-- Derived from skills/cogworks/role-profiles.json#intake-analyst -->' 'intake agent is marked as derived'
require_pattern ".claude/agents/cogworks-intake-analyst.md" 'model: haiku' 'intake agent is pinned to haiku'
require_pattern ".claude/agents/cogworks-synthesizer.md" '<!-- Derived from skills/cogworks/role-profiles.json#synthesizer -->' 'synthesizer agent is marked as derived'
require_pattern ".claude/agents/cogworks-synthesizer.md" 'model: sonnet' 'synthesizer agent is pinned to sonnet'
require_pattern ".claude/agents/cogworks-composer.md" '<!-- Derived from skills/cogworks/role-profiles.json#composer -->' 'composer agent is marked as derived'
require_pattern ".claude/agents/cogworks-composer.md" 'model: sonnet' 'composer agent is pinned to sonnet'
require_pattern ".claude/agents/cogworks-validator.md" '<!-- Derived from skills/cogworks/role-profiles.json#validator -->' 'validator agent is marked as derived'
require_pattern ".claude/agents/cogworks-validator.md" 'model: haiku' 'validator agent is pinned to haiku'

require_pattern "README.md" '--engine agentic' 'root README documents --engine agentic'
require_pattern "README.md" 'canonical role profiles' 'root README documents canonical role profiles'
require_pattern "README.md" 'GitHub Copilot CLI' 'root README documents Copilot CLI adapter'
require_pattern "README.md" 'dispatch-manifest.json' 'root README documents dispatch-manifest.json'
forbid_pattern "README.md" 'Agentic engine is Claude-first' 'root README no longer claims the agentic engine is Claude-first'

require_pattern "skills/cogworks/README.md" 'GitHub Copilot CLI' 'skill README documents Copilot CLI adapter'
require_pattern "skills/cogworks/README.md" '.cogworks-runs/' 'skill README documents run artifact root'
require_pattern "skills/cogworks/README.md" 'dispatch-manifest.json' 'skill README documents dispatch-manifest.json'

require_pattern "TESTING.md" 'canonical role specs defined' 'TESTING documents canonical role specs'
require_pattern "TESTING.md" 'Claude and Copilot CLI adapters defined' 'TESTING documents both adapters'
require_pattern "TESTING.md" '--expect-surface claude-cli' 'TESTING documents surface-specific validation'
require_pattern "TESTING.md" '--expect-surface copilot-cli' 'TESTING documents Copilot validation'
require_pattern "TESTING.md" 'dispatch-manifest.json` exists for `native-subagents` runs' 'TESTING uses native-subagents terminology'
require_pattern "TESTING.md" 'canonical role profiles, surface bindings, model policy, and actual dispatch modes' 'TESTING documents generalized dispatch manifest'

require_pattern "tests/agentic-smoke/README.md" 'execution_surface = claude-cli' 'smoke runbook documents Claude surface expectation'
require_pattern "tests/agentic-smoke/README.md" 'execution_surface = copilot-cli' 'smoke runbook documents Copilot surface expectation'
require_pattern "tests/agentic-smoke/README.md" '--expect-surface claude-cli' 'smoke runbook documents Claude validation flags'
require_pattern "tests/agentic-smoke/README.md" '--expect-surface copilot-cli' 'smoke runbook documents Copilot validation flags'
require_pattern "tests/agentic-smoke/README.md" 'dispatch-manifest.json` exists for `native-subagents` runs' 'smoke runbook uses native-subagents terminology'
forbid_pattern "tests/agentic-smoke/README.md" 'Claude-first adapter behavior' 'smoke runbook no longer claims a Claude-first adapter'

require_pattern "scripts/validate-agentic-run.sh" '--expect-surface' 'live run validator supports --expect-surface'
require_pattern "scripts/validate-agentic-run.sh" 'native-subagents' 'live run validator supports native-subagents'
require_pattern "scripts/validate-agentic-run.sh" 'copilot-inline-prompt' 'live run validator validates Copilot inline bindings'
require_pattern "scripts/validate-agentic-run.sh" 'inherit-session-model' 'live run validator validates Copilot model policy'
require_pattern "scripts/validate-agentic-run.sh" 'canonical-role-specs' 'live run validator validates canonical-role-specs'

require_pattern "scripts/run-agentic-quality-compare.py" 'execution_surface = claude-cli' 'quality comparison prompt requires claude-cli surface'
require_pattern "scripts/run-agentic-quality-compare.py" 'execution_adapter = native-subagents' 'quality comparison prompt requires native-subagents'
require_pattern "scripts/run-agentic-quality-compare.py" 'specialist_profile_source = canonical-role-specs' 'quality comparison prompt requires canonical role specs'
require_pattern "scripts/run-agentic-quality-compare.py" 'role-profiles.json' 'quality comparison prompt references canonical role profiles'
require_pattern "scripts/run-agentic-quality-compare.py" '--expect-surface' 'quality comparison runner validates execution surface explicitly'

require_pattern "scripts/compare-engine-performance.py" 'Execution surface' 'comparison report includes execution surface'
require_pattern "scripts/compare-engine-performance.py" 'Specialist profile source' 'comparison report includes specialist profile source'
require_pattern "scripts/compare-engine-performance.py" 'Binding types' 'comparison report includes binding types'
require_pattern "scripts/compare-engine-performance.py" 'Model policies' 'comparison report includes model policies'

if python3 - <<'PY' "$ROOT_DIR/skills/cogworks/role-profiles.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
profiles = {profile["profile_id"]: profile for profile in data["profiles"]}
required = {"intake-analyst", "synthesizer", "composer", "validator"}
if set(profiles) != required:
    raise SystemExit(1)
for profile_id in required:
    bindings = profiles[profile_id]["bindings"]
    if "claude-cli" not in bindings or "copilot-cli" not in bindings:
        raise SystemExit(1)
PY
then
  pass 'role-profiles.json defines the four canonical roles with Claude and Copilot bindings'
else
  fail 'role-profiles.json is missing required canonical role bindings'
fi

if bash "$ROOT_DIR/tests/framework/graders/deterministic-checks.sh" "$ROOT_DIR/skills/cogworks" >/dev/null 2>&1; then
  pass 'deterministic checks pass for skills/cogworks'
else
  fail 'deterministic checks failed for skills/cogworks'
fi

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "Agentic contract test failed with $FAILURES issue(s)." >&2
  exit 1
fi

echo ""
echo "Agentic contract test passed."
