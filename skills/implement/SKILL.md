---
name: implement
description: Eksekusi implementasi. Input dari tasks.md (hasil to-issues) atau langsung dari konteks (hasil grill ask-me). Drive TDD internal, chain ke code-review. User-invoked.
disable-model-invocation: true
---

# Implement

Engine eksekusi. Input bisa dari tasks.md (task existing) atau langsung dari hasil grill / diskusi (fitur baru).

## Prasyarat

**Setup marker:** `.agent-docs/project-meta.md` harus ada (`setup-workflow` sudah pernah jalan) — gate ini biasanya dijaga via `ask-me` router.

## Step 1 — Cari Input

Cari source implementasi, prioritas:

1. **Konteks percakapan** — user sudah jelas dengan behavior yang mau diimplement?
   - Dari hasil grill `ask-me` (scope, behavior, terminologi)
   - Dari diskusi langsung
   - Kalau cukup → langsung Step 3 (TDD). Skip Step 2.

2. **tasks.md** — ada task eligible di Queue?
   - Baca `.agent-docs/issue-tracker.md`, filter slug `status: open`.
   - Ambil task teratas di **Queue** yang `Depends:` sudah di **Done**.
   - Lanjut Step 2 (update status, BASE_COMMIT).

3. **Gak ada keduanya** — tanya user:
   - "Mau langsung implement dari ide ini, atau breakdown dulu lewat `to-issues`?"
   - User pilih langsung → source = konteks. User pilih breakdown → arahkan `to-issues`.

## Step 2 — Update Status & Capture Base

**Hanya jalan kalau source dari tasks.md.** Kalau source dari konteks → skip Step 2.

Cut task dari **Queue**, paste ke **In Progress**.

**Catat base reference**: jalankan `git rev-parse HEAD`, simpan sebagai `BASE_COMMIT`. Ini titik sebelum perubahan. Nanti di Step 4, pass `BASE_COMMIT..HEAD` sebagai diff range ke `code-review`. Kalau belum ada commit (repo baru sebelum init) — catat `BASE_COMMIT: none` (code-review akan diff working tree vs empty).

Kalau sesi akan di-handoff sebelum review — pastikan BASE_COMMIT dicatat di handoff doc.

## Step 3 — Implement (TDD)

### Branching Tipe Task

Cek Detail task di tasks.md. Kalau task bertipe `prototype` → **skip TDD, skip test**. Langsung buat prototype sesuai `prototype/SKILL.md`. Output: prototype decision + throwaway branch. Setelah selesai → lompat ke Step 5.

Kalau task normal:

Baca `.agent-docs/TDD.md` — disiplin red-green-refactor vertical-slice. Tapi adjust berdasarkan tipe implementasi:

- **Pure logic / compute** (validasi, kalkulasi, transformasi data) → TDD penuh. Wajib test untuk critical path + edge case.
- **UI-heavy / API integration** (komponen visual, endpoint wrapper, third-party call) → minimal 1 test untuk critical path. TDD penuh opsional — prioritaskan test yang verifikasi kontrak.
- **Bug fix** → characterization test dulu sebelum fix: tangkap behavior existing (termasuk bug) di test, baru fix dan update test assertion. Jangan hapus test characterization setelah fix — jadi regression test.
- **Greenfield / test framework belum ada** → setup test runner dulu (pilih yang cocok dengan tech stack). Kalau setup >10 menit — skip TDD, inform user.

### Escape Hatch

Setelah maksimal 3 siklus RED→GREEN masih gagal (test merah terus, infinite refactor loop, atau stuck):
- Stop TDD cycle.
- Tanya user: "TDD stuck setelah 3 siklus. Opsi: (a) skip test, lanjut implementasi langsung, (b) minta bantuan, (c) batalkan."
- Kalau user skip — catat di handoff/pesan: "Diimplementasi tanpa test — TDD gagal karena [alasan]."
- Jangan loop forever.

### Catatan Implementasi

- Vocabulary dari `.agent-docs/CONTEXT.md`, respect `.agent-docs/ADR.md`.
- Test verifikasi behavior via interface publik, bukan detail implementasi.
- Kalau selama implementasi nemu code smell struktural (bukan cuma masalah task ini) — catat, jangan perbaiki. Sarankan `improve-architecture` nanti.

