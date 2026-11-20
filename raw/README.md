# raw/

Arsip script asli persis seperti dikirim. **Jangan diedit isinya.**

```
raw/
  inbox/     ← BELUM disortir. Taruh script baru di sini.
  sorted/    ← SUDAH disortir (dipecah ke src/ + dicatat di notes/)
  MANIFEST.md ← daftar semua file raw + sha256 + status
```

## Alur
1. Kamu taruh script baru di `raw/inbox/` (upload langsung ke GitHub, tidak perlu copy-paste ke chat).
2. Di chat cukup bilang: "ada yang baru di inbox".
3. AI membaca `INDEX.md` dan `MANIFEST.md`, lalu memproses setiap file inbox dengan aturan di bawah.
4. File yang selesai dipindah ke `sorted/`, dicatat di `MANIFEST.md`, `INDEX.md` diperbarui.

## Aturan anti-duplikasi (supaya tidak diulang kalau logic sama)
Untuk setiap file di inbox, AI memeriksa berurutan:

1. **Hash sama persis** dengan file di MANIFEST: file sama. Hapus dari inbox, tidak ada yang diproses.
2. **Logic dan mekanisme sama, hanya beda kecil** (nama variabel, teks, angka, urutan): JANGAN buat modul `src/` baru. Simpan raw ke `sorted/`, catat di MANIFEST sebagai `varian dari <script>`, dan tulis hanya selisihnya di `notes/<script>.md` bagian "Varian".
3. **Ada logic atau mekanisme baru** (remote baru, fitur baru, cara kerja berbeda): pecahkan hanya bagian barunya ke `src/`. Bagian yang sudah ada cukup dirujuk, tidak disalin lagi.
4. **Script yang sama sekali baru:** proses penuh (src + notes + INDEX).

Kalau AI ragu apakah sebuah script termasuk varian atau logic baru, AI bertanya dulu, tidak menebak.

## Penamaan
`<nama>_v<versi>.<ext>`, contoh `auto_surg_v1.1_fixed.lua`. Kalau nama bentrok, tambahkan tanggal.
