# Deterministic Validation Report — api-auth-smoke

**Stage:** deterministic-validation  
**Run root:** `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/run-root/`  
**Skill path:** `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/skill-output/`  
**Overall result:** PASS

---

## Check 1 — SKILL.md exists, non-empty, valid YAML frontmatter

| Item | Result |
|---|---|
| File exists | ✅ |
| Non-empty | ✅ |
| `name:` field present | ✅ `api-auth-smoke` |
| `description:` field present | ✅ normative guidance on HTTP status codes and token handling |

## Check 2 — reference.md exists, non-empty

| Item | Result |
|---|---|
| File exists | ✅ |
| Non-empty | ✅ (98 lines) |

## Check 3 — metadata.json field coverage

| Field | Result |
|---|---|
| `skill_name` | ✅ `api-auth-smoke` |
| `engine_mode` | ✅ `agentic` |
| `execution_surface` | ✅ `copilot-cli` |
| `generated_at` | ✅ `2026-03-07T09:47:28Z` |

## Check 4 — Prior stage gate status

| Stage | Status |
|---|---|
| `source-intake` | ✅ pass |
| `synthesis` | ✅ pass |
| `skill-packaging` | ✅ pass |

---

## Blocking Failures

None.

---

## Warnings (advisory, carried from prior stages)

1. Coverage gap: no source guidance on refresh tokens, token revocation, multi-factor auth, or 429 interaction with auth retries (noted at source-intake and synthesis; non-blocking).

---

## Targeted Probe

Not required — all deterministic checks passed cleanly; no ambiguous findings warranted deeper inspection.
