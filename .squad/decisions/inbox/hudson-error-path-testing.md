> **Triage verdict (2026-03-13):** ACCEPT — MEDIUM PRIORITY  
> 8 error scenarios well-scoped, ~30 hours total. All 8 currently untested (happy-path only today).  
> Phase 1 (fixtures) can start immediately. Phase 2 (validators) follows.  
> No outdated claims. Aligned with D-037 through D-042 specs.

# Error Path Testing Strategy for Agentic Engine

**Date:** 2026-03-07  
**Author:** Hudson (Test Engineer)  
**Status:** Design specification — ready for implementation  

## Executive Summary

The agentic engine's error handling is thoroughly specified in `agentic-runtime.md` but completely unvalidated by existing test fixtures. All current evidence (smoke runs, benchmarks) covers happy paths only. This document designs concrete test scenarios for contradictory sources, missing artifacts, stage failures, retries, fallbacks, and schema violations—each with fixture specifications, expected behaviors, and validation criteria.

---

## Current Test Gap Analysis

### What We Know Works (Happy Path)
- **Source intake:** Valid JSON input → properly classified sources
- **Synthesis:** Non-contradictory sources → unified guidance
- **Packaging:** Synthesis output → complete skill files with `[Source N]` citations
- **Deterministic validation:** Packaged skill → passes all checks (YAML, citations, structure)
- **Native subagent dispatch:** Available → stages run as separate agents with proper manifests
- **Single-agent fallback:** Native subagents unavailable → coordinator runs all stages inline

### What Is Completely Untested (Error Paths)
1. **Contradictory source inputs** — spec says "preserve contradictions" but synthesis engine untested on conflicting guidance
2. **Missing stage artifacts** — spec says "emit failed stage-status.json and stop" but no fixture demonstrates this
3. **Stage failure and retry** — spec defines retry policy but no scenario triggers a first-attempt failure followed by retry
4. **Fallback to single-agent** — dispatcher availability checks unvalidated; fallback behavior untested
5. **Invalid dispatch manifest** — spec defines schema, but malformed JSON or missing fields never tested
6. **Context overflow** — no fixtures large enough to trigger model context limits
7. **Tool availability degradation** — spec references tool scope per stage, but no scenario tests tool unavailability
8. **Blocking rule violations** — spec defines which stages must wait for which inputs; premature stage starts never tested

### Validation Tooling Status
- `test-agentic-contract.sh` — validates static contract (files exist, patterns present) ✓ Working
- `validate-agentic-run.sh` — validates artifact structure (schema, manifests, stage outputs) ✓ Working
- **Missing:** Tests that exercise error conditions during execution, not just artifact validation after

---

## Error Path Test Scenarios

### Scenario 1: Contradictory Source Inputs

**Risk:** Synthesizer receives conflicting guidance and resolves it silently, producing a skill that doesn't faithfully represent the source contradiction.

**Spec References:**
- agentic-runtime.md line 14: "conflicting guidance" triggers full-path escalation
- role-profiles.json (synthesizer): "preserve contradictions and entity boundaries"
- SKILL.md: Synthesis stage must record contradictions in `cdr-registry.md`

**Fixture Structure:**
```
tests/agentic-smoke/fixtures/contradictory-sources/
  source-1-auth-basic.md          # Basic HTTP auth approach
  source-2-oauth-only.md          # OAuth exclusive approach
  metadata.json                   # Minimal coordination metadata
```

**Source Content Examples:**

`source-1-auth-basic.md`:
```
# API Authentication: Basic HTTP Auth

Use HTTP Basic Authentication for the API endpoints.
Pass credentials via Authorization header with base64 encoding.
Supported endpoints: /auth/login, /auth/refresh

Example:
  Authorization: Basic base64(username:password)
```

`source-2-oauth-only.md`:
```
# API Authentication: OAuth 2.0 Flow

This API ONLY supports OAuth 2.0 Bearer tokens.
Basic auth is deprecated and will be removed.
Use the /oauth/token endpoint to obtain tokens.

Bearer tokens expire after 1 hour. Implement refresh logic.
```

