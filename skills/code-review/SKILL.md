---
name: code-review
description: Review diff sejak fixed point (commit/branch/tag, atau "none" untuk repo baru) 2 axis — Standards dan Spec — paralel sub-agent, tidak saling polusi. User-invoked.
disable-model-invocation: true
---

# Code Review

Dua axis review, dijalankan terpisah supaya tidak saling pengaruh:

- **Standards** — kode ikuti konvensi project?
- **Spec** — kode implementasi sesuai issue/PRD asal?

## Prasyarat

`.agent-docs/project-meta.md` harus ada (`setup-workflow` sudah pernah jalan). Tidak ada → arahkan ke `setup-workflow`, stop.

### Dipanggil dari Skill Lain (Chain)

Skill ini bisa dipanggil dari `implement` (chain `to-prd`→`to-issues`→`implement`→`code-review`). Karena `disable-model-invocation: true`, skill lain tidak bisa auto-invoke. Sebaliknya, `implement` akan **baca `code-review/SKILL.md` dan jalankan Step 1-5 manual** dalam sesi yang sama (sama seperti chain `to-prd`→`to-issues`).

Saat dipanggil dari chain (`implement`), spec + fixed point + diff range sudah tersedia di konteks percakapan — Step 2 opsi 1 (inline dari caller) akan trigger duluan.

## Step 1 — Validasi Fixed Point

Fixed point bisa berupa commit hash atau `none` (repo baru, belum ada commit).

- **Commit hash**: jalankan `git rev-parse <fixed-point>`. Kalau gagal → tanya user, stop.
- **`none`** (repo baru, belum ada commit): skip rev-parse. Diff pakai empty tree hash: `git diff --stat 4b825dc642cb6eb9a060e54bf899d1530363a3b7 HEAD`. Kalau error karena belum ada commit sama sekali — diff working tree vs empty: `git diff --no-index /dev/null <file-path>` untuk tiap file baru.

Pastikan diff tidak kosong. Kalau diff kosong — stop, beri tahu user tidak ada perubahan untuk direview.

## Step 2 — Cari Sumber Spec

Prioritas (coba satu per satu, stop kalau ketemu):

1. **Inline dari caller** — kalau dipanggil dari `implement` (Detail task + Done criteria, atau hasil grill), spec sudah ada di konteks percakapan. Pakai itu. Format inline bisa include `Detail:` dan `Done:` — gunakan keduanya untuk evaluate completeness.
2. **File PRD** — `.agent-docs/.scratch/<slug>/PRD.md` — cocokkan slug dari nama branch/fitur. Slug: ambil segment terakhir setelah `/`. Contoh: `feature/user-auth` → slug `user-auth`. `fix/login-error` → slug `login-error`. Kalau branch tidak pakai separator `/` — slug = nama branch utuh.
3. **Detail task** — `.agent-docs/.scratch/<slug>/tasks.md` — format tasks.md sekarang: `**Queue**` / `**In Progress**` / `**Done**` (bold label, bukan section heading). Ambil field `Detail:` dari task yang relevan.
4. **Path dari user** — user kasih lokasi file spec langsung. Validasi file exists dan readable sebelum baca. Kalau tidak ada atau tidak readable — kembali ke opsi 1-3, jangan lanjut dengan data rusak. Beri tahu user path tidak valid.

Kalau tidak ketemu — tanya user. Kalau user bilang tidak ada — sub-agent Spec skip, laporkan "no spec available".

## Step 3 — Cari Sumber Standards

File apapun di repo yang dokumentasikan cara nulis kode (`CODING_STANDARDS.md`, `CONTRIBUTING.md`, dll).

Di luar itu, axis Standards selalu bawa **smell baseline** tetap (Fowler, *Refactoring* ch.3) — berlaku walau repo tidak dokumentasikan apapun:

- **Speculative Generality** — abstraksi/parameter/hook buat kebutuhan yang belum ada di spec → hapus, inline balik sampai kebutuhan nyata muncul
- **Message Chains** — navigasi `a.b().c().d()` panjang yang caller tidak seharusnya bergantung → sembunyikan di balik satu method
- **Middle Man** — class/fungsi yang cuma delegasikan ke tempat lain → potong, panggil target asli langsung
- **Refused Bequest** — subclass/implementer yang abaikan sebagian besar yang diwarisi → drop inheritance, pakai composition

## Step 4 — Jalankan Paralel

Kirim satu pesan, dua panggilan sub-agent (general-purpose), tanpa saling lihat konteks:

**Sub-agent Standards** dapat: full diff command + commit list (kalau fixed point `none`, list kosong — inform sub-agent), file standards yang ditemukan, smell baseline lengkap.
Brief: laporkan per file/hunk tempat diff langgar standard terdokumentasi (kutip sumber + rule), plus smell baseline yang terdeteksi. Bedakan hard violation vs judgement call. Skip yang sudah dihandle tooling otomatis. Di bawah 400 kata.

**Sub-agent Spec** dapat: full diff command + commit list, path/isi spec (termasuk `Done:` criteria kalau ada).
Brief: laporkan (a) requirement dari spec yang hilang/parsial, (b) behavior di diff yang tidak diminta (scope creep), (c) requirement yang kelihatan diimplementasi tapi salah, (d) **Done criteria** — mana yang terpenuhi dan mana yang tidak (kalau `Done:` tersedia di spec). Kutip baris spec tiap temuan. Di bawah 400 kata.

**Fallback (Sequential):** Kalau paralel sub-agent tidak support (misal keterbatasan platform), jalankan Standards dulu — laporkan — baru Spec. Output tetap dipisah di heading masing-masing (`## Standards` / `## Spec`), jangan merge.

### Error Handling Sub-Agent

Kalau salah satu sub-agent gagal (timeout, tool error, output tidak sesuai format):
- Jangan block review total.
- Laporkan partial result: "Standards: [result], Spec: [error — gagal dijalankan]".
- Tetap tampilkan heading `## Standards` / `## Spec` — yang gagal diisi dengan pesan error, jangan di-skip diam-diam.

## Step 5 — Aggregasi

Tampilkan dua laporan di bawah heading `## Standards` dan `## Spec`, verbatim atau sedikit dirapikan. **Jangan** merge atau re-rank temuan — dua axis sengaja dipisah supaya kode yang penuhi spec tapi langgar convention (atau sebaliknya) tetap kelihatan jelas.

## Saran Skills Lain

- **Belum ada diff untuk direview (belum ada perubahan)** → skill ini tidak relevan, kerjakan perubahan dulu baru review
- **Hanya butuh satu axis review (spec saja atau standards saja)** → tetap jalankan `code-review` utuh (dua axis terpisah, masing-masing akan report "tidak ada data" kalau tidak tersedia)
- **Butuh deepening arsitektur, bukan review diff** → `improve-architecture` (health check codebase untuk deepening opportunities)
