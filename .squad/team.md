# cogworks — Agent Risk Remediation Team

## Project Context

**Project:** cogworks — knowledge encoding pipeline for AI agent skills  
**Repo:** `/home/williamh/code/cogworks`  
**User:** William Hallatt  
**Mission:** Maintain and harden the cogworks knowledge encoding pipeline  
**Stack:** Markdown/YAML skills, Bash scripts, Python test harness, Node.js (`npx skills`)

## Members

| Name | Role | Focus | Emoji |
|------|------|--------|-------|
| Ripley | Lead | Architecture decisions, scope, code review | 🏗️ |
| Ash | Security Engineer | Security boundary, prompt injection, activation guards | 🔒 |
| Dallas | Pipeline Engineer | Pipeline workflow, handoff artifacts, file system guards | 🔧 |
| Hudson | Test Engineer | Behavioral traces, CI gates, quality validation | 🧪 |
| Lambert | Compatibility Engineer | Cross-agent compatibility, contributor safety, self-ref risks | 🌐 |
| Kane | Product Manager | Roadmap, PRD authoring, backlog, AI skills UX | 📦 |
| Parker | Benchmark & Evaluation Engineer | Skill quality definition, cross-model eval, external validation | 📐 |
| Scribe | Session Logger | Memory, decisions, orchestration logs | 📋 |
| Ralph | Work Monitor | — | 🔄 Monitor |

## Issue Source

Connected. Work tracked via GitHub issues with `squad:*` labels.  
See: `https://github.com/williamhallatt/cogworks/issues`

## Key Files

- Risk analysis: `docs/cogworks-agent-risk-analysis.md`
- Compatibility matrix: `docs/cross-agent-compatibility.md`
- Skills: `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`, `skills/cogworks-learn/SKILL.md`
- Tests: `tests/behavioral/`, `tests/framework/scripts/cogworks-eval.py`
- Scripts: `scripts/test-generated-skill.sh`, `scripts/refresh-behavioral-traces.sh`
- Docs: `AGENTS.md`, `CLAUDE.md`, `TESTING.md`
