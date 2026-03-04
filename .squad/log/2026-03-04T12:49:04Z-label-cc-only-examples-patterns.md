# Session Log: Label [Claude Code only] in examples.md and patterns.md

**Date:** 2026-03-04T12:49:04Z  
**Agent:** Lambert (general-purpose, background)  
**Commit:** f578d3d153bc0bdb7139583e641d2439b6f244ad on main

## Summary

Lambert labeled all Claude Code-specific fields in `skills/cogworks-learn/examples.md` and `skills/cogworks-learn/patterns.md` to match the `[Claude Code only]` labeling convention established in `reference.md` (TD-017/TD-018).

**Total locations labeled:** 18

### examples.md (8 examples)
- Example 2: context:fork field
- Example 4: agent:Explore reference
- Example 5: disable-model-invocation field
- Example 6: user-invocable field
- Example 7: argument-hint field
- Example 8: $ARGUMENTS/$N syntax
- Example 10: ${CLAUDE_SESSION_ID} variable
- Example 11: .claude/skills/ path

### patterns.md (6 patterns + 4 anti-patterns)
- Pattern 2: disable-model-invocation field
- Pattern 4: user-invocable field
- Pattern 6: context:fork field
- Pattern 7: agent:Explore reference
- Pattern 8: $ARGUMENTS/$N syntax
- Pattern 10: .claude/skills/ path
- Anti-Pattern 3: agent:Explore reference
- Anti-Pattern 4: ${CLAUDE_SESSION_ID} variable
- Anti-Pattern 7: context:fork field
- Anti-Pattern 8: disable-model-invocation field

## Status

✓ All 18 locations labeled  
✓ No examples removed or rewritten  
✓ Committed to main
