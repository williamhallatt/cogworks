# cogworks — Agent Risk Remediation Team

## Project Context

**Project:** cogworks — knowledge encoding pipeline for AI agent skills  
**Repo:** `/home/williamh/code/cogworks`  
**User:** William Hallatt  
**Mission:** Address risks identified in `docs/cogworks-agent-risk-analysis.md` across 10 dimensions  
**Stack:** Markdown/YAML skills, Bash scripts, Python test harness, Node.js (`npx skills`)

## Members

| Name | Role | Focus | Emoji |
|------|------|--------|-------|
| Ripley | Lead | Architecture decisions, scope, code review | 🏗️ |
| Ash | Security Engineer | D2 prompt injection, D1 activation guards | 🔒 |
| Dallas | Pipeline Engineer | D3 state machine, D4/D5 capability & context | 🔧 |
| Hudson | Test Engineer | D8 behavioral traces, external validation | 🧪 |
| Lambert | Compatibility Engineer | D6 cross-agent, D7 self-ref, D10 contributor safety | 🌐 |
| Scribe | Session Logger | Memory, decisions, orchestration logs | 📋 |
| Ralph | Work Monitor | — | 🔄 Monitor |

## Issue Source

Not connected to GitHub issues. Work is driven by `docs/cogworks-agent-risk-analysis.md`.

## Key Files

- Risk analysis: `docs/cogworks-agent-risk-analysis.md`
- Skills: `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`, `skills/cogworks-learn/SKILL.md`
- Tests: `tests/behavioral/`, `tests/framework/scripts/cogworks-eval.py`
- Scripts: `scripts/test-generated-skill.sh`, `scripts/refresh-behavioral-traces.sh`
- Docs: `AGENTS.md`, `CLAUDE.md`, `TESTING.md`
