# surg_exact

**Tujuan:** Bot surgery Growtopia yang mencocokkan teks dialog PERSIS (termasuk kode warna) per kondisi, satu `elseif` per kemungkinan. Beda mekanisme dari `auto_surg` (kata kunci longgar + anti-stuck).
**Sumber:** `raw/sorted/surg_exact_dfnl5.lua` (AUTO_SURG DFNL5, 204 baris). Varian: `raw/sorted/surg_exact_ceximo_edit.lua` (lihat bagian Varian).
**File (urutan load):** `01_rules` → `02_main` di `src/surg_exact/`
**Tidak disalin ke src:** `auto()` (raw baris 1-31). Isinya sama dengan `src/auto_surg/tools.lua`, hanya tanpa blok anti-stuck dan log berlabel `DFNL5`.
**Tool ID dan packet:** sama dengan `notes/auto_surg.md`. Format API ada di `notes/growtopia_api.md`.

## Mekanisme
Tiap aturan: `var.v1` memuat `OnDialogRequest` DAN `var.v2` memuat teks kondisi (sering dengan kode warna) DAN tombol `tool<ID>` ada. Kalau cocok: set `tool`, `auto()`, `return true`. Aturan dievaluasi berurutan, yang pertama cocok menang. Kalau tidak ada yang cocok: `return false`.

Pola memakai pattern Lua: `(.+)` penangkap sisa teks, `(%d+)` angka. Kode warna menentukan tingkat keparahan: `` `4`` merah (parah), `` `6`` kuning, `` `3`` hijau/ringan, `` `2`` hijau.

## Urutan aturan (pertama cocok menang)
| Kondisi (teks di `v2`) | Tombol | Tool |
|------------------------|--------|------|
| `The patient wakes up!` | 1262 | Anesthetic |
| `The patient screams and flails!` | 1262 | Anesthetic |
| `Status: `4Heart stopped!` | 4312 | Defibrillator |
| `Status: `6Coming to` | 1262 | Anesthetic |
| `Pulse: `4` | 4310 | Transfusion |
| `Temp: `4/`6/`3<angka>` | 1266 dulu, lalu 4318 | Antibiotic / Lab kit |
| `losing blood `4very quickly!` | 4314 dulu, lalu 1270 | Clamp / Stitches |
| `Patient is `6losing blood!` | 4314 dulu, lalu 1270 | Clamp / Stitches |
| `Incisions: `20` atau `Incisions: `30` | 1296 | Fix it |
| `The patient has not been diagnosed.` | 4316 | Ultrasound |
| `Status: `4Awake` | 1262 | Anesthetic |
| `Bones: `6/`4 <n> broken` | 1268 | Splint |
| `Patient broke his arm.` | 1270 | Stitches |
| `Status: `3Awake` | 1262 | Anesthetic |
| `Pulse: `6` | 4310 | Transfusion |
| `You can't see what you are doing!` | 1258 | Sponge |
| (tanpa teks) tombol 1296 DAN 1270 ada | 1270 | **Stitches** |
| `Bones: ... shattered` (12 kombinasi warna 1 atau 2 tulang) | 4308 dulu, lalu 1260 | Pins / Scalpel |
| `Patient broke his leg.` | 1270 | Stitches |
| `Patient is losing blood `3slowly.` | 4314 | Clamp (TANPA fallback Stitches) |
| (tanpa teks) tombol 1260 ada | 1260 | Scalpel (default) |

## Beda dengan auto_surg (Moeyii)
| Aspek | surg_exact | auto_surg |
|-------|------------|-----------|
| Pencocokan | teks persis + warna | kata kunci longgar |
| Deteksi gagal + restart (`start`) | tidak ada | ada |
| Anti-stuck | tidak ada | ada (tapi lihat bugs.md #1) |
| Tombol 1296 + 1270 muncul bersamaan | pilih Stitches | pilih Fix it |
| Perdarahan lambat | hanya Clamp | Clamp atau Stitches |
| Tulang patah/hancur | dipecah per warna | satu cabang `shattered` / `broken` |

## Varian: surg_exact_ceximo_edit (Edit Ceximo Auto Surgery)
Aturannya SAMA dengan DFNL5 (dibandingkan baris per baris). Selisihnya hanya:
1. **API huruf kecil:** `sendPacket(...)` dan `log(...)` (DFNL5: `SendPacket`, `LogToConsole`). Label log `PixelMorph_`. Artinya target loader berbeda (lihat growtopia_api.md).
2. **Aturan robot:** dialog `Are you sure you want to perform surgery on this robot?...` + tombol 4316 memanggil `auto1()`. Fungsi `auto1` TIDAK didefinisikan di mana pun. Lihat bugs.md.
3. **Aturan jantung tambahan:** `Status: The patient's heart has stopped!` + 4312 → Defibrillator (selain `Status: `4Heart stopped!`).
4. **`Sleep(100)`** disisipkan sebelum `auto()` pada aturan `Patient broke his arm.`.
