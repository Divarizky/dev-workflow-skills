---
name: setup-workflow
description: Setup kumpulan skill dev untuk sebuah repo/project. Deteksi status project (baru/existing), generate .agent-docs/ sebagai tracker lokal. Prasyarat wajib — jalankan sekali per repo sebelum skill lain (ask-me, implement, bug-diagnosis, to-prd, to-issues, improve-architecture, project-migration, prototype, code-review, handoff, status) dipakai pertama kali di repo tersebut.
disable-model-invocation: true
---

# Setup Workflow

Tulis config yang skill lain baca. Run sekali per repo. Bukan scaffold deterministik — deteksi state repo nyata, konfirmasi ke user kalau ambigu, baru tulis.

## Step 1 — Cek marker setup

Cek exist: `.agent-docs/project-meta.md`

- Ada → setup sudah pernah jalan. Baca isinya, tampilkan ringkasan (status, setup_date), lanjut ke `ask-me`. STOP di sini.
- Tidak ada → lanjut Step 2.

## Step 2 — Deteksi status project

Tentukan `new` vs `existing` dari isi folder + git history (kalau ada):

- Kosong / hanya file scaffold bawaan (contoh: `flutter create`, `create-react-app`, `npx create-next-app` default output tanpa modifikasi) → status: `new`
- Banyak file custom (+ git history lebih dari initial commit kalau git repo) → status: `existing`

Bukan git repo (folder polos) → deteksi dari isi folder saja. Folder kosong atau hanya berisi `.agent-docs/` → `new`.

## Step 3 — Isi CONTEXT.md, ADR.md

Cabang berdasarkan status project:

**Existing:**
- Jalankan versi ringan dari `project-migration/docs/CONTEXT-INTAKE.md` (scan struktur folder, dependency utama, pattern arsitektur yang kepakai)
- Tujuan: isi `.agent-docs/CONTEXT.md` dari hasil scan otomatis
- `.agent-docs/ADR.md` dibuat kosong — belum ada keputusan arsitektur untuk di-log dari scan pasif
- Jangan generate risk register — itu domain `project-migration`, bukan setup

**New:**
- Delegasikan ke skill `ask-me` — jalankan grill dalam mode **Bangun Domain** (interview loop, CONTEXT.md kosong)
- `ask-me` yang isi `.agent-docs/CONTEXT.md` dan `.agent-docs/ADR.md` langsung dengan hasil sesi
- Setup tidak lanjut ke Step 4 sampai `ask-me` selesai

**Dependency**: `ask-me` (grill dalam mode Bangun Domain) — resolved.

## Step 4 — Generate `.agent-docs/`

Tulis file berikut jika belum ada (jangan overwrite jika sudah ada):

- `.agent-docs/CONTEXT.md` — hasil Step 3 (scan atau grill)
- `.agent-docs/ADR.md` — hasil Step 3 (kosong atau hasil grill)
- `.agent-docs/TDD.md` — copy dari seed `setup-workflow/seeds/TDD.md` apa adanya (isi tetap, tidak project-specific)
- `.agent-docs/issue-tracker.md` — index ringan per fitur (tracker: local, list `features: [{slug, status}]`). Kosong (`features: []`) saat pertama dibuat — diisi `to-issues` saat fitur pertama di-breakdown (schema `features:` didefinisikan di skill `to-issues`).

Struktur task lokal (lazy-created, bukan digenerate di sini — muncul saat `to-prd`/`to-issues` dipanggil pertama kali untuk fitur tertentu): `.agent-docs/.scratch/<feature-slug>/PRD.md` (dari `to-prd`) dan `.agent-docs/.scratch/<feature-slug>/tasks.md` (dari `to-issues`, single-file checklist dengan section Queue/In Progress/Done/Superseded).

## Step 5 — Tulis project-meta.md

```
.agent-docs/project-meta.md
---
status: <new|existing>
setup_date: <YYYY-MM-DD>
```

## Step 6 — Selesai

Beri tahu user:
- Setup complete
- Status terdeteksi (new/existing)
- Arahkan ke `ask-me` untuk mulai kerja

## Re-run

Setup hanya perlu diulang jika user eksplisit minta reset (restart context). Skill ini tidak auto re-run selama `.agent-docs/project-meta.md` masih ada.
