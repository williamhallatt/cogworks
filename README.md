# cogworks

Two advisor skills for authoring agent skills.

- `cg-distill` — synthesis methodology: how to turn one or more sources
  on a topic into a decision-first knowledge base.
- `cg-build` — skill-authoring doctrine: how to structure, package, and
  validate an agent skill for its target runtime.

Both work standalone.

## Install

Install with [Vercel Skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add williamhallatt/cogworks
```

## Use

Invoke either skill by name in your agent.

```text
Use cg-distill to help me synthesize these three OAuth docs into a single knowledge base.
Use cg-build to help me write a SKILL.md for the incident-triage playbook I just drafted.
```

## License

[MIT](LICENSE)
