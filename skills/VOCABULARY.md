# Vocabulary

Definisi shared yang dipakai lintas skill. Satu sumber kebenaran — skill lain refer
ke sini, jangan redefine.

## Arsitektur

- **Module** — unit kode: interface (kontrak publik) + implementation (isi di baliknya).
- **Interface** — semua yang caller wajib tahu buat pakai module. Bukan detail internal.
- **Depth** — rasio behavior vs interface. Deep = interface kecil, behavior besar di baliknya.
  Shallow = interface hampir sekompleks implementasi.
- **Seam** — titik kode tempat behavior bisa diganti tanpa edit langsung di situ.
- **Adapter** — implementasi konkret di balik seam. Satu adapter = hipotetis. Dua adapter = nyata.
- **Locality** — hal yang berhubungan (perubahan, bug, pengetahuan) tetap berdekatan lokasinya,
  tidak tersebar.

## ADR Filter

Keputusan dicatat sebagai ADR **hanya** kalau lolos ketiga filter ini:

1. **Hard to reverse** — biaya ubah nanti tinggi.
2. **Surprising without context** — orang lain baca kode nanti tanya "kenapa begini?"
3. **Real trade-off** — ada alternatif nyata yang sengaja tidak dipilih.

Kalau salah satu tidak terpenuhi → skip, tidak perlu ADR.