## Step 4 — Review

**Kalo task prototype → skip review.** Langsung capture answer di `.agent-docs/.scratch/<slug>/prototype-decision.md` + commit prototype ke throwaway branch (jangan main). Lompat ke Step 5.

Kalo task normal:

### Capture Current State

Jalankan `git rev-parse HEAD` → `CURRENT_COMMIT`.

### Delegasikan ke `code-review`

Fixed point: pass `BASE_COMMIT` sebagai fixed point. Diff range: `BASE_COMMIT..CURRENT_COMMIT`. Kalau BASE_COMMIT none → code-review diff working tree vs empty.

Spec — isi dari tasks.md (Detail + Done criteria) atau hasil grill (behavior + terminologi), pass sebagai text inline. **Sertakan Done criteria** kalau ada.

Karena `code-review` `disable-model-invocation: true`, jangan auto-invoke. **Baca `code-review/SKILL.md`, jalankan Step 1-5 manual** di sesi yang sama.

## Step 5 — Selesai

- **Review pass**:
  - Kalau dari **tasks.md**: cut task dari **In Progress**, paste ke **Done** (append bawah), ganti `[ ]` → `[x]`. Update index (lihat bawah).
  - Kalau dari **konteks**: tulis file tracking minimal (lihat bawah).
  - Inform user task selesai.
  - Tanya user: "Selesai. Mau commit dulu atau lanjut?" Jangan auto-commit.
  - Kalau dari tasks.md, **Cek Queue** — ada task yang semua dependency-nya sudah `[x]` (Done)? Kalau ada, tawarkan: "TASK-N sekarang eligible. Kerjakan? (y/n)". User y → ulang dari Step 2. User n → selesai.

- **Review ada temuan**:
  - Task tetap di **In Progress**.
  - Jangan sarankan commit.
  - Kembali ke Step 3, perbaiki kode, ulang Step 4.
  - BASE_COMMIT tetap sama.

### Update Index (dari tasks.md)

Setelah pindah ke Done, update `.agent-docs/issue-tracker.md`:
- Increment `task_done` (+1).
- Cek `task_done == task_count`? Ya → `status: done`. Tidak → `status: open` tetap.
- Update `updated: <hari ini>`.

### Tracking Minimal (dari konteks)

Tulis entry di `.agent-docs/issue-tracker.md` + `.agent-docs/.scratch/<slug>/tasks.md`:

```yaml
# issue-tracker.md entry
- slug: <fitur>
  status: done
  source: ask-me
  created: <hari ini>
  updated: <hari ini>
  task_count: 1
  task_done: 1
```

```markdown
# <Fitur> — Tasks

**Done**
- [x] TASK-1 | <judul fitur> | Depends: none | Priority: medium
    Detail: <behavior dari grill>
    Done:
    - [x] <criteria>
```

### Aturan Commit

Commit hanya pas implementasi utuh masuk **Done** — bukan di tengah TDD cycle. Commit terpisah untuk prefactoring sama commit implementasi — jangan digabung.

### Side Quest — Code Smell

Kalau selama implementasi nemu masalah arsitektur yang signifikan (tidak langsung terkait task ini):
- Catat: path file, deskripsi smell, saran perbaikan.
- Setelah Step 5 selesai, tampilkan: "Saya lihat potensi deepening di [modul]. Kapan-kapan invoke `improve-architecture` buat health check."

## Saran Skills Lain

- **Task belum ada breakdown** → `to-issues` dulu (pecah PRD/plan jadi task)
- **Butuh deep domain modeling dulu** → `ask-me` grill dalam
- **Ada temuan arsitektur selama implementasi** → `improve-architecture` terpisah (jangan digabung)
- **Sesi mau ditutup, task masih In Progress** → `handoff` dulu

### Catatan Chain

Skill ini bagian dari chain: `to-prd`→`to-issues`→`implement`→`code-review`. Setelah `code-review` selesai:
- Review pass → kembali ke Step 5 `implement`.
- Review fail → kembali ke Step 3 `implement` (perbaiki kode, review ulang). BASE_COMMIT tetap.
