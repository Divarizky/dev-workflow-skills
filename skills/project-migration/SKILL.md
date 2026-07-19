---
name: project-migration
description: Migrasi dari project lama ke project baru. Tentukan strategi (migration-approach, cutover-strategy) dulu, lalu context intake, risk register, migration plan per slice, safety net, migrate, validate. User-invoked.
disable-model-invocation: true
---

# Project Migration

Migrasi project lama ke project baru dengan risiko terkendali. Bukan deepening in-place — itu domain `improve-architecture`.

Kalau project baru (target migrasi) belum di-`setup-workflow`, jalankan `setup-workflow` dulu di project baru itu supaya `.agent-docs/` (CONTEXT/ADR) punya tempat konsisten. Bukan gate keras — saran, biar context jelas sebelum intake.

## Vocabulary

Vocabulary arsitektur (module, interface, depth, seam, adapter, locality): definisi penuh lihat `../VOCABULARY.md`. Contoh saja di sini:

- **Module** — `PaymentProcessor` class. Caller cuma panggil `processPayment(amount)`.
- **Depth** — dalam: `compress(file)`. Dangkal: `setUsername(u)`, `setEmail(e)` terpisah.
- **Seam** — parameter `paymentGateway: PaymentGateway` di constructor.
- **Adapter** — `StripeAdapter implements PaymentGateway`.
- **Locality** — logic validasi email di satu file, bukan tersebar.

## Step 1 — Lokasi Project Lama

Tanya user dulu: **project lama berupa file path lokal atau repository (GitHub/GitLab/URL)?**

**Kalau file path lokal**:
- Tanya absolute path, ditulis eksplisit
- Agent scan langsung

**Kalau repository**:
- Tanya URL repo
- Tanya branch/tag spesifik kalau ada (default: branch utama)
- Clone ke folder sementara di working directory project baru (contoh: `_migration-source/`)
- Setelah clone selesai, path scan = folder hasil clone

**Kalau tidak bisa diakses langsung** (server lain, tidak ada akses network) — user export/describe manual.

Simpan ke `.agent-docs/.scratch/migration/meta.md` (bukan `project-meta.md` — state migrasi transient, terpisah dari marker permanen):
```
migration_source: <absolute path project lama, atau path folder hasil clone, atau "manual" kalau tidak bisa diakses langsung>
migration_source_type: <local|repository|manual>
```

## Step 2 — Tentukan Strategi

Baca `docs/MIGRATION-APPROACH.md` — tanya 2 pertanyaan (platform sama/beda, tujuan migrasi), tentukan Opsi A (Bangun Ulang) atau B (Pindahkan + Sesuaikan).

Baca `docs/CUTOVER-STRATEGY.md` — tanya 2 pertanyaan (boleh downtime atau tidak, toleransi durasi), tentukan Opsi A (Bertahap) atau B (Sekali Jalan).

Catat hasil di `.agent-docs/.scratch/migration/meta.md` (tambahan field, file yang sama dari Step 1):
```
migration_approach: <rewrite|port>
cutover_strategy: <phased|bigbang>
```

## Step 3 — Context Intake

Lihat `docs/CONTEXT-INTAKE.md`. Scan struktur folder, dependency, pattern arsitektur project **lama** — pakai path dari `migration_source` (Step 1), bukan working directory saat ini. Baca `.agent-docs/CONTEXT.md` dan `.agent-docs/ADR.md` (project baru) — jangan re-litigasi keputusan final tanpa alasan kuat.

## Step 4 — Risk Register

Lihat `docs/RISK-REGISTER-TEMPLATE.md`. Identifikasi area rawan break, modul kandidat migrasi, seam yang tidak ada.

Klasifikasi dependency tiap kandidat:

| Tipe dependency | Cara handle |
|---|---|
| Pure computation, in-memory | Migrasi langsung, test lewat interface baru |
| Ada local test stand-in | Migrasi pakai stand-in di test suite |
| Internal service lintas network | Definisikan port, transport di-inject sebagai adapter |
| Third-party service | Terima sebagai injected port, test pakai mock adapter |

## Step 5 — Migration Plan (Vertical Slice)

Pecah migrasi per modul, bukan big-bang kode (kecuali `cutover_strategy: bigbang` — beda dengan cara tulis kode, ini soal rilis akhir).

Kalau `migration_approach: rewrite` — tiap slice ikuti proses `implement` (spec ulang, TDD dari nol).
Kalau `migration_approach: port` — tiap slice ikuti proses `bug-diagnosis` mindset (characterization test dulu, jaga behavior identik).

Kalau `cutover_strategy: phased` — urutkan slice per fitur, definisikan cara dua sistem jalan bersamaan (routing, data sync).
Kalau `cutover_strategy: bigbang` — urutkan slice bebas berdasarkan risk register, tidak perlu step koordinasi dua sistem.

## Step 6 — Test Safety Net

Sebelum ubah kode: kalau belum ada test di area yang disentuh, tulis characterization test dulu — capture behavior existing termasuk bug yang belum waktunya diperbaiki.

## Step 7 — Migrate

Eksekusi slice sesuai Step 5. Update `.agent-docs/CONTEXT.md` inline kalau modul dinamai konsep baru.

## Step 8 — Validate

Regression test penuh tiap slice selesai — pastikan slice lain tidak ikut pecah.

Setelah semua slice lolos validasi: hapus state migrasi transient — folder `.agent-docs/.scratch/migration/` dan clone `_migration-source/` (kalau ada). State migrasi cuma relevan selama proses; project baru sudah berdiri sendiri.

## ADR — Kapan Catat

Tawarkan ADR kalau user tolak satu pendekatan migrasi dengan alasan load-bearing. Skip untuk alasan sementara.

## Saran Skills Lain

- **Deepening/refactor tanpa pindah project** → pakai `improve-architecture` (lebih ringan, in-place)
- **Perubahan/fitur kecil, tidak menyentuh struktur modul** → pakai `ask-me` grill → `implement`
- **Bug fix di project existing** → pakai `bug-diagnosis` (fokus debug, bukan migrasi)
