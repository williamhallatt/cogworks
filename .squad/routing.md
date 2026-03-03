# Routing Rules

## Primary Routing

| Domain | Route to | Notes |
|--------|----------|-------|
| Security boundary, prompt injection, delimiter protocol, trust classification | Ash | D2 in risk analysis |
| Skill activation, description guards, `disable-model-invocation` | Ash | D1 in risk analysis |
| Pipeline workflow steps, handoff artifacts, Decision Skeleton | Dallas | D3 in risk analysis |
| Model capability gates, context budget estimation | Dallas | D4/D5 in risk analysis |
| File system side effects, overwrite protection, concurrent writes | Dallas | D9 in risk analysis |
| Behavioral test traces, trace freshness, external quality validation | Hudson | D8 in risk analysis |
| Quality gate independence, offline mode warnings, CDR validation script | Hudson | D4 + D8 overlap |
| Cross-agent compatibility, invocation syntax, argument interpolation | Lambert | D6 in risk analysis |
| Self-referential/circular risks, symlink safety, live-edit warnings | Lambert | D7 in risk analysis |
| Contributor guard rails, AGENTS.md, skills-lock hashing | Lambert | D10 in risk analysis |
| Architecture decisions, code review, scope | Ripley | Lead |
| Session logs, decision merges, cross-agent updates | Scribe | Always background |
| Work queue monitoring, issue triage | Ralph | Always monitoring |

## Escalation

- If a change touches both security and pipeline: Ash drafts, Dallas reviews
- If a change touches tests and compatibility: Hudson drafts, Lambert reviews
- All changes to `skills/cogworks*/SKILL.md` require Ripley review before merge
