#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ROOT=""
SKILL_PATH=""
EXPECT_SURFACE=""
FINAL_SUMMARY_PATH=""
STAGE_INDEX_PATH=""
DISPATCH_MANIFEST_PATH=""
FAILURES=0

usage() {
  cat <<'USAGE'
Usage: scripts/validate-agentic-run.sh --run-root <path> --skill-path <path> [--expect-surface <name>]

Validates the maintainer-only cogworks sub-agent run artifact contract.
USAGE
}

pass() {
  echo "PASS  $1"
}

fail() {
  echo "FAIL  $1" >&2
  FAILURES=$((FAILURES + 1))
}

check_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_nonempty_file() {
  local path="$1"
  local label="$2"
  if [[ -s "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

resolve_final_summary() {
  local path
  for path in "$RUN_ROOT/final-summary.md" "$RUN_ROOT/final-review/final-summary.md"; do
    if [[ -f "$path" ]]; then
      FINAL_SUMMARY_PATH="$path"
      pass "final-summary.md exists"
      return 0
    fi
  done
  fail "final-summary.md exists"
}

resolve_stage_index() {
  local path
  for path in "$RUN_ROOT/stage-index.json" "$RUN_ROOT/final-review/stage-index.json"; do
    if [[ -f "$path" ]]; then
      STAGE_INDEX_PATH="$path"
      pass "stage-index.json exists"
      return 0
    fi
  done
  fail "stage-index.json exists"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-root)
      RUN_ROOT="$2"
      shift 2
      ;;
    --skill-path)
      SKILL_PATH="$2"
      shift 2
      ;;
    --expect-surface)
      EXPECT_SURFACE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$RUN_ROOT" || -z "$SKILL_PATH" ]]; then
  usage >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 2
fi

check_dir "$RUN_ROOT" "run root exists"
check_nonempty_file "$RUN_ROOT/run-manifest.json" "run-manifest.json exists and is non-empty"
resolve_stage_index
resolve_final_summary

if [[ -n "$STAGE_INDEX_PATH" ]]; then
  check_nonempty_file "$STAGE_INDEX_PATH" "stage-index.json is non-empty"
fi

if jq -e '
  .run_type == "subagent-skill-build" and
  (.run_id | type == "string" and length > 0) and
  (.execution_surface == "claude-cli" or .execution_surface == "copilot-cli") and
  .specialist_profile_source == "canonical-role-specs" and
  (.stages_expected | arrays and length > 0)
' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  pass 'run-manifest.json has required sub-agent metadata'
else
  fail 'run-manifest.json missing required sub-agent metadata'
fi

if [[ -n "$EXPECT_SURFACE" ]]; then
  if jq -e --arg surface "$EXPECT_SURFACE" '.execution_surface == $surface' "$RUN_ROOT/run-manifest.json" >/dev/null; then
    pass "run-manifest.json execution_surface == $EXPECT_SURFACE"
  else
    fail "run-manifest.json execution_surface != $EXPECT_SURFACE"
  fi
fi

DISPATCH_MANIFEST_PATH="$RUN_ROOT/dispatch-manifest.json"
check_nonempty_file "$DISPATCH_MANIFEST_PATH" "dispatch-manifest.json exists and is non-empty"

if jq -e '
  .profile_source == "canonical-role-specs" and
  (.execution_surface == "claude-cli" or .execution_surface == "copilot-cli") and
  (.dispatches | arrays and length >= 4)
' "$DISPATCH_MANIFEST_PATH" >/dev/null; then
  pass 'dispatch-manifest.json has required top-level fields'
else
  fail 'dispatch-manifest.json missing required top-level fields'
fi

validate_dispatch_record() {
  local stage="$1"
  local role="$2"
  local profile_id="$3"
  local binding_type="$4"
  local binding_ref="$5"
  local model_policy="$6"
  if jq -e \
    --arg stage "$stage" \
    --arg role "$role" \
    --arg profile_id "$profile_id" \
    --arg binding_type "$binding_type" \
    --arg binding_ref "$binding_ref" \
    --arg model_policy "$model_policy" \
    '
    any(.dispatches[]?;
      .stage == $stage and
      .role == $role and
      .profile_id == $profile_id and
      .binding_type == $binding_type and
      .binding_ref == $binding_ref and
      .model_policy == $model_policy and
      (.preferred_dispatch_mode == "background" or .preferred_dispatch_mode == "foreground") and
      (.actual_dispatch_mode == "background" or .actual_dispatch_mode == "foreground") and
      ((.tool_scope | type) == "string" and (.tool_scope | length > 0)) and
      ((.status | type) == "string" and (.status | length > 0))
    )
  ' "$DISPATCH_MANIFEST_PATH" >/dev/null; then
    pass "$stage dispatch manifest record exists"
  else
    fail "$stage dispatch manifest record missing"
  fi
}

SURFACE="$(jq -r '.execution_surface' "$RUN_ROOT/run-manifest.json")"
if [[ "$SURFACE" == "claude-cli" ]]; then
  validate_dispatch_record "source-intake" "intake-analyst" "intake-analyst" "claude-agent-file" ".claude/agents/cogworks-intake-analyst.md" "pinned-haiku"
  validate_dispatch_record "synthesis" "synthesizer" "synthesizer" "claude-agent-file" ".claude/agents/cogworks-synthesizer.md" "pinned-sonnet"
  validate_dispatch_record "skill-packaging" "composer" "composer" "claude-agent-file" ".claude/agents/cogworks-composer.md" "pinned-sonnet"
  validate_dispatch_record "deterministic-validation" "validator" "validator" "claude-agent-file" ".claude/agents/cogworks-validator.md" "pinned-haiku"
elif [[ "$SURFACE" == "copilot-cli" ]]; then
  validate_dispatch_record "source-intake" "intake-analyst" "intake-analyst" "copilot-inline-prompt" "skills/cogworks/role-profiles.json#intake-analyst" "inherit-session-model"
  validate_dispatch_record "synthesis" "synthesizer" "synthesizer" "copilot-inline-prompt" "skills/cogworks/role-profiles.json#synthesizer" "inherit-session-model"
  validate_dispatch_record "skill-packaging" "composer" "composer" "copilot-inline-prompt" "skills/cogworks/role-profiles.json#composer" "inherit-session-model"
  validate_dispatch_record "deterministic-validation" "validator" "validator" "copilot-inline-prompt" "skills/cogworks/role-profiles.json#validator" "inherit-session-model"
fi

stages=(
  source-intake
  synthesis
  skill-packaging
  deterministic-validation
  final-review
)

for stage in "${stages[@]}"; do
  check_dir "$RUN_ROOT/$stage" "$stage directory exists"
  check_nonempty_file "$RUN_ROOT/$stage/stage-status.json" "$stage stage-status.json exists and is non-empty"
  if [[ -f "$RUN_ROOT/$stage/stage-status.json" ]]; then
    if jq -e --arg stage "$stage" '.stage == $stage and (.status | length > 0)' "$RUN_ROOT/$stage/stage-status.json" >/dev/null; then
      pass "$stage stage-status.json has required fields"
    else
      fail "$stage stage-status.json missing required fields"
    fi
  fi
done

check_nonempty_file "$RUN_ROOT/source-intake/source-inventory.json" "source-intake/source-inventory.json exists and is non-empty"
check_nonempty_file "$RUN_ROOT/source-intake/source-manifest.json" "source-intake/source-manifest.json exists and is non-empty"
check_nonempty_file "$RUN_ROOT/source-intake/source-trust-report.md" "source-intake/source-trust-report.md exists and is non-empty"
check_nonempty_file "$RUN_ROOT/source-intake/source-trust-gate.json" "source-intake/source-trust-gate.json exists and is non-empty"

if [[ -f "$RUN_ROOT/source-intake/source-trust-gate.json" ]]; then
  if jq -e '.gate_passed == true and ((.sources | type) == "array") and ((.sources | length) > 0)' "$RUN_ROOT/source-intake/source-trust-gate.json" >/dev/null; then
    pass "source-trust-gate.json has gate_passed: true with classified sources"
  else
    fail "source-trust-gate.json missing gate_passed: true or classified sources"
  fi
fi

check_nonempty_file "$RUN_ROOT/synthesis/synthesis.md" "synthesis/synthesis.md exists and is non-empty"
check_nonempty_file "$RUN_ROOT/synthesis/cdr-registry.md" "synthesis/cdr-registry.md exists and is non-empty"
check_nonempty_file "$RUN_ROOT/synthesis/traceability-map.md" "synthesis/traceability-map.md exists and is non-empty"

check_nonempty_file "$RUN_ROOT/skill-packaging/decision-skeleton.json" "skill-packaging/decision-skeleton.json exists and is non-empty"
check_nonempty_file "$RUN_ROOT/skill-packaging/composition-notes.md" "skill-packaging/composition-notes.md exists and is non-empty"

check_dir "$SKILL_PATH" "generated skill directory exists"
check_nonempty_file "$SKILL_PATH/SKILL.md" "generated skill SKILL.md exists and is non-empty"
check_nonempty_file "$SKILL_PATH/reference.md" "generated skill reference.md exists and is non-empty"
check_nonempty_file "$SKILL_PATH/metadata.json" "generated skill metadata.json exists and is non-empty"

if rg -q '^(engine_mode|execution_surface|execution_adapter|run_root|skill_path):' "$SKILL_PATH/SKILL.md"; then
  fail 'generated skill SKILL.md leaks runtime metadata'
else
  pass 'generated skill SKILL.md does not leak runtime metadata'
fi

if jq -e 'has("engine_mode") or has("execution_surface") or has("execution_adapter") or has("run_root") or has("skill_path")' "$SKILL_PATH/metadata.json" >/dev/null; then
  fail 'generated skill metadata.json leaks runtime metadata'
else
  pass 'generated skill metadata.json does not leak runtime metadata'
fi

check_nonempty_file "$RUN_ROOT/deterministic-validation/deterministic-gate-report.json" "deterministic-validation/deterministic-gate-report.json exists and is non-empty"
check_nonempty_file "$RUN_ROOT/deterministic-validation/final-gate-report.json" "deterministic-validation/final-gate-report.json exists and is non-empty"

REFERENCE_VALIDATION_EXIT=0
REFERENCE_VALIDATION_OUTPUT=""
if [[ -f "$ROOT_DIR/skills/cogworks-encode/scripts/validate-synthesis.sh" && -f "$SKILL_PATH/reference.md" ]]; then
  REFERENCE_VALIDATION_OUTPUT="$(bash "$ROOT_DIR/skills/cogworks-encode/scripts/validate-synthesis.sh" "$SKILL_PATH/reference.md" 2>&1)" || REFERENCE_VALIDATION_EXIT=$?
  if [[ $REFERENCE_VALIDATION_EXIT -eq 0 || $REFERENCE_VALIDATION_EXIT -eq 2 ]]; then
    pass 'generated reference passes synthesis validation without critical failures'
  else
    fail 'generated reference has synthesis validation critical failures'
    if [[ -n "$REFERENCE_VALIDATION_OUTPUT" ]]; then
      printf '%s\n' "$REFERENCE_VALIDATION_OUTPUT" >&2
    fi
  fi
else
  fail 'generated reference could not be checked with validate-synthesis.sh'
fi

SKILL_VALIDATION_EXIT=0
SKILL_VALIDATION_OUTPUT=""
if [[ -f "$ROOT_DIR/skills/cogworks-learn/scripts/validate-skill.sh" && -d "$SKILL_PATH" ]]; then
  SKILL_VALIDATION_OUTPUT="$(bash "$ROOT_DIR/skills/cogworks-learn/scripts/validate-skill.sh" "$SKILL_PATH" 2>&1)" || SKILL_VALIDATION_EXIT=$?
  if [[ $SKILL_VALIDATION_EXIT -eq 0 || $SKILL_VALIDATION_EXIT -eq 2 ]]; then
    pass 'generated skill passes generated-skill validation without critical failures'
  else
    fail 'generated skill has generated-skill validation critical failures'
    if [[ -n "$SKILL_VALIDATION_OUTPUT" ]]; then
      printf '%s\n' "$SKILL_VALIDATION_OUTPUT" >&2
    fi
  fi
else
  fail 'generated skill could not be checked with validate-skill.sh'
fi

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "Sub-agent run validation failed with $FAILURES issue(s)." >&2
  exit 1
fi

echo ""
echo "Sub-agent run validation passed."
