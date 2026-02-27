# Plan: Fix R1 actionability gaps (templates) — 2026-02-27

## Goal
Change `_sources/tdd/chatgpt-deep-research-tdd.md` (ChatGPT Deep Research prompt) to address **only**:
- Missing worked examples / test templates
- Missing depth on concrete test-writing mechanics (naming, AAA, fixtures)

Decision: **platform-agnostic pseudocode templates** (copy/paste-ready skeletons with placeholders).

## Minimal prompt edits
1) **Scope boundaries**
- Add test-writing mechanics + short pseudocode templates to *In-scope*.
- Avoid long language-specific tutorials, but permit short templates.

2) **Source selection guidance**
- Require at least one source each that explicitly covers:
  - test naming / actionable failures
  - AAA (Arrange–Act–Assert) structure
  - fixtures / isolation / test data management

3) **Synthesis requirements (within existing headings only)**
- Under **Decision Rules**: require `Template:` fenced code blocks for at least 3 mechanics-related rules.
- Under **Quick Reference**: require 3 `Template:` fenced code blocks after the lookup table:
  1) naming template
  2) AAA skeleton
  3) fixture/setup pattern

## Files changed
- `_sources/tdd/chatgpt-deep-research-tdd.md`
