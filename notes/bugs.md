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
