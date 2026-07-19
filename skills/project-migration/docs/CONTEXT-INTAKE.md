# Context Intake

Dipakai di dua tempat: `setup-workflow` Step 3 (versi ringan, existing project) dan `project-migration` Step 1 (versi penuh, sebelum migrasi).

## Versi Ringan (setup-workflow)

Tujuan: isi awal `.agent-docs/CONTEXT.md`, bukan analisis mendalam.

Scan:
- Struktur folder top-level + pattern arsitektur yang kelihatan (MVC, MVVM, layered, dll)
- Dependency utama dari file manifest (`package.json`, `pubspec.yaml`, `build.gradle`, `Podfile`)
- Istilah domain yang muncul berulang di nama class/fungsi/comment

Output: entry `.agent-docs/CONTEXT.md` secukupnya untuk agent tidak "buta" saat mulai kerja. Tidak perlu lengkap — akan terus terisi lewat `ask-me` grill dan sesi kerja berikutnya.

## Versi Penuh (project-migration)

Tujuan: dasar untuk Risk Register (Step 2), jadi harus lebih dalam dari versi ringan.

Scan tambahan:
- Peta dependency antar modul — siapa memanggil siapa, coupling tersembunyi
- Modul mana yang shallow (interface hampir sekompleks implementasinya) vs deep
- Test coverage existing per area — area tanpa test = risk tinggi otomatis
- Cross-check terhadap `.agent-docs/ADR.md` — keputusan mana yang sudah final, jangan diusulkan ulang tanpa alasan kuat

Output: draft awal tiap entry Risk Register (`RISK-REGISTER-TEMPLATE.md`) — problem, dependency type, seam status per kandidat.

## Prinsip

Jangan mulai propose solusi di tahap ini. Context intake murni observasi — solusi/migration plan baru masuk di Step 3 `project-migration`.