**Expected Behavior (per spec):**
1. Source intake classifies both sources as valid, records contradiction signal
2. Synthesizer preserves both approaches in `synthesis.md` with explicit contradiction markers
3. CDR registry (`cdr-registry.md`) records the divergence:
   - Entity: "authentication method"
   - Source 1 guidance: "HTTP Basic Auth"
   - Source 2 guidance: "OAuth 2.0 only"
   - Contradiction type: "exclusive alternative" (not compatible)
4. Packaged skill includes both approaches with qualification:
   - Section for Basic Auth (with source reference)
   - Section for OAuth (with source reference)
   - Explicit note: "Choose one based on your API version"
5. Deterministic validation passes (both sections properly cited)

**Validation Criteria:**
1. `synthesis/cdr-registry.md` must contain:
   - Entity name: "authentication-method"
   - Contradiction marker or explicit "conflicting guidance" label
   - Both source references
2. `synthesis/synthesis.md` must include:
   - Both authentication approaches
   - Clear demarcation showing they are alternatives
   - `[Source 1]` and `[Source 2]` citations in appropriate sections
3. Generated skill MUST NOT:
   - Silently choose one over the other
   - Merge contradictory guidance into a single approach
4. Final-summary.md must mention contradiction was preserved

**Testing Approach:**
- Run with `--engine agentic`
- Validate artifact structure (existing tooling works)
- Manual review of synthesis.md to verify contradiction preservation
- NEW: Add schema check to `validate-agentic-run.sh` for `cdr-registry.md` contradiction records

---

### Scenario 2: Missing Source Inventory Output

**Risk:** Source intake fails to produce `source-inventory.json`, but synthesis stage starts anyway, receiving an incomplete input set.

**Spec References:**
- agentic-runtime.md line 129: "A stage may not start until all required inputs exist and are non-empty"
- agentic-runtime.md line 130: "If a required artifact is missing, emit a failed stage-status.json and stop"
- role-profiles.json (synthesizer): required input is "source inventory, source trust report"

**Fixture Structure:**
```
tests/agentic-smoke/fixtures/missing-inventory/
  source-1.md
  source-2.md
  metadata.json
```

**How to Trigger:**
This is a **staged failure scenario**. The intake-analyst agent must encounter a condition that causes it to write partial artifacts:
- `source-manifest.json` exists ✓
- `source-trust-report.md` exists ✓
- `source-inventory.json` missing ✗

**Possible causes:**
1. Invalid JSON in source files → intake can't parse → skips inventory generation
2. Disk space exhaustion → partial write of inventory
3. Tool unavailability → can't traverse source directory

**For testing purposes:** Directly create a `source-intake/` directory with missing inventory:
```
{run_root}/source-intake/
  stage-status.json          # MUST record "pass" (intake reported success) or "fail" (it detected missing inventory)
  source-manifest.json
  source-trust-report.md
  source-inventory.json      # MISSING
```

**Expected Behavior (per spec):**
1. If intake-analyst detects it cannot generate inventory, must write `stage-status.json` with `status: "fail"` → synthesis must not start
2. If intake-analyst writes `pass` but inventory is actually missing, coordinator MUST detect during blocking-rule check → stop before synthesis starts
3. Coordinator writes to run-manifest.json indicating failure chain
4. `final-summary.md` reports: "source-intake failed: required artifact source-inventory.json missing"

**Validation Criteria:**
1. Synthesis stage directory must NOT be created
2. Run manifest must have `completion_status: "failed"` or similar
3. Final summary must mention blocking rule violation
4. No skill output in {skill_path}

**Testing Approach:**
- Create fixture with artificially missing inventory
- Run with `--engine agentic`
- Validate that synthesis stage never starts (check stage-index.json for "stages_completed")
- NEW: Add explicit blocking-rule check in `validate-agentic-run.sh` for missing required artifacts

