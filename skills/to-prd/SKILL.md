---
name: to-prd
description: Sintesis percakapan/hasil grill jadi PRD, tulis ke .agent-docs/.scratch/ (full local). Tanpa interview — sintesis dari konteks yang sudah dibahas + eksplorasi codebase terfokus. User-invoked. Kalau butuh stress-test plan, pakai ask-me grill dalam dulu.
disable-model-invocation: true
---

# To PRD

Sintesis, bukan interview. Input berasal dari percakapan aktif atau hasil `ask-me` grill. Output: dokumen PRD yang siap di-review user.

## Prasyarat

- `.agent-docs/project-meta.md` harus ada (`setup-workflow` sudah pernah jalan). Tidak ada → arahkan ke `setup-workflow`, stop.
- `implement` sudah tulis `.agent-docs/.scratch/<slug>/tasks.md` (tracking minimal)? Baca dulu — ini sumber tambahan.

## Step 1 — Context Sebelum Eksplorasi

Jangan eksplorasi codebase dulu. Urutan:

1. **Baca `.agent-docs/CONTEXT.md`** — vocabulary domain. Catat istilah yang relevan dengan fitur ini.
2. **Baca `.agent-docs/ADR.md`** — keputusan arsitektur di area terkait. Jangan re-litigasi tanpa alasan kuat.
3. **Cek path `.agent-docs/.scratch/<slug>/tasks.md`** — kalau ada dari `implement` (tracking minimal), baca isinya sebagai referensi.
4. **Eksplorasi codebase terfokus** — maksimal 10 file atau 5 menit, mana yang lebih dulu. Fokus pada area yang relevan dengan fitur (baca nama file/directory di path terkait, bukan seluruh repo).

### Seam Detection Heuristic

Selama eksplorasi, deteksi seam — titik kode tempat behavior bisa diganti tanpa edit langsung di situ.

