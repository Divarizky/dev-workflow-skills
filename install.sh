#!/usr/bin/env bash
set -euo pipefail

CANONICAL_ROOT="${DEV_SKILLS_ROOT:-$HOME/.agents}"
REPO_URL="${DEV_SKILLS_REPO_URL:-git@github.com:Divarizky/dev-workflow-skills.git}"
AGENTS=()
UNLINK=false
BACKUP_EXISTING=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --Pi                Install for Pi
  --Codex             Install for Codex
  --Claude            Install for Claude Code
  --canonical-root P  Canonical clone location
  --repo-url URL      Git repository URL
  --backup-existing   Move existing skill paths to a timestamped backup
  --unlink            Remove only links created to this canonical source
  -h, --help          Show this help

Environment:
  DEV_SKILLS_ROOT, DEV_SKILLS_REPO_URL
  PI_CODING_AGENT_DIR, CODEX_HOME, CLAUDE_CONFIG_DIR
EOF
}

while (($#)); do
  case "$1" in
    --Pi|--pi) AGENTS+=(pi); shift ;;
    --Codex|--codex) AGENTS+=(codex); shift ;;
    --Claude|--claude) AGENTS+=(claude); shift ;;
    --canonical-root) CANONICAL_ROOT="${2:?missing value for --canonical-root}"; shift 2 ;;
    --repo-url) REPO_URL="${2:?missing value for --repo-url}"; shift 2 ;;
    --backup-existing) BACKUP_EXISTING=true; shift ;;
    --unlink) UNLINK=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v git >/dev/null || { echo "git tidak ditemukan." >&2; exit 1; }

if ((${#AGENTS[@]} == 0)); then
  echo "Pilih minimal satu agent: --Pi, --Codex, atau --Claude." >&2
  usage >&2
  exit 2
fi

if [[ ! -e "$CANONICAL_ROOT" ]]; then
  mkdir -p "$(dirname "$CANONICAL_ROOT")"
  echo "Cloning canonical repository ke $CANONICAL_ROOT"
  git clone "$REPO_URL" "$CANONICAL_ROOT"
elif [[ ! -d "$CANONICAL_ROOT/.git" ]]; then
  echo "Memakai shared skills root yang sudah ada di $CANONICAL_ROOT (update Git dilewati)"
else
  if [[ -n "$(git -C "$CANONICAL_ROOT" status --porcelain)" ]]; then
    echo "$CANONICAL_ROOT memiliki perubahan lokal; commit/stash dulu." >&2
    exit 1
  fi
  echo "Memperbarui canonical repository di $CANONICAL_ROOT"
  git -C "$CANONICAL_ROOT" pull --ff-only
fi

CANONICAL_SKILL="$CANONICAL_ROOT/skills/dev"
[[ -f "$CANONICAL_SKILL/ask-me/SKILL.md" ]] || {
  echo "Canonical repository tidak memiliki skills/dev yang valid: $CANONICAL_SKILL" >&2
  exit 1
}
CANONICAL_SKILL="$(cd "$CANONICAL_SKILL" && pwd)"

skill_path() {
  case "$1" in
    pi) echo "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills/dev" ;;
    codex) echo "${CODEX_HOME:-$HOME/.codex}/skills/dev" ;;
    claude) echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/dev" ;;
    *) echo "Agent tidak didukung: $1" >&2; return 1 ;;
  esac
}

same_link() {
  local target="$1"
  [[ -L "$target" ]] || return 1
  local resolved
  resolved="$(cd "$(dirname "$target")" && realpath "$(basename "$target")" 2>/dev/null || true)"
  [[ "$resolved" == "$CANONICAL_SKILL" ]]
}

ensure_link() {
  local agent="$1" target
  target="$(skill_path "$agent")"
  mkdir -p "$(dirname "$target")"

  if [[ -e "$target" || -L "$target" ]]; then
    if same_link "$target"; then
      echo "[$agent] sudah terhubung: $target"
      return
    fi
    if [[ "$BACKUP_EXISTING" != true ]]; then
      if [[ -L "$target" ]]; then
        echo "[$agent] target adalah link ke lokasi lain: $target; gunakan --backup-existing." >&2
      else
        echo "[$agent] folder skill nyata sudah ada: $target; gunakan --backup-existing." >&2
      fi
      return 1
    fi
    local backup="${target}.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$target" "$backup"
    echo "[$agent] target lama dipindahkan ke $backup"
  fi

  ln -s "$CANONICAL_SKILL" "$target"
  echo "[$agent] symlink dibuat: $target -> $CANONICAL_SKILL"
}

remove_link() {
  local agent="$1" target
  target="$(skill_path "$agent")"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    echo "[$agent] tidak ada link: $target"
  elif same_link "$target"; then
    rm "$target"
    echo "[$agent] link dilepas: $target"
  else
    echo "[$agent] dilewati karena bukan link ke canonical source: $target"
  fi
}

IFS=',' read -r -a selected <<< "$AGENTS"
for agent in "${selected[@]}"; do
  [[ -n "$agent" ]] || continue
  if [[ "$UNLINK" == true ]]; then
    remove_link "$agent"
  else
    ensure_link "$agent"
  fi
done

echo "Selesai. Canonical source: $CANONICAL_ROOT"