---

### Scenario 3: Stage Failure and Retry

**Risk:** A stage fails on first attempt, retry logic doesn't trigger, or retry fails with different error and coordinator doesn't surface it properly.

**Spec References:**
- agentic-runtime.md line 141-145: Retry policy (synthesis: 1, skill-packaging: 1, validator: 1)
- agentic-runtime.md line 146: "If the same stage fails twice for the same blocking reason, stop and surface the issue to the user"
- agentic-runtime.md line 132: "it must not rewrite a successful specialist-authored stage-status.json unless recording an explicit retry"

**Fixture Structure:**
Two-phase fixture demonstrating packaging failure + retry:

```
tests/agentic-smoke/fixtures/skill-packaging-retry/
  source-1.md
  metadata.json
  # Synthesis will succeed; packaging will fail on first try due to:
  # - Source guidance is unclear on whether skill should have multiple sections
  # - Packaging attempt 1: tries to create unsupported structure
  # - Packaging attempt 2: restructures appropriately
```

**Example Source:**
```
# Microservice Architecture Guidelines

Guide developers on when to split services.
Also, document the cost analysis process.
And explain observability requirements for distributed services.
Also provide CLI tool implementation guidance.

Include examples. Lots of examples.
```

(Intentionally vague/conflicting structure requests)

**Expected Behavior (per spec):**
1. **First attempt (packaging):**
   - Composer creates initial skill structure
   - Deterministic validation finds critical fidelity issue (contradictory section ordering, missing CDR references)
   - Writes `skill-packaging/stage-status.json` with `status: "fail"`, `retry_reason: "fidelity-concern"`
2. **Coordinator detects first failure:**
   - Reads stage-status.json, sees `status: "fail"` and retry_reason
   - Increments retry counter
   - Invokes packaging stage again with failure context
3. **Second attempt (packaging - retry):**
   - Composer receives context about first-attempt failure
   - Restructures to resolve fidelity issue
   - Validation passes
   - Writes `skill-packaging/stage-status.json` with `status: "pass"`, `is_retry: true`, `retry_count: 1`
4. **Coordinator continues:**
   - Observes retry succeeded, proceeds to deterministic-validation
   - Final run is successful

**Validation Criteria:**
1. Run manifest must record `retry_count` for skill-packaging stage: >= 1
2. stage-index.json must list skill-packaging twice (with timestamps showing second > first)
3. Second `stage-status.json` must have `is_retry: true`
4. Final-summary.md must mention "packaging stage retried once and succeeded"
5. Generated skill must be valid and complete

**Testing Approach:**
- This is a **staged execution scenario** requiring real agent dispatch
- Cannot be mocked with static fixtures
- Requires running full agentic pipeline on fixture with ambiguous synthesis output
- Validation: Run agentic engine, inspect run manifest for retry counters

---

### Scenario 4: Fallback to Single-Agent Execution

**Risk:** Native subagent capability check fails or is unavailable, but coordinator doesn't actually fall back—instead runs partial stages, producing incomplete dispatch manifest.

**Spec References:**
- agentic-runtime.md line 39: "execution_adapter = native-subagents when the current surface exposes a real subagent primitive"
- agentic-runtime.md line 40: "execution_adapter = single-agent-fallback otherwise"
- agentic-runtime.md line 62: Coordinator "must not claim native subagent execution when fallback was used"
- copilot-adapter.md: describes when Copilot CLI does NOT have native subagent capability

**Test Scenario Variants:**

#### Variant A: Copilot CLI Without Native Subagents (Expected Fallback)
**Condition:** Copilot CLI session without access to Task tool (or Task tool disabled)

**Expected Behavior (per spec):**
1. Coordinator detects that Task tool is unavailable
2. Sets `execution_adapter = "single-agent-fallback"` in run-manifest
3. Sets `specialist_profile_source = "inline-fallback"`
4. All 5 stages run within coordinator context (no dispatch)
5. Dispatch manifest is NOT created (only required for native-subagents)
6. Final summary records: `"execution_mode": "degraded-single-agent"`

