---
name: ask-me
description: Jalur utama + grill. Auto-trigger saat user minta bantuan umum ("gimana caranya", "mau nambah X", "bantu aku Y", "lanjutin kerjaan"). Untuk fitur baru, jalanin 3-5 pertanyaan grill dulu sebelum routing. Skip kalau user sudah sebut skill eksplisit, atau sinyal match bug-diagnosis.
model-invocation: enabled
---

# Ask Me

Router atas semua skill dev. Untuk fitur baru — grill dulu, lalu arahkan ke skill yang tepat.

## Setup Awal (Pertama Kali)

**Kalau ini pertama kali pakai kumpulan skill dev di repo ini:**

1. `.agent-docs/project-meta.md` belum ada (belum pernah jalankan `setup-workflow`)
2. User invoke `ask-me` (natural first step)
3. `ask-me` deteksi marker tidak ada, arahkan ke `setup-workflow` dulu
4. User harus manual invoke: `setup-workflow`
5. Setelah `setup-workflow` selesai, baru gunakan `ask-me` untuk routing semua task berikutnya

Setelah setup awal satu kali, `setup-workflow` tidak perlu dijalankan lagi.

## Prasyarat

`.agent-docs/project-meta.md` harus sudah ada. Kalau belum → arahkan `setup-workflow`, stop.

## Jalur Utama

Kebanyakan kerjaan lewat satu jalur ini. Tiap skill punya posisi — bukan cuma daftar.

### 1. Grill (Step 2 di bawah)
3-5 pertanyaan. Output: scope, behavior, terminologi. Nentuin jalur berikutnya.

### 2. Build — `implement`
Hasil grill langsung dipakai `implement`. Gak perlu task breakdown untuk perubahan kecil.
Untuk perubahan besar, grill dalam → `to-prd` → `to-issues` baru `implement`.

### Off-ramps (keluar dari jalur utama, balik lagi nanti)
- **Bug ketemu** → `bug-diagnosis`. Balik setelah fix.
- **Arsitektur menghalangi** → Catat, jangan perbaiki sekarang. Nanti `improve-architecture`.
- **Sesi kepanjangan** → `handoff`. Lanjut di sesi baru.
- **Mau migrasi project** → `project-migration`. Standalone, bukan feature work.
- **Desain belum solid / perlu explore** → `prototype`. Validasi dulu, balik setelah answer captured.

## Step 1 — Deteksi Intent

Baca permintaan user, map ke tabel:

| Sinyal | Jalur |
|---|---|
| "tambah fitur baru", "buat halaman baru", "mau bikin X" — belum ada breakdown | **→ Step 2 (Grill)** |
| "kerjakan task X", "lanjut task berikutnya", "implement task dari tasks.md" | `implement` — dari tasks.md atau hasil grill. Jangan buat bug fix. |
| "error", "bug", "crash", "gagal", "lambat", paste stack trace | `bug-diagnosis` — 6-phase heavy. Bukan buat fitur baru atau bug trivial. |
| "buat PRD", "dokumentasikan fitur ini", "tulis spec" | `to-prd` — sintesis percakapan/grill. Jangan tanpa input jelas. |
| "pecah jadi task", "breakdown plan ini", "buat daftar task implementasi" | `to-issues` — breakdown spec jadi task. Jangan tanpa PRD/plan matang. |
| "refactor", "kode ini susah dibaca", "modul ini berantakan" — project sama, tidak pindah | `improve-architecture` — health check. Jangan di tengah implementasi fitur. |
| "migrasi", "pindah dari project lama", "port ke project baru" | `project-migration` — lintas project. Bukan buat refactor in-place. |
| "review perubahan ini", "cek diff sejak X", "vet sebelum commit" | `code-review` — 2-axis. Jangan sebelum ada perubahan. |
| "handoff", "compact sesi ini", "lanjut di sesi lain" | `handoff` — bridge ke sesi baru. Compact cukup kalau thread sama. |
| "gua lagi di mana", "status", "lagi ngerjain apa", "posisi sekarang" | `status` — read-only snapshot. |
| "coba explore", "test ide", "spike", "prototype", "ragu sama desain", "coba dulu sebelum implement" | `prototype` — LOGIC atau UI tergantung pertanyaan. Tanya dulu: logic/state atau visual/layout? |
| Ambigu, cocok >1 skill | Tanya user, tampilkan 2-3 opsi, lalu redirect. |
| `.agent-docs/` tidak ada | **→ `setup-workflow`** |

Kalau result != "→ Step 2 (Grill)" — langsung ke Step 3 (Konfirmasi), skip Step 2.

## Step 2 — Grill (khusus fitur baru)

Hanya jalan kalau intent "tambah fitur baru". Baca `.agent-docs/CONTEXT.md` dan `.agent-docs/ADR.md` dulu sebelum tanya.

Tanya satu per satu, tunggu jawaban. Skip yang sudah jelas dari percakapan.

1. **Behavior** — "Apa yang harus terjadi dari sisi user?" (bukan cara implementasi)
2. **Terminologi** — "Ini istilah baru atau sinonim dari `<istilah existing>`?" — validasi bentrok sama CONTEXT.md
3. **Scope** — "Satu modul atau lintas modul?"
4. **Constraint** — "Ada batasan teknis/bisnis?"
5. **Priority** — "MUST (critical path) atau NICE?"

