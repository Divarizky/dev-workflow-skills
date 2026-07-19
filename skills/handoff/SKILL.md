---
name: handoff
description: Compact percakapan aktif jadi dokumen handoff untuk sesi/agent lain. Simpan di .agent-docs/handoffs/ (workspace), bukan temp directory OS. User-invoked.
disable-model-invocation: true
---

# Handoff

## Prasyarat

`.agent-docs/project-meta.md` harus ada (setup-workflow sudah pernah jalan). Tidak ada → arahkan ke `setup-workflow`, stop.

Beda dari fitur "compact" bawaan agent — compact ringkas seluruh histori untuk lanjutkan thread yang sama. Handoff ambil **slice** konteks relevan buat task baru, sesi awal tetap utuh (bukan diganti).

## Step 1 — Tulis Dokumen

Simpan ke `.agent-docs/handoffs/<timestamp>-<slug>.md` — dalam workspace, bukan temp directory OS (tidak semua environment agent punya akses eksplisit ke `$TMPDIR`/`/tmp`/`%TEMP%`). Bikin folder `.agent-docs/handoffs/` dulu kalau belum ada.

Nama file: timestamp (`YYYY-MM-DD`) + slug deskriptif singkat.

## Step 2 — Isi Dokumen

- Ringkasan progres saat ini
- Keputusan yang sudah dibuat
- Open question / next step
- **Section wajib**: "Suggested Skills" — skill mana dari kumpulan skill dev yang harus dipanggil sesi berikutnya (`ask-me`, `implement`, `bug-diagnosis`, `improve-architecture`, `project-migration`, `to-prd`, `to-issues`, `code-review`, `handoff`)
- **Kalau sesi tengah jalanin `implement` yang belum sampai review**: sertakan spec/task detail relevan (behavior, interface, edge case dari grill, atau Detail task) — bukan cuma commit reference. Tetap ringkas ke handoff biar sesi baru tidak perlu buka file lain buat ngerti konteks.

## Aturan Reference-Only

Jangan duplikasi konten yang sudah ada di artifact lain (PRD, tasks.md, ADR, issue, commit, diff). Reference by path/URL — jangan copy isi.

**Kecuali:** snippet kecil (<5 baris, misal error trace atau log singkat) yang lebih jelas di-inline daripada di-reference. Inline snippet pakai backtick atau blockquote.

## Redaksi

Redact informasi sensitif — API key, password, PII — sebelum tulis ke file.

**Pola redaksi yang harus discan:**
- `sk-...` (API key pattern — 30+ karakter setelah prefix)
- `AKIA...` (AWS access key)
- `ghp_...`, `gho_...`, `github_pat_...` (GitHub token)
- `-----BEGIN.*KEY-----` (private key block)
- `Bearer [a-zA-Z0-9\-_]+` (JWT / token auth header)
- `password=`, `passwd=`, `secret=` di inline values
- Email: `user@example.com` — redact jadi `user@***`
- IP internal: `10.`, `172.16-31.`, `192.168.` — redact
- `DATABASE_URL`, `REDIS_URL`, `AWS_SECRET_KEY` — redact value

Jangan hanya andalkan scan manual. Kalau ragu, tanya user: "Ada informasi sensitif di konteks ini yang perlu diredact?"

## Step 3 — Tailor (Opsional)

Kalau user kasih argumen deskripsi fokus sesi berikutnya — sesuaikan isi dokumen ke fokus itu, bukan ringkasan generik seluruh percakapan.

## Kapan Pakai

- Sesi kerja terlalu panjang, context window mendekati limit
- Mau eksplorasi side-quest (misal nemu bug arsitektur saat kerja fitur) tanpa polusi konteks task utama — buat handoff, buka sesi baru untuk side-quest, kembali ke sesi awal setelah selesai
- Ganti device/environment (misal lanjut kerja di Antigravity setelah mulai di Pi Agent)

## Saran Skills Lain

- **Sesi masih pendek, jauh dari context limit** → lanjutkan sesi biasa, handoff belum diperlukan
- **Butuh compact ringkas untuk lanjutkan thread yang sama** → gunakan fitur "compact" bawaan agent (bukan handoff — handoff ambil slice relevan untuk task baru, compact ringkas seluruh histori)