**Validation Criteria:**
1. run-manifest.json must have:
   - `execution_adapter: "single-agent-fallback"`
   - `execution_mode: "degraded-single-agent"`
   - `specialist_profile_source: "inline-fallback"`
2. dispatch-manifest.json must NOT exist
3. All 5 stage directories exist with stage-status.json
4. Coordinator wrote all stage-status.json files (not specialists)
5. Final-summary.md must explicitly mention degraded execution mode

**Testing Approach:**
- Use existing smoke test fixture with Copilot CLI (no native subagents)
- Already partially covered by smoke runbook
- NEW: Add explicit fallback detection to `validate-agentic-run.sh` (check that dispatch-manifest.json absence is consistent with single-agent-fallback)

#### Variant B: Runtime Failure of Native Subagent Dispatch
**Condition:** Coordinator attempts to dispatch synthesizer as subagent, dispatch fails

**Potential Failure Modes:**
- Model unavailable (e.g., pinned model configured but not accessible)
- Subagent dispatch timeout
- Subagent crashes with no return artifact

**Expected Behavior (per spec):**
- Not explicitly specified in current agentic-runtime.md
- Implicit assumption: This should trigger fallback or explicit failure

**Testing Approach:**
- Advanced scenario; requires runtime instrumentation
- Document as "Future: Runtime Dispatch Failure"

---

### Scenario 5: Invalid Dispatch Manifest Schema

**Risk:** Dispatch manifest is written with missing fields, wrong types, or malformed JSON, but coordinator doesn't detect it and proceeds anyway.

**Spec References:**
- agentic-runtime.md line 226-242: Dispatch manifest must include specific fields per dispatch entry
- agentic-runtime.md line 262-268: Acceptance criteria require dispatch-manifest.json to map to canonical role profiles

**Fixture Structure:**
Create malformed dispatch manifests in a test fixture:

```
tests/agentic-smoke/fixtures/invalid-dispatch-manifest/
  source-1.md
  metadata.json
  # Pre-stage setup: coordinator will write dispatch-manifest.json with known issues
```

**Test Variants:**

**Variant A: Missing Fields**
```json
{
  "profile_source": "canonical-role-specs",
  "execution_surface": "claude-cli",
  "execution_adapter": "native-subagents",
  "dispatches": [
    {
      "stage": "source-intake",
      "role": "intake-analyst",
      // MISSING: profile_id, binding_type, binding_ref, model_policy, tool_scope, status
      "preferred_dispatch_mode": "background",
      "actual_dispatch_mode": "background"
    }
  ]
}
```

**Variant B: Wrong Type for model_policy**
```json
{
  "dispatches": [
    {
      // ... other fields ...
      "model_policy": ["pinned-haiku"],  // WRONG: should be string
      // ...
    }
  ]
}
```

**Variant C: Invalid binding_type**
```json
{
  "dispatches": [
    {
      "binding_type": "slack-webhook",  // WRONG: not in allowed list
      // ...
    }
  ]
}
```

**Expected Behavior (per spec):**
- Coordinator must validate dispatch manifest against schema
- If schema invalid, emit failed stage-status.json for the failing dispatch
- Stop the run with clear error message

**Validation Criteria:**
1. Coordinator must detect schema violations at startup (before any stages run)
2. Run manifest must record `completion_status: "failed"`
3. Error message must cite specific schema violation (e.g., "missing field: profile_id")
4. No skill output
5. Final-summary.md must mention dispatch manifest validation failure

**Testing Approach:**
- NEW: Create test script `tests/agentic-schemas/validate-dispatch-manifest.sh`
- Pre-create malformed manifests in fixtures
- Run validation only (not full pipeline)
- Verify schema validator rejects each malformed variant

---