Setiap istilah baru → update `.agent-docs/CONTEXT.md` inline. Format: `## <Istilah> — <definisi>`. Kalau bentrok — klarifikasi dulu sinonim atau konsep beda.

### Grill Dalam — untuk scope besar / ambigu / new project

Dua mode tergantung situasi:

#### Mode Sharpen — fitur besar di existing project

Kalau hasil grill menunjukkan scope besar (lintas modul) atau banyak ambigu di project
 yang sudah punya CONTEXT.md, lanjut ke 5 poin:

1. **Domain model** — "Apa istilah kunci di area ini? Ada bentrok dengan CONTEXT.md?"
2. **Keputusan arsitektur** — "Ada keputusan yang hard to reverse?"
   Catat ADR kalau lolos 3 filter: hard to reverse, surprising without context, real trade-off.
3. **Validasi kode** — "Klaim ini cocok sama kode existing?" Eksplorasi codebase untuk validasi.
4. **Dependency** — "Modul ini bergantung ke apa? Ada seam?"
5. **Test** — "Area ini udah punya test? Butuh characterization test dulu?"

#### Mode Bangun Domain — new project (dari setup-workflow)

Kalau CONTEXT.md kosong (new project) dan dipanggil dari `setup-workflow`,
pakai interview loop:

- Satu pertanyaan per giliran. Rekomendasi jawaban — user tinggal konfirmasi/koreksi.
- Gak ada batas jumlah tanya. Loop sampai domain model crystallize.
- Fokus: terminology inti, konsep, hubungan antar entitas, batasan sistem.
- Jangan tanya hal yang bisa diekstrak dari code scaffold (nama folder, dependency).
- Output: CONTEXT.md terisi penuh + ADR pertama untuk keputusan arsitektur awal.

#### Aturan (berlaku untuk kedua mode):
- Update CONTEXT.md inline tiap istilah baru. Format: `## <Istilah> — <definisi>`.
- Kalau pertanyaan bisa dijawab dari eksplorasi codebase → eksplorasi dulu.
- Kalau dipanggil dari `setup-workflow`, selesai sesi → lanjut ke Step 4 setup-workflow.

### Tentukan Jalur

| Scope | Rekomendasi |
|---|---|
| Kecil (1 modul), behavior jelas | `implement` langsung — hasil grill jadi input |
| Besar (lintas modul) | Grill dalam → `to-prd` (chain ke `to-issues`) |
| Banyak ambigu / desain belum solid | Grill dalam → `prototype` — validasi dulu sebelum spec |
| State machine / logic complex | `prototype` LOGIC — explore edge case lewat terminal TUI |
| UI layout belum decided | `prototype` UI — bandingkan varian layout |

Tampilkan ringkasan + rekomendasi ke user, lalu lanjut Step 3.

## Step 3 — Konfirmasi

State assumption: "Ini masuk kategori [skill/rekomendasi], lanjut?" — user konfirmasi atau koreksi.

## Step 4 — Redirect

Arahkan user ke skill terpilih. Contoh: "Ini masuk `implement`, lanjut di sana."

## Catatan

**Multi-Agent Environment:** Kalau user switch antara agent (misal dari Pi Agent ke Antigravity CLI), marker `.agent-docs/project-meta.md` tetap persist di workspace. `ask-me` di agent baru akan detect marker itu, tidak perlu re-run `setup-workflow`.

## Tips

- **User sudah eksplisit sebut nama skill** → invoke skill itu langsung (e.g., `implement`), `ask-me` bisa dilewati. Router hanya untuk yang bingung pilih skill mana.
- **Cek setup:** Sebelum route, cek `.agent-docs/project-meta.md` ada tidak. Kalau belum, arahkan ke `setup-workflow` dulu — stop, jangan lanjut routing.

## Aturan Sesi

### Single-session
- Grill + implement kecil: selesai 1 sesi.

### Multi-session
- Grill dalam + to-prd + to-issues: 1 sesi, jangan compact di tengah.
- handoff sebelum tutup sesi.
- implement per task di sesi fresh.

### Bug di tengah feature
1. handoff feature context (state, progress, BASE_COMMIT kalau ada).
2. bug-diagnosis sesi terpisah.
3. handoff hasil fix.
4. Balik ke feature, refer handoff.

### Compact vs Handoff
| Situasi | Pakai |
|---|---|
| Sesi normal, masih jauh dari limit | Lanjut |
| Thread sama, context penuh | Compact (bawaan agent) |
| Ganti task/phase, mulai fresh | handoff dulu |
| Tengah phase (grill/spec/implement) | handoff — jangan compact |

## Guard Auto-Trigger

Skill ini `model-invocation: enabled` — auto-jalan. Rules:

- User sudah sebut nama skill eksplisit → jangan trigger.
- Sinyal user match tabel trigger `bug-diagnosis` (error/bug/crash/stack trace) → jangan trigger, biarkan `bug-diagnosis` yang ambil.
- Skill eksekusi lain (implement, to-prd, dst) tetap `disable-model-invocation: true` — cuma routing + grill yang auto, eksekusi tetap butuh konfirmasi user.
