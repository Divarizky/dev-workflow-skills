---
name: to-issues
description: Pecah PRD/plan menjadi task independen (vertical slices, alias tracer bullet), tulis ke tasks.md (full local). User-invoked.
disable-model-invocation: true
---

# To Issues

Pecah spec jadi task vertical-slice, tulis ke tasks.md. Input: PRD.md, percakapan, atau split task existing.

## Prasyarat

- `.agent-docs/project-meta.md` harus ada (`setup-workflow` sudah pernah jalan). Belum ada → arahkan ke `setup-workflow`, stop.
- Kalau input dari PRD.md — pastikan `status: approved` di frontmatter-nya. Kalau masih `draft`, konfirmasi ke user dulu: "PRD ini masih draft. Lanjut breakdown anyway atau approve dulu?"

## Step 1 — Deteksi Sumber Input

Branching berdasarkan sumber:

### Sumber A: PRD.md (path langsung atau chain dari `to-prd`)

1. Baca `.agent-docs/.scratch/<slug>/PRD.md` — ambil Problem, Acceptance Criteria, User Stories, Testing Decisions.
2. Kalau `status: draft` → tanya user: "PRD masih draft. Lanjut breakdown atau approve dulu?"
3. Kalau `status: approved` → lanjut Step 2.

### Sumber B: Percakapan aktif (hasil `ask-me` grill dalam / diskusi langsung)

1. Filter: hanya keputusan yang sudah disepakati eksplisit masuk breakdown. Ide yang masih ditanya/tentatif → skip atau masukan ke Further Notes.
2. Kalau belum ada PRD.md sama sekali → tanya user: "Mau saya buat PRD dulu lewat `to-prd`, atau langsung breakdown dari percakapan ini?"
3. User pilih langsung breakdown → ekstrak problem, solution, behavior dari percakapan, lanjut Step 2.

### Sumber C: Split task existing

1. Baca `.agent-docs/.scratch/<slug>/tasks.md` — cari task di Queue dengan deskripsi >5 baris atau scope lebar.
2. Proposal: "TASK-3 terlalu besar. Pecah jadi sub-task?" User setuju → sub-task list.
3. Skip Step 2 (vertical slice — ini sub-division, bukan slice baru). Langsung ke Step 3 dengan format khusus split.
4. Kalau tidak ada task oversized — beri tahu user, stop. Tidak ada yang perlu di-split.

## Step 2 — Vertical Slices + Greenfield Branch

### Definisi

- **Horizontal slice**: satu layer saja (schema, API, UI). Tidak bisa di-demo sampai semua layer selesai.
- **Vertical slice** (tracer bullet): satu jalur sempit tembus SEMUA layer. Bisa langsung di-demo begitu selesai.

### Branching Status Project

Baca `.agent-docs/project-meta.md`:

**Existing** (`status: existing`):
- Eksplorasi codebase terfokus — 5 file atau 3 menit. Cari layer stack (frontend/backend/DB/infra) dari struktur folder.
- Judul & deskripsi pakai vocabulary `.agent-docs/CONTEXT.md`, respect `.agent-docs/ADR.md`.

**New** (`status: new` / greenfield):
- Tidak perlu eksplorasi codebase — belum ada kode.
- Tentukan layer stack bareng user: "Project ini layer apa aja? Frontend web? Mobile? Backend API? Database? Infra?"
- Vertical slice tetap relevan — layer yang akan dibangun.
- Prefactoring skip (tidak ada kode).

### Prefactoring (hanya untuk existing project)

Sebelum breakdown, cari 1-2 smell kecil di area yang langsung disentuh fitur. Bukan refactor besar.
- Batas waktu: maksimal 15 menit atau 1-2 perubahan.
- Contoh yang diizinkan: rename method, extract small function, inline trivial wrapper.
- Contoh yang dilarang: restrukturisasi modul, ganti pola arsitektur, extract interface baru — itu domain `improve-architecture`.
- Tanya user: "Saya lihat [smell] di area yang akan disentuh. Betulin dulu sebelum breakdown? (estimated: 5-10 menit)"
- Kalau user skip — catat di Further Notes, jangan paksa.

## Step 3 — Present & Iterasi Breakdown

### Format Proposal

```
**Proposed Slices:**

**1. [Judul Slice]**
- Blocked by: None / TASK-xxx
- User stories covered: <MUST/SHOULD/NICE dari PRD, atau "N/A — split task">
- Scope: <deskripsi singkat end-to-end behavior>
- Layers: <layer yang ditembus — frontend, backend, DB, infra>
- Type: implement | prototype (opsional — default implement. Prototype = throwaway answer, bukan delivery)
- Uncertainty: Low / Medium / High  (opsional — flag task butuh research)
- Complexity: Low / Medium / High
- Done:
  - <kriteria konkret — kapan task ini selesai>
```

**Prototype task**: kalau `Type: prototype`, vertical-slice penuh gak wajib. Satu slice cukup explore question. Done criteria: answer captured di prototype-decision.md.

- **Layers check**: proposal cuma 1 layer? Flag: "Ini horizontal slice. Yakin mau pisah per layer, atau gabung jadi vertical?"
- **Demoable check**: "Setelah slice ini selesai, apa yang bisa di-demo / di-test?" Kalau jawabannya tidak ada — slice belum vertical.
- **Done criteria**: harus terukur. "Login berfungsi" ❌. "User bisa login pake email+password, test e2e pass, error message muncul untuk invalid credential" ✅.

### Iterasi

Minta user approve, merge (& gabung dependency), split (& pecah dependency), atau reorder. Iterasi sampai granularity dan dependency disetujui.

### Cycle Detection

