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
require_file "skills/cogworks/README.md"
require_file "skills/cogworks/agentic-runtime.md"
require_file "skills/cogworks/claude-adapter.md"
require_file "skills/cogworks/copilot-adapter.md"
require_file "skills/cogworks/role-profiles.json"
require_file "skills/cogworks-encode/SKILL.md"
require_file "skills/cogworks-learn/SKILL.md"
require_file "README.md"
require_file "INSTALL.md"
require_file "TESTING.md"
require_file "tests/agentic-smoke/README.md"
require_dir "tests/agentic-smoke/fixtures/api-auth-smoke"
require_file "scripts/render-agentic-role-bindings.py"
require_file "scripts/render-dispatch-manifest.py"
require_file "scripts/resolve-role-profile.py"
require_file "scripts/validate-agentic-run.sh"
require_dir ".claude/agents"
require_file ".claude/agents/cogworks-intake-analyst.md"
require_file ".claude/agents/cogworks-synthesizer.md"
require_file ".claude/agents/cogworks-composer.md"
require_file ".claude/agents/cogworks-validator.md"

require_pattern "skills/cogworks/SKILL.md" 'turn source material into a validated generated skill' 'orchestrator exposes the single product purpose'
require_pattern "skills/cogworks/SKILL.md" 'fail closed when trust, provenance, contradiction handling, or validation is' 'orchestrator is fail-closed'
require_pattern "skills/cogworks/SKILL.md" 'only the generated skill is a user-facing product artifact' 'orchestrator hides internal execution strategy'
require_pattern "skills/cogworks/SKILL.md" 'runtime details such as execution surface, run root, or sub-agent metadata do' 'orchestrator forbids runtime metadata leakage'
forbid_pattern "skills/cogworks/SKILL.md" '--engine agentic' 'orchestrator no longer exposes --engine agentic'
forbid_pattern "skills/cogworks/SKILL.md" 'Default to `legacy`' 'orchestrator no longer exposes legacy engine choice'

require_pattern "README.md" 'one stable user-facing entry point: `cogworks`' 'root README documents one stable entry point'
require_pattern "README.md" 'Sub-agents are implementation machinery, not a public interface.' 'root README keeps sub-agents internal'
require_pattern "README.md" 'Codex sub-agent build' 'root README documents Codex deferral'
forbid_pattern "README.md" '--engine agentic' 'root README no longer documents --engine agentic'
forbid_pattern "README.md" 'Legacy' 'root README no longer presents a legacy engine mode'

require_pattern "skills/cogworks/README.md" 'They are not a user-facing mode switch.' 'skill README keeps sub-agents internal'
forbid_pattern "skills/cogworks/README.md" '--engine agentic' 'skill README no longer documents --engine agentic'

require_pattern "INSTALL.md" '`cogworks` is the normal user-facing entry point.' 'install guide documents the single entry point'
forbid_pattern "INSTALL.md" '/cogworks encode' 'install guide no longer documents pseudo-CLI invocation'

require_pattern "skills/cogworks/agentic-runtime.md" 'run_type = subagent-skill-build' 'runtime defines subagent build run type'
require_pattern "skills/cogworks/agentic-runtime.md" 'execution_surface = claude-cli | copilot-cli' 'runtime defines supported surfaces'
require_pattern "skills/cogworks/agentic-runtime.md" 'specialist_profile_source = canonical-role-specs' 'runtime requires canonical role specs'
require_pattern "skills/cogworks/agentic-runtime.md" 'dispatch-manifest.json' 'runtime requires dispatch-manifest.json'
forbid_pattern "skills/cogworks/agentic-runtime.md" 'single-agent-fallback' 'runtime no longer promises single-agent fallback'
forbid_pattern "skills/cogworks/agentic-runtime.md" 'engine_mode' 'runtime no longer documents engine_mode'

