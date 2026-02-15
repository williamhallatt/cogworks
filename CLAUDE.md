# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Related Documentation

- [README.md](README.md) - Project overview and quick start
- [TESTING.md](TESTING.md) - Testing guidelines and framework
- [RELEASES.md](RELEASES.md) - Release process and troubleshooting
- [INSTALL.md](INSTALL.md) - End-user installation instructions
- [ROADMAP.md](ROADMAP.md) - Future feature planning

## Platform Limitations

- **Linux (Ubuntu) only** - Hardcoded paths throughout (see ROADMAP.md)
- **No authenticated sources** - WebFetch cannot access content behind logins
- **Context window ceiling** - All sources must fit in Claude's context during synthesis

## Known Issues

**Soft invocation block:** The cogworks agent description attempts to prevent implicit invocation by requesting explicit `@cogworks` commands. If you observe unintended invocations (the agent fires when it shouldn't), this is a known limitation - the prompt should be strengthened.

## Quality Requirements

Generated skills must satisfy:

- **Source fidelity** - Accurately represents source material without fabrication
- **Self-sufficiency** - Works standalone without external context
- **Completeness** - Covers stated scope thoroughly
- **Specificity** - Provides actionable patterns with when/why/how context
- **No overlap** - Doesn't duplicate existing built-in knowledge

See also: [TESTING.md](TESTING.md) for quality validation guidelines.

## Non-Obvious Behaviors

- Both `cogworks-encode` and `cogworks-learn` skills are required dependencies for the cogworks agent
- Supporting files (patterns.md, examples.md) are only created when they contain substantive content (3+ distinct entries); otherwise, content is folded into reference.md
- The cogworks-learn skill's validation process checks quality requirements before confirming success
