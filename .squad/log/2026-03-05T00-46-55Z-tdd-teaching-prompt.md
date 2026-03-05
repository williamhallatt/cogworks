# Session Log: TDD Teaching Prompt

**Date:** 2026-03-05T00:46:55Z
**Agents:** Ripley (Lead), Parker (Benchmark & Evaluation)
**Request:** "Team, I want to teach another squad how you approach TDD testing. Please review your process carefully and tell me the exact prompt I need to provide the other team to get them up to your standard."

## Session Overview

William requested cross-squad knowledge transfer documentation for cogworks TDD testing approach. Two agents spawned with complementary scopes:

- **Ripley:** Architectural philosophy synthesis (breaking circular ground truth, 3-layer framework, key decisions, coordination patterns)
- **Parker:** Quality measurement standards (external ground truth, cross-model independence, baseline comparison, statistical validity)
- **Hudson:** Listed as completed in spawn manifest but produced no deliverables

## Deliverables

### Ripley: TDD Philosophy Architecture
- **File:** `.squad/decisions/inbox/ripley-tdd-philosophy-synthesis.md`
- **Focus:** Architectural principles, framework structure, coordination patterns
- **Key insight:** Circular ground truth is epistemological failure — team deleted working tests rather than validate consistency instead of correctness

### Parker: TDD Quality Standards
- **File:** `.squad/agents/parker/tdd-quality-standards.md`
- **File:** `.squad/decisions/inbox/parker-tdd-quality-standards.md`
- **Focus:** Quality definition, cross-model independence, baseline comparison, statistical validity, adversarial testing
- **Key insight:** If Model A generated, Model A cannot be sole judge — hard rule for non-circular validation

### Hudson: No Deliverables Found
- Spawn manifest indicates completion of "TDD workflow documentation"
- No decision inbox file created
- No agent directory exists (`.squad/agents/hudson/` missing)

## Core Principles Synthesized

1. **Circular ground truth problem** — LLM-generated traces used as ground truth validate consistency, not correctness
2. **Layer 1 deterministic checks** — Mechanical validation, incorruptible, ~1 second runtime, minimum gate for all skill changes
3. **Layer 2 behavioral evaluation** — Blocked pending non-circular ground truth definition (D-022/D-023)
4. **Layer 3 pipeline benchmark** — Offline defaults, explicit real-mode opt-in, winner criterion under audit
5. **Cross-model independence** — Different models for generation vs evaluation, or human ground truth with inter-rater reliability
6. **Baseline comparison** — Agent WITH skill vs WITHOUT skill behavioral delta with statistical significance
7. **Documentation ownership** — Post-decision audit protocol (D-025): no architectural decision closes until Scribe audits stale references

## Architectural Decisions Referenced

- **D-022:** Deleted all behavioral traces (circular ground truth problem)
- **D-023:** Removed capture scripts (perpetuated circular validation)
- **D-021:** CI gate enforcement (quality gate must fail when traces missing)
- **D-024:** Delimiter injection preprocessing (deterministic protection)
- **D-025:** Documentation ownership protocol (stale reference cleanup)
- **D-026:** Delimiter preprocessing implementation (mechanical boundary protection)

## External Team Handoff

William can provide two documents:
1. **Ripley's synthesis** — Architectural overview and coordination patterns
2. **Parker's standards** — Quality measurement criteria, statistical validity requirements, 18 self-assessment questions

Together these cover:
- Why the team chose correctness over convenience
- How to break circular validation
- What makes a test "good" vs "working"
- Statistical standards for claiming quality improvements
- Anti-patterns to avoid (with team's own failures as examples)

## Next Steps

- Scribe merges decision inbox → `decisions.md`
- Scribe updates Ripley and Parker `history.md` files
- Scribe commits all `.squad/` updates
- William determines if Hudson's work exists elsewhere or was not completed
