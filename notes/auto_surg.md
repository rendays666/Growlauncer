# auto_surg

**Tujuan:** Bot otomatis untuk mini-game Surgery di Growtopia. Membaca dialog bedah, memilih tool yang tepat, mengirim klik tombol lewat packet, dan restart otomatis kalau pasien gagal.
**Sumber:** `raw/sorted/auto_surg_v1.1_fixed.lua` (Auto Surg V1.1 Fixed, by Moeyii, 245 baris)
**File (urutan load):** `config` → `tools` → `detect` → `main` di `src/auto_surg/`
**Platform:** Lua loader Growtopia (bukan Roblox). API yang dipakai: `sendDialog`, `LogToConsole`, `growtopia.notify`, `SendPacket`, `AddHook`.

## Mekanisme
1. `main.lua` memasang `AddHook(surg, "OnVariant")`.
2. Tiap variant masuk, `surg(var)` menyimpan `var.v2` (teks dialog) ke `currentState`. Kalau `var.v1` bukan `OnDialogRequest`, langsung `return false`.
3. `surg` mencocokkan pola di `v2` menurut prioritas (tabel di bawah), mengisi global `tool`, lalu memanggil `auto()`.
4. `auto()` mengubah nama tool jadi ID, menjalankan anti-stuck, lalu mengirim packet.

## Packet
- Pilih tool: `SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|tool<ID>")`
- Restart operasi: sama, dengan `buttonClicked|start`

## ID tool
| Nama | ID | Nama | ID |
|------|----|------|----|
| Sponge | 1258 | Pins | 4308 |
| Scalpel | 1260 | Transfusion | 4310 |
| Anesthetic | 1262 | Defibrillator | 4312 |
| Antibiotic | 1266 | Clamp | 4314 |
| Splint | 1268 | Ultrasound | 4316 |
| Stitches | 1270 | Lab kit | 4318 |
| Fix it | 1296 | | |

Tombol tersedia kalau `v2` memuat teks `tool<ID>`. Hampir semua aturan memeriksa ini dulu sebelum memilih tool.

## Urutan prioritas di `surg()` (pertama cocok menang)
Penomoran mengikuti komentar di kode.

| # | Pemicu di `v2` | Syarat tombol | Tool |
|---|----------------|---------------|------|
| 0 | died / failed / escaped / The patient, tanpa kata tool/Pulse/Temp/Status/Incisions/Bones | - | kirim `start`, `failCount++` |
| 1 | Heart stopped | tool4312 | Defibrillator |
| 2 | wakes up / screams / flails / Awake / Coming to | tool1262 | Anesthetic |
| 3 | losing blood | tool4314 → Clamp, tool1270 → Stitches | lihat bugs.md #2 |
| 4 | Pulse: | tool4310 | Transfusion |
| 5 | Temp: | tool1266 → Antibiotic, tool4318 → Lab kit | |
| 6 | shattered | tool4308 → Pins, tool1260 → Scalpel | |
| 6b | broken | tool1268 | Splint |
| 7 | broke his | tool1270 | Stitches |
| 8 | Incisions: | tool1296 | Fix it |
| 9 | can't see / cannot see | tool1258 | Sponge |
| 10 | not been diagnosed | tool4316 | Ultrasound |
| 11 | Incisions: | tool1260 | Scalpel |
| 12 | (tanpa pola teks) | tool1296 + tool1270 | Fix it |
| 13 | (tanpa pola teks) | tool1260 | Scalpel |
| 14 | (tanpa pola teks) | tool4316 | Ultrasound |

## Anti-stuck (di `auto()`)
Kalau `currentState` sama dengan pemanggilan sebelumnya DAN tool sama, `stuckCount++`. Setelah 5 kali, tool diganti: Scalpel → Ultrasound → Antibiotic → Lab kit → (lainnya) Scalpel. Bug pada mekanisme ini ada di `notes/bugs.md` #1.

## Global state
`tool`, `itool`, `failCount`, `lastTool`, `lastState`, `stuckCount` (di `config.lua`), `currentState` (diisi di `surg`).