### Scenario 6: Context Overflow (Sources Too Large)

**Risk:** Source set is so large that model cannot fit all sources in context window, coordinator doesn't validate source size before dispatch, and stages fail with cryptic "context limit exceeded" errors.

**Spec References:**
- copilot-adapter.md: "model policy inherit-session-model means model is determined at runtime"
- role-profiles.json (synthesizer): Context discipline mentions "focused on the source set" but no explicit limit

**Challenge:** This scenario is hard to test because:
1. Context limits depend on model family and version
2. Hard to predict exact token count of sources
3. May not be deterministic failure point

**Approach: Stub Implementation**

Create fixture with **artificially marked** large source:
```
tests/agentic-smoke/fixtures/context-overflow-stub/
  source-1-small.md           # ~5KB
  source-2-large.md           # ~500KB (generated filler or real documentation)
  metadata.json               # Includes flag: "test_context_overflow": true
```

**Expected Behavior (Aspirational):**
1. Coordinator pre-validates source size against model context limits
2. If projected tokens > 90% of context window, either:
   - Reject and ask user to split sources
   - OR switch to degraded fallback (single-agent with more budget)
3. If synthesis stage runs but hits context limit at runtime:
   - Stage fails with specific error: "model response truncated - context window exceeded"
   - Coordinator suggests splitting sources

**Validation Criteria:**
1. If coordinator rejects upfront: run manifest records `completion_status: "rejected"` with reason "context-window-exceeded"
2. If stage hits limit at runtime: synthesis stage-status.json records `status: "fail"`, `error_category: "context-limit"`
3. Error message is actionable (suggests splitting sources)

**Testing Approach:**
- Blocked until agentic engine has runtime context validation
- Document as "Future: Context Overflow Detection"
- Create stub fixture for manual testing

---

### Scenario 7: Tool Unavailability Degradation

**Risk:** A specialist stage requires a tool that's unavailable on the execution surface (e.g., synthesizer needs Grep but surface doesn't provide it), but the stage doesn't gracefully degrade—instead silently skips work.

**Spec References:**
- role-profiles.json: Each role defines tool_scope (e.g., intake-analyst: "Bash, Glob, Grep, Read, Edit, Write")
- copilot-adapter.md: Different surfaces support different tool sets
- agentic-runtime.md line 49: "the runtime must never claim a stronger adapter capability than the current surface actually provided"

**Test Scenario:**
Synthesizer requires Bash, but surface only provides Read/Write.

**Expected Behavior (per spec):**
1. Coordinator checks tool availability before dispatch
2. If required tool unavailable:
   - Either defer to fallback
   - OR fail explicitly with clear error message: "Cannot dispatch synthesizer: required tool Bash unavailable on copilot-cli"
3. Stage never starts with degraded capability
4. Run manifest records tool capability gap

**Validation Criteria:**
1. Stage-status.json must record tool check result
2. If tool unavailable and no fallback, run must fail with explicit error
3. Coordinator must not attempt stage with missing tools

**Testing Approach:**
- NEW: Create tool capability matrix in dispatch validation
- Check each role's required tools against surface capability
- Fail fast if gap detected
- Document in `validate-agentic-run.sh`

---

### Scenario 8: Blocking Rule Violations (Premature Stage Start)

**Risk:** A stage starts before required inputs are ready, coordinator doesn't enforce blocking rules, and stage fails with "input not found" errors.

**Spec References:**
- agentic-runtime.md line 129: "A stage may not start until all required inputs exist and are non-empty"
- Stage ownership table: Each stage lists required inputs (e.g., synthesis requires source-inventory, source-trust-report)

**Test Scenarios:**

**Variant A: Synthesis Starts Before Intake Completes**
- source-intake/ directory exists but stage-status.json missing
- Coordinator still dispatches synthesizer
- Synthesizer can't find required inputs

**Variant B: Packaging Starts Before Synthesis Complete**
- synthesis/ exists but only partial files (synthesis.md present, cdr-registry.md missing)
- Composer starts and fails