Setiap kali user setuju dependency chain, cek cycle:
- Ambil semua TASK + depends yang sudah disepakati.
- Jalankan topological sort (Kahn's algorithm atau DFS + back edge).
- Kalau cycle terdeteksi: "TASK-1, TASK-3, TASK-5 membentuk cycle — tidak ada task yang bisa dimulai. Hapus atau reorder salah satu dependency?"
- Baru lanjut ke Step 4 setelah cycle resolved.

## Step 4 — Tulis ke tasks.md

### Format Standar

```markdown
# <Nama Fitur> — Tasks

**Queue**
- [ ] TASK-<nomor> | <Nama task> | Depends: <TASK-ID atau "none"> | Priority: critical | high | medium | low
    Detail: <end-to-end behavior, bukan implementasi per layer>
    Done:
    - [ ] <kriteria konkret — terukur>

**In Progress**
- [ ] TASK-<nomor> | <Nama task> | Depends: <TASK-ID atau "none"> | Priority: critical | high | medium | low
    (cut dari Queue, pindah ke sini — checkbox tetap [ ])

**Done**
- [x] TASK-<nomor> | <Nama task> | Depends: <TASK-ID atau "none"> | Priority: critical | high | medium | low
    (cut dari In Progress, ganti [ ] jadi [x])
```

Urutan task di **Queue**: priority critical → high → medium → low. Dalam satu level priority: unblocked (`Depends: none`) duluan, baru blocked. **Done** tidak perlu diurut — append ke bawah tiap selesai.

### Aturan Format

- **Depends**: separator koma + spasi (`TASK-1, TASK-2`). Kalau tidak ada dependency: `none`.
- **Priority**: huruf kecil semua — `critical | high | medium | low`. (Step 3 proposal juga pakai huruf kecil — konsisten)
- **Nomor TASK**: sequential, lanjut dari nomor tertinggi existing di file.
- **Detail**: 2-5 kalimat. Fokus behavior — apa yang harus muncul, bukan gimana implementasinya.
- **Done criteria**: minimal 2. Harus bisa di-verifikasi tanpa buka kode (test pass, API response, screenshot).
- **Group label**: `**Queue**`, `**In Progress**`, `**Done**`, `**Superseded**` — bold text, bukan heading markdown (`##`). Dipakai `implement` dan `status` untuk navigasi status.
- **Pindah task**: Queue→In Progress: cut baris, paste ke In Progress (checkbox tetap `[ ]`). In Progress→Done: cut, paste ke Done (append bawah), ganti `[ ]`→`[x]`.

### Validasi Sebelum Tulis

- Setiap TASK-ID di `Depends:` beneran ada di file.
- Priority value sesuai daftar (`critical|high|medium|low`).
- Tidak ada dependency cycle (re-check setelah finalisasi — user mungkin ubah dependency selama iterasi).
- Done criteria tidak ambigu (gak ada "seharusnya", "kiranya", "work properly").

Kalau ada yang invalid — tanya user, jangan tulis dulu.

### Splitting Task Existing

Task lama yang di-split — pindahkan ke **Superseded**:
```
**Superseded**
- [ ] ~~TASK-3 | Setup Login Page | Depends: none | Priority: critical~~
    Superseded by: TASK-3a, TASK-3b
```

- Judul strikethrough.
- Catat superseded-by.
- Transfer dependency: task lain yang depends on TASK-3 → ganti depends ke TASK-3a (sub-task pertama). Beri tahu user perubahan ini.

### Update Index

Tulis/update entry slug ini di `.agent-docs/issue-tracker.md`:

```yaml
tracker: local
features:
  - slug: <feature-slug>
    status: open
    source: to-prd | ask-me | manual
    created: <YYYY-MM-DD>
    updated: <YYYY-MM-DD>
    task_count: <total task>
    task_done: <task selesai — 0 pas baru dibuat>
```

Kalau slug belum ada — tambahkan.
Kalau slug sudah ada — update `updated`, `task_count`, `task_done`. Jangan overwrite `created` dan `source`.

### Catatan

- **Hindari hard-coded file path atau code snippet** — cepat basi.
- **Behavior focus**: deskripsi task fokus apa yang harus terjadi, bukan implementasi per layer.
- State task ditentukan oleh section heading (`**Queue**` / `**In Progress**` / `**Done**`), bukan checkbox. Checkbox `[x]` cuma buat Done.

## Step 5 — Finalisasi & Chain

- Beri tahu user daftar task + path tasks.md.
- Cek task tracker: ada task eligible (Todo, dependency none atau sudah Done)?
  - **Ada**: tanya user "Lanjut execute task pertama via `implement`? (y/n)".
    - User y → baca `implement/SKILL.md`, jalankan Step 1-5 manual di sesi ini (sama seperti chain `to-prd`→`to-issues`). Jangan invoke `implement` sebagai skill — routine manual.
    - User n → "Invoke `implement` kapan saja buat eksekusi task."
  - **Tidak ada semua task blocked**: "Semua task masih nunggu dependency. Selesaikan task blocker dulu via `implement`."
- Kalau ada slice dengan Uncertainty High atau butuh sharpen desain — flag spesifik: "TASK-4 butuh riset dulu — sarankan `ask-me` grill dalam sebelum eksekusi."

## Saran Skills Lain

- **Fitur sudah ada task di `tasks.md`** → `implement` (eksekusi task existing)
- **Belum ada PRD yang jelas** → `to-prd` dulu, baru chain ke `to-issues` lewat situ
- **Ada task butuh sharpen desain** → `ask-me` grill dalam (stress-test sebelum implementasi)
- **Task uncertainty High / desain belum solid** → `prototype` dulu (LOGIC atau UI), answer captured baru breakdown real task
