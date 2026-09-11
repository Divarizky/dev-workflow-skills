#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="${DEV_SKILLS_ROOT:-$HOME/.agents}"
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
  --source-root P     Shared skills source location
  --repo-url URL      Git repository URL
  --backup-existing   Move existing skill paths to a timestamped backup
  --unlink            Remove only links created to this source
  -h, --help          Show this help

Without an agent flag, only prepare the shared source at ~/.agents/skills/dev.

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
    --source-root) SOURCE_ROOT="${2:?missing value for --source-root}"; shift 2 ;;
    --repo-url) REPO_URL="${2:?missing value for --repo-url}"; shift 2 ;;
    --backup-existing) BACKUP_EXISTING=true; shift ;;
    --unlink) UNLINK=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v git >/dev/null || { echo "git tidak ditemukan." >&2; exit 1; }

if [[ ! -e "$SOURCE_ROOT" ]]; then
  mkdir -p "$(dirname "$SOURCE_ROOT")"
  echo "Cloning skills repository ke $SOURCE_ROOT"
  git clone "$REPO_URL" "$SOURCE_ROOT"
elif [[ ! -d "$SOURCE_ROOT/.git" ]]; then
  echo "Memakai shared skills root yang sudah ada di $SOURCE_ROOT (update Git dilewati)"
else
  if [[ -n "$(git -C "$SOURCE_ROOT" status --porcelain)" ]]; then
    echo "$SOURCE_ROOT memiliki perubahan lokal; commit/stash dulu." >&2
    exit 1
  fi
  echo "Memperbarui skills repository di $SOURCE_ROOT"
  git -C "$SOURCE_ROOT" pull --ff-only
fi

SOURCE_SKILL="$SOURCE_ROOT/skills/dev"
[[ -f "$SOURCE_SKILL/ask-me/SKILL.md" ]] || {
  echo "Source tidak memiliki skills/dev yang valid: $SOURCE_SKILL" >&2
  exit 1
}
SOURCE_SKILL="$(cd "$SOURCE_SKILL" && pwd)"

if ((${#AGENTS[@]} == 0)); then
  echo "Tidak ada target agent; source tersedia di $SOURCE_SKILL"
fi

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
  [[ "$resolved" == "$SOURCE_SKILL" ]]
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

  ln -s "$SOURCE_SKILL" "$target"
  echo "[$agent] symlink dibuat: $target -> $SOURCE_SKILL"
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
    echo "[$agent] dilewati karena bukan link ke source ini: $target"
  fi
}

for agent in "${AGENTS[@]}"; do
  [[ -n "$agent" ]] || continue
  if [[ "$UNLINK" == true ]]; then
    remove_link "$agent"
  else
    ensure_link "$agent"
  fi
done

echo "Selesai. Skills source: $SOURCE_ROOT"