**Expected Behavior (per spec):**
1. Coordinator checks all required inputs before each stage dispatch
2. If required artifact missing or empty:
   - Do NOT start stage
   - Emit error: "Cannot start synthesis: required artifact source-inventory.json missing"
3. Stop the run

**Validation Criteria:**
1. All stage starts must be logged with "blocking rule check passed" message
2. If blocking rule violation detected, run fails before stage starts
3. Error message explicitly names missing artifact
4. stage-index.json only lists stages that actually ran

**Testing Approach:**
- NEW: Add blocking rule validator to `validate-agentic-run.sh`
- Check that each stage start is preceded by artifact existence check
- Verify stage sequence respects dependencies

---

## Test Infrastructure Requirements

### New Fixtures Needed

```
tests/agentic-smoke/fixtures/
  contradictory-sources/                    # Scenario 1
    source-1-auth-basic.md
    source-2-oauth-only.md
    metadata.json
  
  missing-inventory/                        # Scenario 2
    source-1.md
    source-2.md
    metadata.json
  
  skill-packaging-retry/                    # Scenario 3
    source-1-ambiguous.md
    metadata.json
  
  invalid-dispatch-manifest/                # Scenario 5
    malformed-dispatches.json               # Multiple variants
    valid-fixture.md
  
  context-overflow-stub/                    # Scenario 6
    source-1.md
    source-2-large.md                       # ~500KB placeholder
    metadata.json
```

### New Validation Scripts Needed

#### 1. `scripts/validate-error-paths.sh`
Orchestrates error path test suite:
- Runs each fixture through agentic engine
- Collects expected vs. actual behavior
- Reports pass/fail for each scenario

**Key checks:**
- Contradictions preserved in CDR registry
- Missing artifacts trigger stage blocking
- Retry counters recorded correctly
- Fallback properly detected and recorded
- Dispatch manifest validates against schema
- Tool availability checked before dispatch
- Blocking rules enforced

#### 2. `tests/framework/schemas/dispatch-manifest-schema.json`
JSON Schema for dispatch manifest validation:
- Defines required fields per dispatch entry
- Specifies allowed values (binding_type, model_policy, etc.)
- Validates structure

