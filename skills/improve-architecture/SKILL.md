---
name: improve-architecture
description: Scan modul shallow (interface lebar) yang bisa di-deepen (interface kecil, behavior besar di baliknya). Filter pakai deletion test, presentasi laporan teks, lalu interview kandidat. Manual invoke, periodic health check.
disable-model-invocation: true
---

# Improve Architecture

## What It Does

Scan codebase, cari **deepening opportunities** — tempat modul shallow (interface hampir sekompleks yang disembunyikan) bisa jadi deep. Presentasi sebagai laporan teks terstruktur, lalu grill kandidat yang dipilih.

Tidak kasih daftar refactor generik. Tiap kandidat harus lolos **deletion test** — kalau modul ini dihapus, kompleksitas terkonsentrasi (jadi lebih kecil interface-nya) atau cuma pindah tempat? Cuma kasus "terkonsentrasi" yang masuk laporan. Filter ini yang cegah laporan jadi saran cleanup generik.

## When to Reach for It

Manual invoke saja — tidak auto-trigger.

Pakai sebagai health check periodik: tiap beberapa hari, atau saat codebase mulai terasa perlu lompat antar banyak modul kecil untuk paham satu konsep. Baca arsitektur existing, usulkan di mana perlu di-deepen.

## Deepening Opportunities

Inti skill: **depth**. Modul deep sembunyikan banyak fungsi di balik interface kecil & stabil. Modul shallow bocorkan implementasinya lewat interface yang hampir selebar kode di baliknya.

Cari tanda shallow:
- Pure function diekstrak cuma demi testability, padahal bug asli sembunyi di cara dia dipanggil (locality hilang)
- Modul bocor lintas seam
- Konsep yang butuh buka banyak file buat dipahami

Vocabulary arsitektur (module, interface, depth, seam, adapter, locality): definisi lihat `../VOCABULARY.md`. Di sini cukup contoh biar tetap readable:

- **Module** — contoh: `PaymentProcessor` class. Caller cuma panggil `processPayment(amount)`, implementasi tersembunyi.
- **Depth** — contoh dalam: `compress(file)` satu fungsi, banyak algoritma. Contoh dangkal: `setUsername(u)`, `setEmail(e)` terpisah.
- **Seam** — contoh: parameter `paymentGateway: PaymentGateway` di constructor.
- **Adapter** — contoh: `StripeAdapter implements PaymentGateway`.
- **Locality** — contoh: logic validasi email di satu file, bukan tersebar.

Kandidat disebut "deepen the Order intake module", bukan "refactor FooBarHandler". Plus istilah domain dari `.agent-docs/CONTEXT.md`.

## Laporan, Lalu Interview

Output: laporan teks (bukan HTML — sesuaikan environment agent). Tiap kandidat: file terkait, friksi, solusi plain-English, manfaat (locality/leverage), rating Strong/Worth Exploring/Speculative.

```markdown
## Architecture Improvement Report

**Rekomendasi Prioritas:** 1. Deepen <Nama Modul> (Strong)

### Kandidat 1: <Nama Modul>
**Files terkait:** <file1>, <file2>, <file3>
**Masalah:** <1-2 kalimat>
**Solusi yang Diusulkan:** <deepening yang diusulkan>
**Manfaat:**
- <manfaat 1>
- <manfaat 2>
**Rating:** Strong | Worth Exploring | Speculative
```

Rating **Strong** cuma untuk kandidat yang lolos deletion test (concentrates).

Klasifikasi dependency (dasar solusi yang diusulkan):

| Tipe dependency | Cara handle |
|---|---|
| Pure computation, in-memory | Selalu bisa dideepen, gabung modul |
| Ada local test stand-in | Bisa dideepen, test pakai stand-in |
| Internal service lintas network | Definisikan port, transport di-inject sebagai adapter |
| Third-party service | Terima sebagai injected port, test pakai mock adapter |

**Seam rule**: jangan buat seam kecuali ada yang benar-benar bervariasi. Satu adapter = hipotetis (mungkin gak perlu). Dua adapter = nyata (pattern justified).

Baca `.agent-docs/ADR.md` dulu — jangan re-litigasi keputusan lama. Munculkan konflik ADR cuma kalau friksinya nyata cukup dipertimbangkan ulang.

Setelah laporan tampil, berhenti — tanya kandidat mana yang mau di-interview. User pilih satu → jalankan interview: constraint, apa di balik seam, test apa yang bertahan. Update `.agent-docs/CONTEXT.md` inline kalau modul dinamai konsep baru. Tawarkan ADR kalau user tolak kandidat dengan alasan load-bearing.

**Escape hatch:** Kalau interview sudah >8 pertanyaan dan masih bergulir, sarankan user buat `handoff` ke sesi baru (biar context window tidak penuh dan fokus terjaga). Jangan paksa selesai dalam satu sesi.

**Opsional**: kandidat signifikan — tawarkan eksplorasi beberapa desain interface berbeda secara paralel (minimalist, flexible, ports & adapters), rekomendasikan yang terkuat.

## Where It Fits

**Periodic maintenance** — jalankan tiap beberapa hari, bukan step dalam chain.

Kombinasi relevan:
- `bug-diagnosis` — temuan arsitektur saat debug jadi kandidat di sini
- `code-review` — temuan arsitektur saat review, lanjut ke sini
- `implement` — cek deepening dulu sebelum implementasi fitur di area kompleks
- `project-migration` — health check sebelum migrasi
