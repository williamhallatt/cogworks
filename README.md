# cogworks

Two advisor skills for authoring agent skills.

- `cogworks-encode` — synthesis methodology: how to turn one or more sources
  on a topic into a decision-first knowledge base.
- `cogworks-learn` — skill-authoring doctrine: how to structure, package, and
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
Use cogworks-encode to help me synthesize these three OAuth docs into a single knowledge base.
Use cogworks-learn to help me write a SKILL.md for the incident-triage playbook I just drafted.
```

## License

[MIT](LICENSE)
