# Dev Workflow Skills

Kumpulan Agent Skills portable untuk workflow development yang terstruktur:
requirements, task breakdown, implementasi, review, diagnosis bug, migrasi,
prototype, handoff, status, dan penyelesaian merge conflict.

## Instalasi

Installer menyimpan satu source canonical, lalu memasangnya ke agent pilihan
menggunakan link folder. Dengan begitu, semua agent memakai skill yang sama.

### Windows PowerShell

```powershell
.\install.ps1 --Pi --Codex --Claude
```

### macOS/Linux

```bash
./install.sh --Pi --Codex --Claude
```

Pilih agent sesuai kebutuhan, misalnya `--Pi`. Opsi tambahan:

- `--backup-existing` — pindahkan folder/link lama ke backup bertimestamp.
- `--unlink` — lepas link yang dibuat installer.
- `--canonical-root PATH` — ubah lokasi source canonical.
- `--repo-url URL` — gunakan URL repository lain.

Secara default, source canonical berada di `~/.agents`, dengan skill di
`~/.agents/skills/dev`. Jika folder itu sudah dipakai sebagai shared skills
root, installer menggunakannya langsung; update Git hanya dilakukan jika
folder tersebut adalah clone repository. Installer memakai symlink di
macOS/Linux dan directory junction di Windows. Folder skill target yang sudah
ada tidak ditimpa otomatis tanpa `--backup-existing`.

## Instalasi sebagai package

```bash
pi install git:git@github.com:Divarizky/dev-workflow-skills
```

## Catatan

Repository ini hanya memuat resource `skills/dev`. Skill dirancang untuk
workflow development, bukan untuk agent tertentu; kapabilitas opsional tetap
memiliki fallback sequential atau berbasis teks bila tersedia.