#### 3. Enhanced `validate-agentic-run.sh` Additions
- Add CDR registry validation (checks for contradiction records)
- Add blocking-rule retrospective check (verify stages didn't start early)
- Add tool capability matrix validation
- Add retry counter validation

### CI Gate Integration

Add error path validation to `tests/ci-gate-check.sh`:
```bash
# After happy-path smoke test
if [[ "$RUN_MODE" == "full" ]]; then
  bash scripts/validate-error-paths.sh --fixtures-dir tests/agentic-smoke/fixtures/
  ERROR_PATH_RESULT=$?
fi
```

---

## Implementation Roadmap

### Phase 1: Fixture Creation (Week 1)
1. Create contradictory-sources fixture
2. Create missing-inventory fixture  
3. Create skill-packaging-retry fixture
4. Create invalid-dispatch-manifest fixture variants
5. Create context-overflow-stub fixture

**Effort:** 4-6 hours  
**Outcome:** 5 fixture sets ready for integration

### Phase 2: Validator Enhancements (Week 1-2)
1. Implement CDR registry contradiction record validation
2. Add blocking-rule retrospective check
3. Add tool capability matrix validation
4. Implement dispatch manifest JSON schema validation
5. Add retry counter tracking

**Effort:** 8-12 hours  
**Outcome:** Enhanced `validate-agentic-run.sh` with error path checks

### Phase 3: Test Orchestration Script (Week 2)
1. Create `scripts/validate-error-paths.sh`
2. Integrate into CI gate
3. Generate test report (pass/fail + diagnostics)

**Effort:** 4-6 hours  
**Outcome:** Automated error path test suite

### Phase 4: Execution & Remediation (Week 2-3)
1. Run fixtures through agentic engine on Claude CLI
2. Run fixtures through agentic engine on Copilot CLI
3. Document any failures or spec gaps
4. Remediate coordinator/adapter if needed

**Effort:** 12-16 hours (depends on failures found)  
**Outcome:** Validated error handling across platforms

---

## Success Criteria

### Test Coverage
- ✅ Each of 8 error scenarios has a concrete fixture
- ✅ Each fixture exercises the error path (not happy path)
- ✅ Validation logic exists for each scenario's expected behavior
- ✅ Fixtures pass on both Claude CLI and Copilot CLI (or explicit platform limitation documented)

### Spec Validation
- ✅ Contradictions are preserved by synthesizer
- ✅ Missing required artifacts trigger stage blocking
- ✅ Retry policy works as specified (1 retry per stage)
- ✅ Fallback to single-agent properly detected and recorded
- ✅ Dispatch manifest schema enforced
- ✅ Tool availability checked before dispatch
- ✅ Blocking rules prevent early stage starts
- ✅ Final summaries accurately describe execution mode and failures

### Tooling
- ✅ `validate-error-paths.sh` runs all scenarios
- ✅ `validate-agentic-run.sh` detects error conditions retrospectively
- ✅ CI gate includes error path validation
- ✅ Test reports are actionable (specific fixture, specific check, specific failure)

---

## Known Limitations & Future Work

### Cannot Test (Requires Code Changes or Infrastructure)
1. **Runtime model unavailability** — requires stubbed model that fails at dispatch time
2. **Disk space exhaustion** — requires OS-level injection
3. **Subagent timeout** — requires instrumented timeout injection
4. **Network failures** — requires network fault injection

**Mitigation:** Document as aspirational tests; design framework for future instrumentation.

### Can Partially Test (Limited Evidence)
1. **Context overflow** — stub fixture available, but real limit depends on model version
2. **Tool unavailability** — surface capability detection can be tested, but not actual tool removal

**Mitigation:** Create stub fixtures for CI gate; plan live validation on multiple surfaces.

### Test Execution Mode
- Error path fixtures are designed for agentic engine with real agent dispatch
- Cannot be fully mocked with static fixtures
- Require running on Claude CLI or Copilot CLI (not locally)

**Mitigation:** Document as integration tests, not unit tests; expect 5-10 minutes per test suite run.

---

## Appendix: Mapping to Spec Sections

| Scenario | Spec Location | Section |
|----------|---------------|---------|
| Contradictory Sources | agentic-runtime.md line 14 | Operating Principle |
| Missing Artifacts | agentic-runtime.md line 129-130 | Blocking Rules |
| Retry Logic | agentic-runtime.md line 139-146 | Retry Policy |
| Fallback | agentic-runtime.md line 39-42 | Execution Model |
| Invalid Manifest | agentic-runtime.md line 226-242 | Dispatch Manifest Contract |
| Context Overflow | agentic-runtime.md (implicit) | Acceptance Criteria |
| Tool Unavailability | role-profiles.json (all roles) | Tool Scope |
| Blocking Rules | agentic-runtime.md line 129 | Blocking Rules |

---

## Conclusion

The agentic engine's specification is precise and operationally detailed. The error path testing strategy above closes the validation gap by:

1. **Concretizing abstract error cases** into executable fixtures
2. **Defining expected behavior** per spec for each scenario
3. **Specifying validation criteria** to confirm behavior matches spec
4. **Building automation** to prevent regression

Once implemented, this strategy will provide evidence that the engine's error handling is not aspirational but verified. It will also surface any gaps between the specification and the implementation, creating a feedback loop to improve both.

The implementation is phased to allow fixture creation and validator enhancement to proceed in parallel with integration testing.

---

## Document Approval

**Reviewed by:** Hudson (Test Engineer)  
**Ready for implementation:** Yes  
**Next step:** Assign fixtures and validators to implementation phase
