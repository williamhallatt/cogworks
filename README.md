# cogworks

Two advisor skills for authoring agent skills.

- `cogworks-encode` — synthesis methodology: how to turn one or more sources
  on a topic into a decision-first knowledge base.
- `cogworks-learn` — skill-authoring doctrine: how to structure, package, and
  validate an agent skill for its target runtime.

Both work standalone. Neither generates a finished artifact on its own; both
coach the human (or agent) doing the writing.

## Install

```bash
git clone https://github.com/williamhallatt/cogworks.git
cd cogworks
npx skills add ./skills/cogworks-encode ./skills/cogworks-learn
```

Requires Node.js 18+. See [INSTALL.md](INSTALL.md) for manual-copy
alternatives.

## Use

Invoke either skill by name in your agent.

```text
Use cogworks-encode to help me synthesize these three OAuth docs into a single knowledge base.
Use cogworks-learn to help me write a SKILL.md for the incident-triage playbook I just drafted.
```

## License

[MIT](LICENSE)
