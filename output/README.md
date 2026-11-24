# output/

Script jadi (siap tempel ke GrowLauncher), hasil gabungan modul di `src/`.
Beda dengan `src/` yang salinan verbatim: isi folder ini **sudah diubah** — bug diperbaiki, aturan digabung.

## auto_surg.lua

**Tujuan:** bot Surgery Growtopia. Baca dialog, pilih tool, kirim klik lewat packet, restart otomatis saat gagal.
**Basis:** `src/auto_surg` (Moeyii, V1.1 Fixed) + aturan teks `src/surg_exact` (DFNL5). Satu file, tanpa dependensi.
**Cara pakai:** tempel seluruh isi `auto_surg.lua` ke GrowLauncher, jalankan sekali. Hook `onvariant` langsung aktif.
**Debug:** variabel global `AUTO_SURG.state` (statistik) dan `AUTO_SURG.config` (`verbose`, `antiStuckBatas`, `restartOtomatis`).

### Perbaikan dibanding `src/auto_surg` (notes/bugs.md)
| Bug | Status di sini | Cara |
|-----|----------------|------|
| #1 anti-stuck tidak mengganti tool yang dikirim | **fixed** | `itool` dihitung setelah anti-stuck memilih tool |
| #2 cabang bleeding mengirim tool lama | **fixed** | packet hanya dikirim kalau tombol Clamp/Stitches ada |
| #3 kode mati / aturan ganda | dirapikan | aturan jadi tabel data, bukan if-chain |
| #4 semua variabel global | sebagian | state bot `local`, hanya `AUTO_SURG` yang global (untuk debug) |

### Tambahan
- Tool yang tombolnya tidak ada dilewati, bukan dikirim ke tombol hantu.
- Dialog non-surgery diabaikan (dulu kata `The patient` di dialog lain bisa memicu restart).
- Denyut normal (`Pulse: `2/`3`) tidak memicu Transfusion.
- Suhu dibaca angkanya (> 100.4F) selain cek warna.
- Statistik sukses/gagal/langkah dari `OnConsoleMessage`.
- Anti-stuck pindah ke alternatif aturan yang sama dulu, baru daftar cadangan.

### Urutan aturan (pertama cocok menang)
1. jantung berhenti → Defibrillator
2. pandangan buram → Sponge (→ Scalpel)
3. pasien sadar / bangun → Anesthetic
4. perdarahan → Stitches/Clamp (tergantung ada sayatan)
5. denyut lemah/kritis → Transfusion
6. demam → Antibiotic → Lab kit
7. tulang hancur → Scalpel (kalau belum ada sayatan) → Pins
8. tulang patah → Splint
9. `broke his` → Stitches
10. belum didiagnosis (0 sayatan) → Ultrasound
11. sayatan > 0 → Fix it → Stitches
12. cadangan → Scalpel, lalu Ultrasound

### Beda yang disengaja dari `surg_exact`
`surg_exact` memakai Fix It untuk `Incisions: `20` (0 sayatan). Di sini Fix It hanya dipakai kalau sayatan **sudah ada** (> 0); saat 0 sayatan bot memilih Scalpel, sesuai alur `surg_helper_zayn` (`cut` sebelum `close`).

### Tes
Diuji dengan Lua 5.4 + mock API (`LogToConsole`, `SendPacket`, `addHook`) memakai 10 dialog contoh: jantung, sadar, perdarahan tanpa Clamp, dialog non-surgery, gagal, demam, tulang hancur, sayatan selesai, pulse normal, anti-stuck. Semua lolos. Belum diuji in-game.

### Belum dikerjakan
- Antiseptic (1264) / operasi robot belum ditangani.
- Tidak ada UI toggle; konfigurasi lewat `AUTO_SURG.config`.
- Belum ada jeda antar packet (`Sleep`) — kalau server menolak kiriman terlalu cepat, tambahkan.
