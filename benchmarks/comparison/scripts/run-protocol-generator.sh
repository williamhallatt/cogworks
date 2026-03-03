#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <cogworks|generator-a|generator-b> <task_id> <sources_path> <skill_out_dir>" >&2
}

if [[ $# -ne 4 ]]; then
  usage
  exit 2
fi

pipeline="$1"
task_id="$2"
sources_path="$3"
skill_out_dir="$4"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

mkdir -p "$skill_out_dir"

if [[ "$pipeline" == "cogworks" ]]; then
  read -r -d '' prompt <<EOF || true
You are running the cogworks pipeline benchmark.
Task id: $task_id
Sources path: $sources_path
Output skill directory: $skill_out_dir

Follow methodology in:
- skills/cogworks/SKILL.md
- skills/cogworks-encode/SKILL.md
- skills/cogworks-learn/SKILL.md

Do a non-interactive run:
1) read all source files under $sources_path
2) synthesize decision-first guidance
3) generate skill files into $skill_out_dir
4) required files: SKILL.md and reference.md
5) include valid frontmatter with name/description
6) do not ask questions; make reasonable defaults
7) stop after files are written
EOF
elif [[ "$pipeline" == "generator-a" ]]; then
  read -r -d '' prompt <<EOF || true
You are running generator-a benchmark protocol.
Task id: $task_id
Sources path: $sources_path
Output skill directory: $skill_out_dir

Follow repository guidance in:
- benchmarks/comparison/comparators/generator-a/skill-creator/SKILL.md
- benchmarks/comparison/comparators/generator-a/skill-creator/references/schemas.md

Non-interactive adaptation:
1) derive skill intent from sources under $sources_path
2) create a new skill artifact at $skill_out_dir
3) required files: SKILL.md and reference.md
4) apply generator-a style: strong trigger description + clear workflow instructions
5) do not run iterative UI/reviewer loops; produce best single-pass artifact
6) do not ask questions; use defaults and finish
EOF
elif [[ "$pipeline" == "generator-b" ]]; then
  read -r -d '' prompt <<EOF || true
You are running generator-b benchmark protocol.
Task id: $task_id
Sources path: $sources_path
Output skill directory: $skill_out_dir

Follow process docs:
- benchmarks/comparison/comparators/generator-b/skill-factory/docs/create_new_skill-process.md
- benchmarks/comparison/comparators/generator-b/skill-factory/docs/knowledge/anthropic-skill-docs/best-practices.md
- benchmarks/comparison/comparators/generator-b/skill-factory/docs/knowledge/anthropic-skill-docs/skills.md

Non-interactive adaptation:
1) read sources under $sources_path
2) create one skill directly in $skill_out_dir
3) required files: SKILL.md and reference.md
4) apply skill-factory style (progressive disclosure, concise discovery description)
5) no interactive Q&A; choose sensible defaults
6) finish once files are written
EOF
else
  echo "Unknown pipeline: $pipeline" >&2
  exit 2
fi

printf "%s\n" "$prompt" | codex exec -s workspace-write -C "$root_dir" -
