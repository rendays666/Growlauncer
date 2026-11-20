# src/

Script yang sudah dipecah per logic, salinan verbatim dari `raw/sorted/` (tidak diubah).
Satu modul = satu folder. Nama file menjelaskan isinya.

Setiap file diawali komentar header (tanpa baris kosong), lalu satu baris kosong, lalu kode asli:
- `[modul/file]` + judul
- Tujuan
- Dependensi
- Urutan load
- Sumber: file raw dan rentang baris

## Segmen
Modul besar dipecah jadi segmen bernomor (`01_...`, `02_...`). Menggabungkan badan semua segmen berurutan menghasilkan script asli. Banyak segmen berbagi variabel `local` yang sama, jadi **segmen tidak bisa dijalankan sendiri-sendiri**; untuk menjalankan, pakai file di `raw/sorted/`.

## Bagian yang sengaja tidak disalin
Kalau suatu bagian identik dengan modul lain (aturan anti-duplikasi di `raw/README.md`), bagian itu tidak disalin lagi. Header file menyebut alasannya dan modul rujukannya.
