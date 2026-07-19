#!/usr/bin/env bash
# Hapus dev-workflow-skills dari ~/.agents/skills/
# Usage:
#   curl -L https://raw.githubusercontent.com/Divarizky/dev-workflow-skills/main/uninstall.sh | bash
#   ./uninstall.sh                # interactive: prompt sebelum hapus
#   ./uninstall.sh --force        # hapus semua tanpa prompt
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

echo "→ Uninstalling dev-workflow-skills from ${DEST}"

if [[ ! -d "${DEST}" ]]; then
  echo "  nothing to do: ${DEST} does not exist"
  exit 0
fi

removed=0; skipped=0; missing=0

uninstall_one () {
  local rel="$1"
  local target="${DEST}/${rel}"

  if [[ ! -f "${target}" ]]; then
    missing=$((missing+1))
    echo "    - ${rel} (not present)"
    return
  fi

  if [[ ${force} -eq 0 ]]; then
    read -r -p "  Remove '${rel}'? [y/N] " ans
    case "${ans}" in
      y|Y|yes|YES) : ;;
      *) echo "    skip ${rel}"; skipped=$((skipped+1)); return ;;
    esac
  fi

  rm -f "${target}"
  removed=$((removed+1))
  echo "    ✓ ${rel}"
}

for s in "${SKILLS[@]}"; do
  uninstall_one "${s}/SKILL.md" || true
done

for s in "${SEEDS[@]}"; do
  uninstall_one "${s}" || true
done

# Cleanup: hapus folder kosong dari dalam ke luar (skill dir → setup-workflow/seeds → skill root)
# Hanya hapus folder yang benar-benar kosong; kalau ada file lain di situ, biarkan.
for skill in "${SKILLS[@]}"; do
  rmdir "${DEST}/${skill}/seeds" 2>/dev/null || true
  rmdir "${DEST}/${skill}" 2>/dev/null || true
done

# Remove DEST itu sendiri kalau kosong (artinya semua skill kita sudah dibersihkan)
if [[ -d "${DEST}" && -z "$(ls -A "${DEST}")" ]]; then
  rmdir "${DEST}"
  echo "  (removed empty ${DEST})"
fi

# Note untuk user: .agent-docs/ di project (project-meta.md dll) sengaja tidak dihapus —
# itu data kerja user, bukan bagian dari skill installer. Hapus manual kalau perlu:
#   rm -rf .agent-docs/

echo ""
echo "Done. removed=${removed} skipped=${skipped} already_absent=${missing}"
echo "Restart agent (or /reload) to pick up changes."
exit 0
