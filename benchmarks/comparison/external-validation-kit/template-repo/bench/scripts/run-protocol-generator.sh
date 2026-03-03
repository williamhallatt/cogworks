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
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workspace_root="${BENCH_WORKSPACE_ROOT:-$repo_root}"
execution_mode="${BENCH_EXECUTION_MODE:-protocol_prompt}"
required_skill_slug="${BENCH_REQUIRED_SKILL_SLUG:-}"
skill_install_source="${BENCH_SKILL_INSTALL_SOURCE:-}"

mkdir -p "$skill_out_dir"

if [[ "$pipeline" == "cogworks" ]]; then
  read -r -d '' prompt <<EOF || true
You are running an external benchmark for cogworks.
Task id: $task_id
Sources path: $sources_path
Output skill directory: $skill_out_dir
Execution mode: $execution_mode

Read:
- $workspace_root/input/protocol/pipeline.md
- $workspace_root/input/protocol/TRUST_MODEL.md (if present)

Rules:
1) Read all source files from $sources_path
2) Generate SKILL.md and reference.md in $skill_out_dir
3) Include YAML frontmatter name + description
4) Do not ask questions; make defensible defaults
5) Do not read any files outside $workspace_root
6) If execution mode is skill_installed, explicitly use installed skill '$required_skill_slug' as your primary workflow guide
7) Add a Benchmark Evidence block in SKILL.md that includes:
   - skill_used: $required_skill_slug
   - skill_install_source: $skill_install_source
EOF
elif [[ "$pipeline" == "generator-a" ]]; then
  read -r -d '' prompt <<EOF || true
You are running an external benchmark for generator-a.
Task id: $task_id
Sources path: $sources_path
Output skill directory: $skill_out_dir
Execution mode: $execution_mode

Read:
- $workspace_root/input/protocol/pipeline.md

Rules:
1) Single-pass generation only
2) Generate SKILL.md and reference.md in $skill_out_dir
3) Include explicit trigger conditions and boundaries
4) Do not ask questions
5) Do not read any files outside $workspace_root
6) If execution mode is skill_installed, explicitly use installed skill '$required_skill_slug' as your workflow baseline
7) Add a Benchmark Evidence block in SKILL.md with:
   - skill_used: $required_skill_slug
   - skill_install_source: $skill_install_source
EOF
elif [[ "$pipeline" == "generator-b" ]]; then
  read -r -d '' prompt <<EOF || true
You are running an external benchmark for generator-b.
Task id: $task_id
Sources path: $sources_path
Output skill directory: $skill_out_dir
Execution mode: $execution_mode

Read:
- $workspace_root/input/protocol/pipeline.md

Rules:
1) Single-pass generation only
2) Generate SKILL.md and reference.md in $skill_out_dir
3) Emphasize concise progressive-disclosure instructions
4) Do not ask questions
5) Do not read any files outside $workspace_root
6) Add a Benchmark Evidence block in SKILL.md with:
   - skill_used: ${required_skill_slug:-none}
   - skill_install_source: ${skill_install_source:-none}
EOF
else
  echo "Unknown pipeline: $pipeline" >&2
  exit 2
fi

printf "%s\n" "$prompt" | codex exec -s workspace-write -C "$workspace_root" -
