#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ROOT=""
SKILL_PATH=""
EXPECT_SURFACE=""
EXPECT_ADAPTER=""
EXPECT_MODE="agentic"
FINAL_SUMMARY_PATH=""
STAGE_INDEX_PATH=""
DISPATCH_MANIFEST_PATH=""

usage() {
  cat <<'USAGE'
Usage: scripts/validate-agentic-run.sh --run-root <path> --skill-path <path> [--expect-surface <name>] [--expect-adapter <name>] [--expect-mode <mode>]

Validates the artifact contract for a live cogworks agentic run.
USAGE
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
    --expect-adapter)
      EXPECT_ADAPTER="$2"
      shift 2
      ;;
    --expect-mode)
      EXPECT_MODE="$2"
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

failures=0

pass() {
  echo "PASS  $1"
}

fail() {
  echo "FAIL  $1" >&2
  failures=$((failures + 1))
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

resolve_dispatch_manifest() {
  local path="$RUN_ROOT/dispatch-manifest.json"
  if [[ -f "$path" ]]; then
    DISPATCH_MANIFEST_PATH="$path"
    pass "dispatch-manifest.json exists"
    return 0
  fi
  fail "dispatch-manifest.json exists"
}

normalized_surface() {
  jq -r '
    if .execution_surface == "claude-cli" or .execution_surface == "copilot-cli" then
      .execution_surface
    elif .execution_adapter == "claude-subagents" then
      "claude-cli"
    else
      "unknown"
    end
  ' "$RUN_ROOT/run-manifest.json"
}

normalized_adapter() {
  jq -r '
    if .execution_adapter == "native-subagents" or .execution_adapter == "single-agent-fallback" then
      .execution_adapter
    elif .execution_adapter == "claude-subagents" then
      "native-subagents"
    else
      "unknown"
    end
  ' "$RUN_ROOT/run-manifest.json"
}

manifest_uses_new_schema() {
  jq -e '
    (.execution_surface == "claude-cli" or .execution_surface == "copilot-cli") and
    (.execution_adapter == "native-subagents" or .execution_adapter == "single-agent-fallback") and
    (
      (.execution_adapter == "native-subagents" and .execution_mode == "subagent" and .specialist_profile_source == "canonical-role-specs") or
      (.execution_adapter == "single-agent-fallback" and .execution_mode == "degraded-single-agent" and .specialist_profile_source == "inline-fallback")
    )
  ' "$RUN_ROOT/run-manifest.json" >/dev/null
}

manifest_uses_old_claude_schema() {
  jq -e '
    (
      (.execution_adapter == "claude-subagents" and .execution_mode == "subagent" and .specialist_profile_source == "repo-agent-files") or
      (.execution_adapter == "single-agent-fallback" and .execution_mode == "degraded-single-agent" and .specialist_profile_source == "inline-fallback")
    )
  ' "$RUN_ROOT/run-manifest.json" >/dev/null
}

check_skill_packaging_output() {
  local draft_path="$RUN_ROOT/skill-packaging/skill-draft"
  if [[ -d "$draft_path" ]] && find "$draft_path" -mindepth 1 -print -quit | grep -q .; then
    pass "skill-packaging outputs exist via non-empty skill-draft"
    return 0
  fi

  if [[ -d "$SKILL_PATH" ]] && find "$SKILL_PATH" -mindepth 1 -print -quit | grep -q .; then
    pass "skill-packaging outputs exist via final skill directory"
    return 0
  fi

  fail "skill-packaging outputs missing both skill-draft and final skill files"
}

validate_new_claude_dispatch_record() {
  local stage="$1"
  local role="$2"
  local profile_id="$3"
  local binding_ref="$4"
  if jq -e \
    --arg stage "$stage" \
    --arg role "$role" \
    --arg profile_id "$profile_id" \
    --arg binding_ref "$binding_ref" \
    '
    any(.dispatches[]?;
      .stage == $stage and
      .role == $role and
      .profile_id == $profile_id and
      .binding_type == "claude-agent-file" and
      ((.binding_ref | type) == "string") and
      (.binding_ref | contains($binding_ref)) and
      ((.model_policy | type) == "string") and
      (.model_policy | startswith("pinned-")) and
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

validate_new_copilot_dispatch_record() {
  local stage="$1"
  local role="$2"
  local profile_id="$3"
  local binding_ref="$4"
  if jq -e \
    --arg stage "$stage" \
    --arg role "$role" \
    --arg profile_id "$profile_id" \
    --arg binding_ref "$binding_ref" \
    '
    any(.dispatches[]?;
      .stage == $stage and
      .role == $role and
      .profile_id == $profile_id and
      .binding_type == "copilot-inline-prompt" and
      ((.binding_ref | type) == "string") and
      (.binding_ref == $binding_ref) and
      (.model_policy == "inherit-session-model") and
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

validate_old_claude_dispatch_record() {
  local stage="$1"
  local role="$2"
  local agent_name="$3"
  local agent_file="$4"
  if jq -e \
    --arg stage "$stage" \
    --arg role "$role" \
    --arg agent_name "$agent_name" \
    --arg agent_file "$agent_file" \
    '
    any(.dispatches[]?;
      .stage == $stage and
      .role == $role and
      .agent_name == $agent_name and
      ((.agent_path | type) == "string") and
      (.agent_path | contains($agent_file)) and
      ((.preferred_model | type) == "string" and (.preferred_model | length > 0)) and
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

check_dir "$RUN_ROOT" "run root exists"
check_nonempty_file "$RUN_ROOT/run-manifest.json" "run-manifest.json exists and is non-empty"
resolve_stage_index
resolve_final_summary

if [[ -n "$STAGE_INDEX_PATH" ]]; then
  check_nonempty_file "$STAGE_INDEX_PATH" "stage-index.json is non-empty"
fi

if manifest_uses_new_schema || manifest_uses_old_claude_schema; then
  pass 'run-manifest.json has required engine metadata'
else
  fail 'run-manifest.json missing required engine metadata'
fi

if jq -e --arg mode "$EXPECT_MODE" '.engine_mode == $mode and (.run_id | length > 0)' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  pass 'run-manifest.json records engine_mode and run_id'
else
  fail 'run-manifest.json missing engine_mode or run_id'
fi

if jq -e '.stages_expected | arrays and length > 0' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  pass 'run-manifest.json records stages_expected'
else
  fail 'run-manifest.json missing stages_expected'
fi

if jq -e '.agentic_path == "agentic-short-path" or .agentic_path == "agentic-full-path"' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  pass 'run-manifest.json records agentic_path'
else
  fail 'run-manifest.json missing valid agentic_path'
fi

if manifest_uses_new_schema && jq -e '.execution_surface == "claude-cli" or .execution_surface == "copilot-cli"' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  pass 'run-manifest.json records execution_surface'
elif manifest_uses_old_claude_schema; then
  pass 'run-manifest.json records execution_surface via old Claude schema'
else
  fail 'run-manifest.json missing valid execution_surface'
fi

if jq -e '.specialist_profile_source == "canonical-role-specs" or .specialist_profile_source == "inline-fallback" or .specialist_profile_source == "repo-agent-files"' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  pass 'run-manifest.json records specialist_profile_source'
else
  fail 'run-manifest.json missing valid specialist_profile_source'
fi

NORMALIZED_SURFACE="$(normalized_surface)"
NORMALIZED_ADAPTER="$(normalized_adapter)"

if [[ -n "$EXPECT_SURFACE" ]]; then
  if [[ "$NORMALIZED_SURFACE" == "$EXPECT_SURFACE" ]]; then
    pass "run-manifest.json execution_surface == $EXPECT_SURFACE"
  else
    fail "run-manifest.json execution_surface != $EXPECT_SURFACE"
  fi
fi

if [[ -n "$EXPECT_ADAPTER" ]]; then
  if [[ "$NORMALIZED_ADAPTER" == "$EXPECT_ADAPTER" ]]; then
    pass "run-manifest.json execution_adapter == $EXPECT_ADAPTER"
  else
    fail "run-manifest.json execution_adapter != $EXPECT_ADAPTER"
  fi
fi

if [[ -n "$FINAL_SUMMARY_PATH" ]] && jq -e '.execution_mode == "degraded-single-agent"' "$RUN_ROOT/run-manifest.json" >/dev/null; then
  if rg -q --ignore-case --fixed-strings -- 'degraded-single-agent' "$FINAL_SUMMARY_PATH" || \
     rg -q --ignore-case 'degraded[ -]single[ -]agent' "$FINAL_SUMMARY_PATH"; then
    pass 'final summary names degraded execution explicitly'
  else
    fail 'final summary does not name degraded execution explicitly'
  fi
fi

if [[ "$NORMALIZED_ADAPTER" == "native-subagents" ]]; then
  resolve_dispatch_manifest
  if [[ -n "$DISPATCH_MANIFEST_PATH" ]]; then
    check_nonempty_file "$DISPATCH_MANIFEST_PATH" "dispatch-manifest.json is non-empty"
  fi

  if manifest_uses_new_schema; then
    if jq -e '
      .profile_source == "canonical-role-specs" and
      (.execution_surface == "claude-cli" or .execution_surface == "copilot-cli") and
      .execution_adapter == "native-subagents" and
      (.dispatches | arrays and length >= 4)
    ' "$DISPATCH_MANIFEST_PATH" >/dev/null; then
      pass 'dispatch-manifest.json has required top-level fields'
    else
      fail 'dispatch-manifest.json missing required top-level fields'
    fi

    if [[ "$NORMALIZED_SURFACE" == "claude-cli" ]]; then
      validate_new_claude_dispatch_record "source-intake" "intake-analyst" "intake-analyst" ".claude/agents/cogworks-intake-analyst.md"
      validate_new_claude_dispatch_record "synthesis" "synthesizer" "synthesizer" ".claude/agents/cogworks-synthesizer.md"
      validate_new_claude_dispatch_record "skill-packaging" "composer" "composer" ".claude/agents/cogworks-composer.md"
      validate_new_claude_dispatch_record "deterministic-validation" "validator" "validator" ".claude/agents/cogworks-validator.md"
    elif [[ "$NORMALIZED_SURFACE" == "copilot-cli" ]]; then
      validate_new_copilot_dispatch_record "source-intake" "intake-analyst" "intake-analyst" "skills/cogworks/role-profiles.json#intake-analyst"
      validate_new_copilot_dispatch_record "synthesis" "synthesizer" "synthesizer" "skills/cogworks/role-profiles.json#synthesizer"
      validate_new_copilot_dispatch_record "skill-packaging" "composer" "composer" "skills/cogworks/role-profiles.json#composer"
      validate_new_copilot_dispatch_record "deterministic-validation" "validator" "validator" "skills/cogworks/role-profiles.json#validator"
    fi
  else
    if jq -e '
      .profile_source == "repo-agent-files" and
      .execution_adapter == "claude-subagents" and
      (.dispatches | arrays and length >= 4)
    ' "$DISPATCH_MANIFEST_PATH" >/dev/null; then
      pass 'dispatch-manifest.json has required top-level fields'
    else
      fail 'dispatch-manifest.json missing required top-level fields'
    fi

    validate_old_claude_dispatch_record "source-intake" "intake-analyst" "cogworks-intake-analyst" ".claude/agents/cogworks-intake-analyst.md"
    validate_old_claude_dispatch_record "synthesis" "synthesizer" "cogworks-synthesizer" ".claude/agents/cogworks-synthesizer.md"
    validate_old_claude_dispatch_record "skill-packaging" "composer" "cogworks-composer" ".claude/agents/cogworks-composer.md"
    validate_old_claude_dispatch_record "deterministic-validation" "validator" "cogworks-validator" ".claude/agents/cogworks-validator.md"
  fi
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
  if jq -e '.gate_passed == true and ((.gate_version | type) == "string") and ((.sources | type) == "array") and ((.sources | length) > 0)' "$RUN_ROOT/source-intake/source-trust-gate.json" >/dev/null; then
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
check_skill_packaging_output

check_nonempty_file "$RUN_ROOT/deterministic-validation/deterministic-gate-report.json" "deterministic-validation/deterministic-gate-report.json exists and is non-empty"
check_nonempty_file "$RUN_ROOT/deterministic-validation/final-gate-report.json" "deterministic-validation/final-gate-report.json exists and is non-empty"

check_dir "$SKILL_PATH" "generated skill directory exists"
check_nonempty_file "$SKILL_PATH/SKILL.md" "generated skill SKILL.md exists and is non-empty"
check_nonempty_file "$SKILL_PATH/reference.md" "generated skill reference.md exists and is non-empty"
check_nonempty_file "$SKILL_PATH/metadata.json" "generated skill metadata.json exists and is non-empty"

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
elif [[ -f "$ROOT_DIR/tests/framework/graders/deterministic-checks.sh" && -d "$SKILL_PATH" ]]; then
  SKILL_VALIDATION_OUTPUT="$(bash "$ROOT_DIR/tests/framework/graders/deterministic-checks.sh" "$SKILL_PATH" 2>&1)" || SKILL_VALIDATION_EXIT=$?
  if [[ $SKILL_VALIDATION_EXIT -eq 0 || $SKILL_VALIDATION_EXIT -eq 2 ]]; then
    pass 'generated skill passes Layer 1 without critical failures'
  else
    fail 'generated skill has Layer 1 critical failures'
    if [[ -n "$SKILL_VALIDATION_OUTPUT" ]]; then
      printf '%s\n' "$SKILL_VALIDATION_OUTPUT" >&2
    fi
  fi
fi

if [[ $failures -gt 0 ]]; then
  echo ""
  echo "Agentic run validation failed with $failures issue(s)." >&2
  exit 1
fi

echo ""
echo "Agentic run validation passed."
