#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/install-cogworks.sh --agent <claude-code|copilot-cli> --project <path> [--copy]

Installs the three cogworks skills plus the native agent definitions required
for the native-first build path.

Options:
  --agent <agent>    Target surface: claude-code or copilot-cli
  --project <path>   Target project directory where skills and native agents are installed
  --copy             Copy files instead of creating symlinks
  --help             Show this help
EOF
}

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

require_path() {
  local path="$1"
  local label="$2"
  [[ -e "$path" ]] || fail "$label not found: $path"
}

make_link_or_copy() {
  local source_path="$1"
  local target_path="$2"
  local mode="$3"

  mkdir -p "$(dirname "$target_path")"
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    rm -rf "$target_path"
  fi

  if [[ "$mode" == "copy" ]]; then
    cp -R "$source_path" "$target_path"
  else
    ln -s "$source_path" "$target_path"
  fi
}

AGENT=""
PROJECT_PATH=""
INSTALL_MODE="link"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --project)
      PROJECT_PATH="${2:-}"
      shift 2
      ;;
    --copy)
      INSTALL_MODE="copy"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$AGENT" ]] || fail "--agent is required"
[[ -n "$PROJECT_PATH" ]] || fail "--project is required"
require_path "$PROJECT_PATH" "Project path"

case "$AGENT" in
  claude-code|copilot-cli) ;;
  *)
    fail "--agent must be claude-code or copilot-cli"
    ;;
esac

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

case "$AGENT" in
  claude-code)
    SKILLS_DIR="$PROJECT_PATH/.claude/skills"
    AGENTS_DIR="$PROJECT_PATH/.claude/agents"
    RENDER_SURFACE="claude-cli"
    RENDER_OUTPUT_DIR="$AGENTS_DIR"
    ;;
  copilot-cli)
    SKILLS_DIR="$PROJECT_PATH/.agents/skills"
    AGENTS_DIR="$PROJECT_PATH/.github/agents"
    RENDER_SURFACE="copilot-cli"
    RENDER_OUTPUT_DIR="$AGENTS_DIR"
    ;;
esac

mkdir -p "$SKILLS_DIR"

for skill_name in cogworks cogworks-encode cogworks-learn; do
  require_path "$ROOT_DIR/skills/$skill_name" "Skill directory"
  make_link_or_copy \
    "$ROOT_DIR/skills/$skill_name" \
    "$SKILLS_DIR/$skill_name" \
    "$INSTALL_MODE"
done

python3 "$ROOT_DIR/scripts/render-agentic-role-bindings.py" \
  --surface "$RENDER_SURFACE" \
  --"${RENDER_SURFACE%%-*}"-output-dir "$RENDER_OUTPUT_DIR"

echo "Installed cogworks for $AGENT"
echo "Skills: $SKILLS_DIR"
echo "Native agents: $AGENTS_DIR"
