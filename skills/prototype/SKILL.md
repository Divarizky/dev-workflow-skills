---
name: prototype
description: Build throwaway prototype to answer a design question — state/logic exploration via TUI terminal, or UI variant comparison. Use when user wants to sanity-check a state model, explore logic edge cases, or compare layout options before committing to implementation.
disable-model-invocation: true
---

# Prototype

**Throwaway code that answers one question.** The question decides the shape.

Cabang otomatis dari pertanyaan user:

| Pertanyaan | Cabang |
|---|---|
| "Apakah state machine / reducer ini handle edge case X?" | `docs/LOGIC.md` — terminal TUI |
| "Gimana kalo tampilannya beda?" | `docs/UI.md` — variant switcher |

Kalau pertanyaan ambigu dan user tidak reachable — default ke LOGIC (backend/logic-heavy) atau UI (frontend-heavy). State assumption di atas prototype.

## Aturan Universal

1. **Throwaway sejak hari pertama, jelas tandanya.** Nama file/fungsi/route mengandung `prototype` atau `_proto`. Jangan samar jadi production code.
2. **Satu command untuk run.** Apapun task runner project — `dart run`, `flutter run`, `npm run`, `swift run`, `python`, `bun`. User tinggal ketik tanpa mikir path.
3. **No persistence.** State in-memory. Persistence cuma kalo pertanyaan eksplisit tentang DB — itu pun pake scratch DB atau file lokal bernama `PROTOTYPE-wipe-me`.
4. **Skip polish.** No tests, no error handling di luar yang bikin prototype runnable, no abstraksi. Poin: belajar sesuatu secepat mungkin.
5. **Surface state.** Setiap action (LOGIC) atau tiap switch variant (UI), tampilkan state penuh — user lihat apa yang berubah.
6. **Capture saat selesai.** Validated decision → fold ke real code. Prototype → commit ke throwaway branch (jangan main). Answer → tulis di `.agent-docs/.scratch/<slug>/prototype-decision.md`.

## Capture Format

```markdown
# Prototype Decision — <nama>

**Question:** <satu kalimat>
**Branch:** LOGIC | UI
**Answer:** <kesimpulan>
**Date:** <YYYY-MM-DD>
**Prototype branch:** <nama branch>

**What was validated:** <bagian yang diambil ke real code>
**What was discarded:** <bagian yang di-throwaway>
```

## Anti-patterns

- **Test.** Prototype yang butuh test bukan prototype lagi.
- **Generalise.** "Nanti kalo perlu X tinggal tambah" — stop. Jawab satu pertanyaan.
- **Blur logic & TUI** (LOGIC). Pure module harus bisa di-lift tanpa bawa terminal code.
- **Variants beda warna doang** (UI). Beda struktur, bukan beda skin.
- **Promote langsung ke production.** Prototype ditulis tanpa test, error handling, abstraksi. Tulis ulang proper saat fold.

## Kapan Pakai vs Skip

| Situasi | Action |
|---|---|
| State machine rawan edge case | LOGIC |
| API contract belum fix | LOGIC (mock + terminal) |
| Layout UI belum decided | UI |
| Task sederhana, behavior jelas | Skip — `implement` langsung |
| Refactor code existing | Skip — `improve-architecture` |
| Persistensi / network call real | Skip — prototype no persistence |
