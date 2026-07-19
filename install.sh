#!/usr/bin/env bash
# Install dev-workflow-skills ke ~/.pi/agent/skills/
# Usage:
#   curl -L https://raw.githubusercontent.com/Divarizky/dev-workflow-skills/main/install.sh | bash
#   ./install.sh                  # interactive: skip existing, prompt overwrite
#   ./install.sh --force          # overwrite semua tanpa prompt
set -euo pipefail

REPO="Divarizky/dev-workflow-skills"
BRANCH="main"
DEST="${HOME}/.agents/skills"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

SKILLS=(
  setup-workflow
  ask-me
  status
  to-prd
  to-issues
  implement
  code-review
  prototype
  improve-architecture
  project-migration
  bug-diagnosis
  handoff
)

# seeds/<file> relative to setup-workflow skill folder
SEEDS=(
  "setup-workflow/seeds/TDD.md"
)

force=0
for arg in "$@"; do
  case "$arg" in
    --force|-f) force=1 ;;
    --help|-h)
      sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

echo "→ Installing dev-workflow-skills to ${DEST}"
mkdir -p "${DEST}"

installed=0; skipped=0; overwritten=0; failed=0

install_one () {
  local rel="$1"
  local target="${DEST}/${rel}"
  mkdir -p "$(dirname "${target}")"

  if [[ -f "${target}" && ${force} -eq 0 ]]; then
    read -r -p "  '${rel}' exists. Overwrite? [y/N] " ans
    case "${ans}" in
      y|Y|yes|YES) : ;;
      *) echo "    skip ${rel}"; skipped=$((skipped+1)); return ;;
    esac
    overwritten=$((overwritten+1))
  elif [[ -f "${target}" && ${force} -eq 1 ]]; then
    overwritten=$((overwritten+1))
  else
    installed=$((installed+1))
  fi

  if ! curl -fsSL "${RAW}/skills/${rel}" -o "${target}"; then
    echo "    FAIL ${rel}" >&2
    failed=$((failed+1))
    # rollback counter so summary matches reality
    if [[ ${installed} -gt 0 && "${target}" -ef "${target}" ]]; then installed=$((installed-1)); fi
    if [[ ${overwritten} -gt 0 && "${target}" -ef "${target}" ]]; then overwritten=$((overwritten-1)); fi
    return 1
  fi
  echo "    ✓ ${rel}"
}

for s in "${SKILLS[@]}"; do
  install_one "${s}/SKILL.md" || true
done

for s in "${SEEDS[@]}"; do
  install_one "${s}" || true
done

echo ""
echo "Done. installed=${installed} overwritten=${overwritten} skipped=${skipped} failed=${failed}"
echo "Restart pi agent (or reload skills) to pick up new skills."
exit 0
