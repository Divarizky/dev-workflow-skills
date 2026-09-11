# Dev Workflow Skills

Kumpulan Agent Skills portable untuk workflow development yang terstruktur:
requirements, task breakdown, implementasi, review, diagnosis bug, migrasi,
prototype, handoff, status, dan penyelesaian merge conflict.

## Instalasi

Jalankan installer dari folder repository ini. Installer memakai satu folder
sumber bersama, lalu membuat link ke agent yang dipilih.

### Windows PowerShell

```powershell
.\install.ps1 --Pi --Codex --Claude
```

### macOS/Linux

```bash
./install.sh --Pi --Codex --Claude
```

Tanpa flag agent, installer hanya menyiapkan folder sumber bersama tanpa
membuat link ke Pi, Codex, atau Claude:

```powershell
.\install.ps1
```

```bash
./install.sh
```

## Flag installer

Flag agent bersifat opsional. Jika digunakan, beberapa flag boleh digabung:

| Flag | Agent | Target link |
|---|---|---|
| `--Pi` | Pi | `~/.pi/agent/skills/dev` |
| `--Codex` | Codex | `~/.codex/skills/dev` |
| `--Claude` | Claude Code | `~/.claude/skills/dev` |

### `--backup-existing`

Pindahkan folder atau link target lama ke backup bertimestamp sebelum membuat
link baru. Tanpa flag ini, target yang sudah ada tidak ditimpa.

```powershell
.\install.ps1 --Pi --backup-existing
```

```bash
./install.sh --Pi --backup-existing
```

### `--unlink`

Lepas link yang menunjuk ke folder sumber skill ini. Folder asli atau link ke
sumber lain tidak akan dihapus.

```powershell
.\install.ps1 --Pi --unlink
```

```bash
./install.sh --Pi --unlink
```

### `--source-root PATH`

Ubah lokasi folder sumber. Installer mencari skill pada `PATH/skills/dev`.

```powershell
.\install.ps1 --Pi --source-root "D:\agent-skills"
```

```bash
./install.sh --Pi --source-root "$HOME/agent-skills"
```

## Folder sumber default

```text
~/.agents/skills/dev
```

Jika `~/.agents` sudah dipakai sebagai shared skills root, installer
menggunakannya langsung. Update Git hanya dilakukan jika folder tersebut
merupakan clone repository. Installer memakai symlink di macOS/Linux dan
directory junction di Windows.

## Instalasi sebagai package

```bash
pi install git:git@github.com:Divarizky/dev-workflow-skills
```

## Catatan

Repository ini hanya memuat resource `skills/dev`. Skill dirancang untuk
workflow development, bukan untuk agent tertentu; kapabilitas opsional tetap
memiliki fallback sequential atau berbasis teks bila tersedia.