require_pattern "skills/cogworks/claude-adapter.md" 'execution_surface = claude-cli' 'Claude adapter declares claude-cli surface'
require_pattern "skills/cogworks/claude-adapter.md" 'If the `Task` tool is unavailable' 'Claude adapter fails closed without Task'
require_pattern "skills/cogworks/claude-adapter.md" 'claude-role-profile' 'Claude adapter records canonical profile bindings'
require_pattern "skills/cogworks/claude-adapter.md" 'python3 scripts/render-agentic-role-bindings.py' 'Claude adapter documents provisioning bridge'
forbid_pattern "skills/cogworks/claude-adapter.md" 'single-agent-fallback' 'Claude adapter no longer claims single-agent fallback'

require_pattern "skills/cogworks/copilot-adapter.md" 'execution_surface = copilot-cli' 'Copilot adapter declares copilot-cli surface'
require_pattern "skills/cogworks/copilot-adapter.md" 'inherit-session-model' 'Copilot adapter records inherit-session-model policy'
require_pattern "skills/cogworks/copilot-adapter.md" 'There is no v1 `.copilot/agents/` file format contract.' 'Copilot adapter does not invent a .copilot agent-file format'
forbid_pattern "skills/cogworks/copilot-adapter.md" 'single-agent-fallback' 'Copilot adapter no longer claims single-agent fallback'

require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "intake-analyst"' 'role profiles define intake-analyst'
require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "synthesizer"' 'role profiles define synthesizer'
require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "composer"' 'role profiles define composer'
require_pattern "skills/cogworks/role-profiles.json" '"profile_id": "validator"' 'role profiles define validator'
require_pattern "skills/cogworks/role-profiles.json" '"binding_type": "claude-role-profile"' 'role profiles define Claude bindings'
require_pattern "skills/cogworks/role-profiles.json" '"binding_type": "copilot-inline-prompt"' 'role profiles define Copilot bindings'

require_pattern "TESTING.md" 'Sub-agent build smoke' 'testing guide documents sub-agent build smoke'
require_pattern "TESTING.md" 'no public engine-selection syntax' 'testing guide enforces removal of public engine selection'
forbid_pattern "TESTING.md" '--engine agentic' 'testing guide no longer documents --engine agentic'

require_pattern "tests/agentic-smoke/README.md" 'Sub-Agent Smoke Runbook' 'smoke runbook title updated'
require_pattern "tests/agentic-smoke/README.md" 'run_type: "subagent-skill-build"' 'smoke runbook documents new run_type'
require_pattern "tests/agentic-smoke/README.md" 'does **not** leak runtime metadata' 'smoke runbook checks for product metadata hygiene'
forbid_pattern "tests/agentic-smoke/README.md" '--engine agentic' 'smoke runbook no longer documents --engine agentic'

require_pattern "scripts/validate-agentic-run.sh" 'run_type' 'run validator validates run_type'
require_pattern "scripts/validate-agentic-run.sh" 'execution_surface' 'run validator validates execution_surface'
require_pattern "scripts/validate-agentic-run.sh" 'specialist_profile_source' 'run validator validates specialist_profile_source'
forbid_pattern "scripts/validate-agentic-run.sh" '.engine_mode ==' 'run validator no longer requires engine_mode'
forbid_pattern "scripts/validate-agentic-run.sh" 'single-agent-fallback' 'run validator no longer validates single-agent fallback'

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

if python3 "$ROOT_DIR/scripts/render-agentic-role-bindings.py" --check >/dev/null 2>&1; then
  pass 'render-agentic-role-bindings.py is in sync with committed Claude agent files'
else
  fail 'render-agentic-role-bindings.py output differs from committed Claude agent files'
fi

DET_EXIT=0
if bash "$ROOT_DIR/tests/framework/graders/deterministic-checks.sh" "$ROOT_DIR/skills/cogworks" >/dev/null 2>&1; then
  pass 'deterministic checks pass for skills/cogworks'
else
  DET_EXIT=$?
  if [[ $DET_EXIT -eq 2 ]]; then
    pass 'deterministic checks pass for skills/cogworks with warnings only'
  else
    fail 'deterministic checks failed for skills/cogworks'
  fi
fi

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "Contract test failed with $FAILURES issue(s)." >&2
  exit 1
fi

echo ""
echo "Contract test passed."
