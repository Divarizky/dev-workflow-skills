---
name: bug-diagnosis
description: Diagnosis loop disiplin untuk bug sulit, crash, atau performance regression yang tidak langsung ketemu akar masalahnya (6 phase — reproduce, minimise, hypothesise, instrument, fix, regression-test). Trigger saat user menyebut kata seperti "bug", "error", "crash", "perbaiki", "fix", "kenapa gagal", "kok gak jalan", "stack trace", "exception", atau "regression". Heavy, pastikan mau lanjut sebelum trigger. Cocok dipakai saat butuh reproduksi terlebih dulu, ada stack trace/error log untuk dibedah, atau bug bersifat intermittent/sulit dilacak. Bukan untuk fix trivial yang penyebabnya sudah jelas.
model-invocation: enabled
---

# Bug Diagnosis

Disiplin untuk bug sulit. Skip phase hanya kalau ada justifikasi eksplisit — jangan lompat ke fix tanpa alasan jelas.

## Prasyarat

`.agent-docs/project-meta.md` harus ada (`setup-workflow` sudah pernah jalan). Tidak ada → arahkan ke `setup-workflow`, stop. Skill ini heavy (6 phase, butuh context) — jangan jalan tanpa setup walau auto-trigger.

## Sebelum Mulai

Baca `.agent-docs/CONTEXT.md` (kalau ada) untuk mental model modul terkait. Cek `.agent-docs/ADR.md` untuk keputusan arsitektur di area yang mau disentuh — jangan salah duga pattern yang sebenarnya sengaja.

## Phase 1 — Reproduce

**Tight loop adalah skill ini.** Segala sesuatu (bisection, hypothesis-testing, instrumentation) adalah mekanis kalau sinyal sudah ada. Alokasikan effort disproporsional di sini.

Cari sinyal pass/fail yang cepat, deterministik, bisa dijalankan agent berulang kali. Tanpa sinyal jelas → tidak akan ketemu akar masalah walau baca kode berjam-jam.

**Opsi sinyal (prioritas tinggi ke rendah):**
1. **Test di seam yang menjangkau bug** — unit, integration, widget, atau UI test (Espresso, XCTest, Playwright, Cypress, `flutter test`, dll)
2. **API/HTTP repro** — curl, Postman, script HTTP, replay request dari dev tools
3. **Log/grep** — logcat, console.log, server log, crash trace — filter + dump state
4. **CLI diff** — banding output (response JSON, screenshot, file dump) before/after
5. **Minimal isolated project** — clone/scaffold minimal yang masih reproduce bug, pisah dari codebase utama
6. **git bisect run** — cari commit pertama yang introduce bug
7. **Differential run** — banding 2 env (staging vs prod, 2 device, 2 browser, 2 API version, 2 build variant)
8. **Fuzz/stress** — input random, parallel request, rapid click — untuk intermittent crash atau race condition
9. **Screenshot/snapshot diff** — untuk UI regression visual
10. **Manual step-by-step** — last resort, catat tiap langkah pasti

**Non-deterministic bug (repro rate <100%):** target bukan repro bersih, tapi tingkatkan **reproduction rate**. Loop trigger, paralelkan, tambah stress, incremental env complexity — sampai flake bisa di-debug.

## Phase 2 — Minimise

Perkecil reproduksi ke elemen paling sedikit yang masih memicu bug. Kenapa penting: mempersempit ruang hipotesis di Phase 3, dan jadi regression test yang bersih di Phase 5.

Kalau seam yang ada terlalu dangkal (test single-caller padahal bug butuh multiple caller) → regression test di situ kasih false confidence. Kalau tidak ada seam yang benar sama sekali → itu sendiri temuan penting. Catat, arsitektur codebase menghalangi bug ini di-lock-down — sarankan user invoke `improve-architecture` terpisah nanti (bukan otomatis).

**Kriteria seam:**
- **Good seam** — dapat isolate komponen yang bug saat ini dari dependencies-nya. Test di seam ini hanya perlu mock/fake interface kecil, bukan setup infrastruktur kompleks.
- **Bad/shallow seam** — test harus mock banyak dependency (network, DB, service lain) atau hanya bisa test surface behavior (return code saja, logic di baliknya tidak terjangkau). Bug di logic bisa lolos test surface ini.

Kalau seam yang ada masuk kategori bad — jangan lanjut Phase 3 dulu. Prioritaskan buat seam yang lebih baik (definisi test port/adapter baru) sebelum lanjut hypothesise. Atau catat sebagai temuan arsitektur untuk `improve-architecture`.

## Phase 3 — Hypothesise

Buat daftar hipotesis, ranking dari paling mungkin. Tiap hipotesis harus punya prediksi konkret — kalau tidak bisa nyatakan prediksinya, itu cuma tebakan, buang atau pertajam.

Tampilkan ranking ke user sebelum mulai testing. User sering punya konteks domain yang langsung re-rank ("baru deploy perubahan di kandidat #3") atau tahu hipotesis mana yang sudah pernah dieliminasi. Jangan block kalau user tidak respon — lanjut pakai ranking sendiri.

## Phase 4 — Instrument

Tiap probe harus map ke prediksi spesifik dari Phase 3. Ubah satu variabel per waktu.

Prioritas alat:
- Debugger/REPL inspection kalau environment support — satu breakpoint lebih baik dari sepuluh log
- Targeted log di titik yang membedakan hipotesis. Jangan "log semua lalu grep"
- Tag tiap debug log dengan prefix unik (misal `[DEBUG-a4f2]`) untuk cleanup gampang di akhir

## Phase 5 — Fix

Ubah minimised repro (Phase 2) jadi failing test di seam yang tepat. Lihat gagal → apply fix → lihat lolos → jalankan ulang skenario original (bukan yang di-minimise) untuk konfirmasi penuh.

## Phase 6 — Regression Test

Test dari Phase 5 tetap tinggal di suite — cegah bug sama muncul lagi.

Catat hipotesis yang terbukti benar di commit message — supaya debugger berikutnya belajar dari ini.

**Maintenance**: test regression adalah tanggung jawab berkelanjutan. Kalau test jadi flaky atau stale setelah refactor, jangan diamkan — gunakan `improve-architecture` health check untuk deteksi test yang perlu dirapikan.

## Setelah Selesai

Tanya: apa yang akan mencegah bug ini dari awal? Kalau jawabannya melibatkan perubahan arsitektur (tidak ada seam test yang baik, caller kusut, coupling tersembunyi) → sarankan user invoke `improve-architecture` terpisah, dengan detail spesifik.

## AFK — Rekomendasi Tanpa User Aktif

Skill ini bisa auto-trigger (`model-invocation: enabled`), termasuk saat user AFK. `improve-architecture` bersifat interaktif — butuh jawaban user tiap step, dan memang tidak diinvoke otomatis (lihat catatan di atas).

Kalau rekomendasi invoke `improve-architecture` muncul dan user AFK: catat rekomendasi di commit message atau log sesi, berhenti di situ. User invoke manual saat kembali aktif.
