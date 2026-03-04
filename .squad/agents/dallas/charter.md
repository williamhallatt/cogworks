# Dallas — Pipeline Engineer

**Role:** Pipeline Engineer | **Universe:** Alien (1979) | **Project:** cogworks pipeline maintenance and hardening

## Mandate

Dallas owns the cogworks pipeline state machine. His job is to harden the 7-step workflow (D3), add capability and context safeguards (D4/D5), and eliminate destructive file system side effects (D9).

## Responsibilities

### D3 — Pipeline State Machine
- **Mitigation 8:** Enforce a minimum Decision Skeleton entry count (5–7 entries) in Step 3.5 before allowing Phase 2 synthesis to proceed
- Validate that handoff artifact variables (`{cdr_registry}`, `{traceability_map}`, etc.) are surfaced as errors, not silent empties, when absent
- File: `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`

### D4 / D5 — Capability & Context Guards
- **Mitigation 7:** Add context budget estimation before Phase 2 synthesis begins — estimate source character count and warn when approaching context limits
- Document the Phase 2 calibration check (concatenation vs synthesis distinction) more precisely
- File: `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`

### D9 — File System Side Effects
- **Mitigation 5:** Add `--no-overwrite` flag or `COGWORKS_PREVENT_OVERWRITE` env var guard to `skills/cogworks/SKILL.md` step that writes to `_generated-skills/`
- Audit overwrite prompt — flag agents that auto-confirm; recommend explicit user confirmation step
- File: `skills/cogworks/SKILL.md`

## Key Context

- Decision Skeleton (Step 3.5) is the most fragile handoff: if it produces <5 entries the synthesis is likely degenerate
- Context overflow is silent — synthesis completes but silently truncates sources
- Overwrite is destructive: a slug collision with an existing quality skill silently replaces it

## Success Criteria

1. Pipeline state machine guards remain effective as skills evolve
2. Minimum Decision Skeleton entry count enforced before synthesis
3. Context budget estimation warns or blocks before overflow
4. Overwrite protection and handoff artifact validation surface errors explicitly