**Universal heuristic** (berlaku untuk TS, Java, Kotlin, Dart, Go, C#, Swift):
- Grep `interface`, `abstract class`, `protocol`, `trait`
- Filter yang jumlah method publik ≤3 — itu seam kandidat terkuat
- Cek constructor / function parameter: kalau ada parameter bertipe interface/abstract — itu injection point, preferred seam
- Cek apakah ada >1 implementasi concrete dari interface yang sama (seam sudah terbukti dipakai)

**Dynamic language fallback** (JS, Python, Ruby, PHP tanpa type hints):
- Grep file test untuk pattern: `mock(`, `patch(`, `stub(`, `Mock(`, `unittest.mock`
- Tiap mock object menunjuk ke dependency yang bisa diganti — itu seam tersembunyi
- Prioritaskan seam dari file yang paling banyak di-mock di test suite — itu dependency yang paling sering perlu diganti

**Output seam detection**: tulis 2-3 seam candidate. Jangan paksakan satu seam. Prioritaskan seam existing (sudah ada di kode) daripada seam baru.

## Step 2 — Tulis PRD

Format dengan frontmatter YAML:

```yaml
---
version: 1.0.0
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
source: to-prd  # atau ask-me (grill dalam), manual
status: draft  # lifecycle: draft → approved → superseded
supersedes: <path versi sebelumnya>  # opsional, isi kalau update PRD lama
---
```

```
# <Judul Fitur>

## Problem
<Masalah dari perspektif user — 2-4 kalimat>

## Solution
<Solusi dari perspektif user — 3-5 kalimat>

## User Stories
(MUST) As a <role>, I want <goal>, so that <benefit>
(MUST) As a <role>, I want <goal>, so that <benefit>
(SHOULD) As a <role>, I want <goal>, so that <benefit>
(NICE) As a <role>, I want <goal>, so that <benefit>

Label prioritas: MUST (critical path), SHOULD (penting tapi bisa tunda), NICE (nice-to-have).

## Acceptance Criteria
- <Kondisi konkret, terukur — fitur dianggap selesai kalau semua terpenuhi>
- <Contoh: "User dapat login dengan email dan password valid — test e2e pass">
- <Contoh: "Error message muncul saat email tidak terdaftar">

## Implementation Decisions
**Final** (sudah disepakati, tidak bisa diganti tanpa ADR):
- <Keputusan 1> — alasan

**Open** (masih perlu validasi saat implementasi):
- <Keputusan 2> — apa yang belum jelas

## Testing Decisions
- **Seam(s)**: <1-3 seam, prioritaskan utama. Tiap seam: file + interface + method count>
- **Test Strategy**: <unit / integration / e2e — yang mana dan coverage target>
- **Environment**: <local / staging / env specific requirement>

## Out of Scope
- <Yang eksplisit tidak dikerjakan di PRD ini>
- <Future scope — catat, tidak dibahas di sini>

## Further Notes (opsional)
<Catatan tambahan yang penting dibawa ke implementasi>
```

### Aturan konten:

- **Jangan sertakan file path atau code snippet spesifik** — cepat basi. Ini berlaku penuh.
- **Exception — hanya kalau**: (a) schema/type/interface <15 baris, (b) state machine ≤6 states, (c) decision table ≤10 baris. Lebih dari itu → link ke file dengan snapshot commit reference: `// snapshot at a7f3e2 — User model v2`. Catat singkat kenapa inline diperlukan.
- **Jangan gunakan exception untuk logika bisnis atau implementasi detail** — hanya untuk struktur data yang encode keputusan lebih presisi dari prosa.
- **User Stories dicover semua aspek fitur** — tapi prioritas MUST harus jelas supaya implementasi tahu critical path.

## Step 3 — Tulis ke PRD.md

Deteksi dulu: apakah `.agent-docs/.scratch/<feature-slug>/PRD.md` sudah ada?

- **Belum ada**: tulis file baru dengan `version: 1.0.0`, `status: draft`, `created: hari ini`.
- **Sudah ada**: baca isinya. Update konten (jangan overwrite mental). Increment `version` (minor, misal `1.1.0`). Tambah `supersedes` dengan path versi sebelumnya. Update `updated: hari ini`. Jangan ubah `created`. Source field tetap dari asal pertama.

**Catatan**: `implement` bisa tulis tracking minimal di `.agent-docs/.scratch/<slug>/tasks.md` untuk fitur dari konteks — itu referensi, bukan overwrite PRD.

PRD.md tidak masuk siklus triage task (triage berlaku di level task via `to-issues`, bukan PRD). Tapi PRD punya lifecycle sendiri via status frontmatter.

## Step 4 — Validasi Diri

Sebelum kasih ke user, cek:

1. **Error check**: Ada placeholder `<...>` yang belum keisi? Kalau ada, tanya user.
2. **Alignment check**: Apakah semua Problem punya setidaknya satu User Story yang address? Apakah semua Acceptance Criteria bisa di-trace ke Solution?
3. **Seam check**: Apakah seam yang dipilih benar-benar ada di codebase (bukan khayalan)? Kalau seam baru — sebut bahwa ini perlu dibuat.
4. **Version check**: Apakah `version` di-increment dengan benar (baru: 1.0.0, update: minor bump).

Kalau ada gap — tanyakan ke user, jangan publish dulu.

## Step 5 — Present & Approve

Tampilkan PRD ke user:

```
Draft PRD: .agent-docs/.scratch/<slug>/PRD.md v<version>

[ringkasan — Problem + Solution + Acceptance Criteria]

Status sekarang: draft
Approve? (y/n)
```

- User **y** → update `status: approved` di frontmatter. Lanjut ke **chain to-issues** (lihat bawah).
- User **n** / kasih revisi → update konten sesuai input. Increment version (minor bump). `status` tetap `draft`. Tanya lagi sampai approve.
- User minta perubahan besar → tulis ulang section relevan, bump version, present ulang.

### Chain ke To-Issues

Setelah PRD di-approve user, tanya:

> PRD sudah approved. Lanjut breakdown ke task via `to-issues`? (y/n)

- User **tidak** → beri tahu user path file PRD + saran: "Invoke `to-issues` kapan saja mau breakdown task."
- User **ya** → **jangan invoke `to-issues` sebagai auto-trigger** (`disable-model-invocation: true`). Sebagai gantinya:

  1. Baca `to-issues/SKILL.md` — pahami Step 2 (vertical slice), Step 3 (propose slicing + iterasi), Step 4 (tulis tasks.md)
  2. Jalankan Step 2-4 `to-issues` manual di dalam sesi ini
  3. Tulis `.agent-docs/.scratch/<slug>/tasks.md` dengan format dan mekanisme yang sama persis seperti `to-issues` lakukan
  4. Update `.agent-docs/issue-tracker.md` — entry slug ini jadi `status: open`
  5. Beri tahu user: PRD approved + tasks.md siap. Path kedua file.

**PENTING**: Skill ini tetap `disable-model-invocation: true` — tidak ada auto-invoke di luar sesi. Chain hanya terjadi karena user explicit approve + setuju breakdown, dalam satu sesi percakapan yang sama.

## Saran Skills Lain

- **Banyak keputusan ambigu tentang fitur** → `ask-me` grill dalam dulu, baru `to-prd` (stress-test design sebelum dokumentasi)
- **PRD sudah disetujui, mau breakdown task** → bisa langsung chain ke `to-issues` lewat Step 5 `to-prd`. Atau invoke `to-issues` manual kalau mau di sesi lain.
- **Belum ada `project-meta.md`** → `setup-workflow` dulu (prasyarat semua skill dev)
