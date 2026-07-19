---
name: status
description: Jawab "gua lagi di mana?" — baca state workflow lokal (feature aktif, task berjalan, handoff terakhir), ringkas jadi snapshot + saran skill berikutnya. Read-only, tidak menulis apapun. User-invoked.
disable-model-invocation: true
---

# Status

Snapshot cepat state kerja saat ini. Pas buka sesi baru dan lupa lagi ngerjain apa. Read-only — cuma baca + ringkas, tidak ubah file apapun.

## Prasyarat

`.agent-docs/project-meta.md` harus ada (`setup-workflow` sudah pernah jalan). Tidak ada → arahkan ke `setup-workflow`, stop.

## Step 1 — Baca State

Baca 3 sumber. Skip yang tidak ada atau corrupt — jangan error. Tapi informasikan ke user kalau ada file yang seharusnya ada tapi bermasalah.

### 1. Index Fitur

Baca `.agent-docs/issue-tracker.md`:
- Filter `status: open` dan `status: done`.
- Ambil `task_count` + `task_done` kalau ada — dipakai buat progress bar di Step 2.
- Kalau file tidak ada atau format invalid — laporkan: "issue-tracker.md tidak terbaca. Invoke `setup-workflow` dulu?"

### 2. Task Aktif

Untuk tiap slug `open`, baca `.agent-docs/.scratch/<slug>/tasks.md`.

Format tasks.md sekarang:
- `**Queue**` — bold label, bukan heading
- `**In Progress**` — bold label
- `**Done**` — bold label
- Checkbox: `[ ]` = not started / in progress, `[x]` = done

Yang perlu diekstrak:
- **In Progress**: cari semua baris `[ ]` di group `**In Progress**`. Ambil TASK-ID + nama.
- **Queue eligible**: di group `**Queue**`, cari baris `[ ]` yang `Depends:` sudah `[x]` di `**Done**`. Ambil task teratas.
- **Queue count**: total `[ ]` di Queue.

Kalau file tasks.md tidak ada tapi index bilang `open` — laporkan: "Slug X: tasks.md tidak ditemukan. Hapus dari index atau restore file."
Kalau file ada tapi format tidak bisa di-parse — laporkan: "Slug X: tasks.md format tidak dikenal."

### 3. Handoff Terakhir

Cari file terbaru di `.agent-docs/handoffs/` — pakai `ls -t .agent-docs/handoffs/*.md 2>/dev/null | head -1` (sort by mtime). Jangan sorting string filename — rawan error.

Ambil 1 baris ringkasan dari isi file (biasanya baris pertama setelah judul). Jangan baca seluruh file.

Kalau folder `handoffs/` tidak ada atau kosong — skip.

## Step 2 — Ringkas

Tampilkan snapshot ringkas:

```
## Status

**Feature aktif:**
- <slug> (<task_done>/<task_count> task selesai) — <status>
- <slug> (<task_done>/<task_count> task selesai) — <status>
  (atau "tidak ada feature open")

**Sedang dikerjakan:**
- TASK-N | <nama task> | <slug>
  (atau "tidak ada")

**Queue antrian:** <N> task — task teratas eligible:
- TASK-M | <nama task> | <slug>
  (atau "-")

**Handoff terakhir:** <path> — <1 baris ringkas>
  (atau "tidak ada")

**Feature done:** <slug(s) — atau "tidak ada">
```

Jangan dump seluruh isi tasks.md/handoff — cukup baris relevan. Reference by path kalau user mau detail.

**Stale task detection**: Cek task In Progress yang tidak ada aktivitas:
- `git log --since="7 days ago" --all --oneline 2>/dev/null` — kalau ada output, ada commit 7 hari terakhir.
- Atau: `git log -1 --format="%ar" HEAD` — "3 hours ago", "2 weeks ago".
- Tampilkan: "TASK-N — last commit: <N hari> lalu — <slug>."
- Kalau git belum init atau bukan repo — skip.

## Step 3 — Saran Skill Berikutnya

Berdasarkan state, sarankan skill (bukan auto-invoke — user putuskan):

- Ada task In Progress / Queue eligible → `implement`
- Tidak ada feature open, mau mulai fitur baru → `ask-me` (grill dulu, lalu nentuin jalur) atau `to-prd` langsung kalau ide sudah jelas
- Handoff terakhir punya section "Suggested Skills" → tampilkan saran itu
- Semua feature `done`, tidak ada kerja tertunda → beri tahu, saran `improve-architecture` (health check) opsional
- Kalau Queue penuh tapi semua blocked (tidak ada eligible) — saran: "Semua task nunggu dependency. Kerjakan blocker dulu."

## Kapan Pakai

- Awal sesi baru — cek posisi sebelum lanjut kerja
- Setelah break panjang — recall context
- Ragu ada task tertunda mana yang perlu dikerjakan
- Sebelum invoke `implement` — lihat task eligible mana yang paling prioritas
