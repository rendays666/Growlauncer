# bugs — masalah yang ditemukan

Status "belum diperbaiki" berarti `src/` masih salinan verbatim dari `raw/`. Belum dites in-game.

## auto_surg

### 1. Anti-stuck tidak benar-benar mengganti tool (belum diperbaiki)
Di `auto()`, `itool` dihitung dari `tool` di awal fungsi (raw baris 21-47). Blok anti-stuck baru mengubah `tool` sesudahnya (raw baris 61-73). Packet di baris 75 tetap memakai `itool` lama, sementara log mencetak nama tool yang baru. Jadi "trying alternatives" hanya tampil di log, packet yang dikirim tetap tool yang macet.
**Perbaikan:** pindahkan blok if-chain penghitung `itool` ke sesudah blok anti-stuck.

### 2. Cabang bleeding bisa mengirim tool lama (belum diperbaiki)
Di aturan 3, `auto()` selalu dipanggil walau tidak ada tombol `tool4314` maupun `tool1270`. Variabel `tool` tidak berubah, jadi yang dikirim ulang adalah tool dari langkah sebelumnya.
**Perbaikan:** panggil `auto()` hanya kalau salah satu tombol ada.

### 3. Kode mati dan redundan (belum diperbaiki)
- Pengecekan `tool1260` kedua di akhir `surg` (raw baris 236-240) tidak pernah tercapai karena aturan 13 sudah menangkapnya.
- Aturan 11 (`tool1260` + `Incisions:`) menghasilkan hasil yang sama dengan aturan 13.

### 4. Semua variabel global
`tool`, `itool`, `lastTool`, dst. adalah global. Bisa bentrok kalau loader menjalankan script lain di environment yang sama.

## surg_exact (DFNL5 dan Ceximo)

### 5. `auto1()` tidak terdefinisi di varian Ceximo (belum diperbaiki)
Aturan robot (`Are you sure you want to perform surgery on this robot?...`) memanggil `auto1()`, tetapi tidak ada `function auto1` di file. Saat dialog itu muncul, Lua melempar error "attempt to call a nil value" dan fitur operasi robot tidak jalan. (Diperiksa dengan grep: 0 definisi.)

### 6. Tanpa deteksi gagal dan anti-stuck (desain, bukan bug)
Kalau pasien mati atau tidak ada aturan yang cocok, script hanya berhenti merespons. Tidak ada `start` otomatis seperti di `auto_surg`.

### 7. Perdarahan lambat tanpa fallback
Aturan `losing blood `3slowly.` hanya memakai Clamp (4314). Kalau tombol Clamp tidak ada, aturan ini tidak cocok dan jatuh ke Scalpel default.

## auto_clear

### 8. Loop memukul tanpa batas (belum diperbaiki)
`breakTile` memukul sampai tile kosong, tanpa batas percobaan atau timeout. Tile yang tidak bisa dipecahkan membuat script macet. Perbaikan: batasi jumlah pukulan per tile lalu lewati.

## auto_buy_pack

### 9. Penelan dialog terlalu luas saat bot jalan (catatan perilaku)
Selama `STATE.running`, semua dialog yang memuat `store`/`purchase`/`confirm`/`buy` dijawab otomatis dengan klik tombol pertama. Bisa mengenai dialog yang bukan milik bot.

## surg_helper_zayn

### 10. Penjaga rekursi `MARK` tidak pernah cocok (belum dites)
Lihat `notes/surg_helper_zayn.md` bagian Gotcha. Aman hanya kalau `sendVariant` tidak memicu hook lagi.
