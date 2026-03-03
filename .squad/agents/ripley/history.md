# history.md

## Learnings

- **Quality calibration vs capability gating are distinct concerns.** Model capability requirements (Sonnet-class or above) address whether the model *can* synthesize; quality calibration addresses whether it *does* synthesize with appropriate depth. The anti-superficiality gate added to Self-Verification targets the latter — it forces the model to introspect on its own output before declaring completion. The key design insight: a model that finds zero tensions between multiple sources has almost certainly under-analyzed, so "all clear" is the red flag, not the green light.

**2026-03-03 — Team coordination notes**

- Dallas implemented pipeline guards (M5, M11, D3, D7) addressing overwrite protection, cross-source synthesis validation, CDR completeness, and convergence risk.
- Ash implemented security guards (D2, D1, D1) addressing escalation boundaries, stale skill detection, and intent clarification.
- Hudson added generalization probe and edge case tests (D8) plus pre-release CI gate to catch circular verification failures.
- Lambert documented Codex behavioral capture and skills-lock schema; recommended AGENTS/CLAUDE dedup approach.
