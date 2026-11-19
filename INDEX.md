# INDEX — Peta Utama Growlauncer

> Baca file ini PERTAMA di setiap sesi. Dari sini, buka hanya file yang relevan.
> Jangan baca `raw/` kecuali benar-benar perlu (mahal, panjang).

## Cara pakai
1. Cari modul yang relevan di tabel bawah.
2. Buka `notes/<modul>.md` untuk penjelasan (fungsi, cara panggil, mekanisme, gotcha).
3. Buka `src/<modul>/` hanya kalau perlu edit/lihat kodenya.
4. `raw/` = script asli, arsip, tidak diubah.
5. Masalah yang sudah diketahui ada di `notes/bugs.md`.

## Script yang terdaftar

| Script | Raw | Notes | Platform | Tujuan |
|--------|-----|-------|----------|--------|
| auto_surg | `raw/auto_surg_v1.1_fixed.lua` | `notes/auto_surg.md` | Growtopia Lua | Auto Surgery bot (by Moeyii) |

## Modul per script

### auto_surg (urutan load: config → tools → detect → main)

| File | Fungsi | Isi singkat | Dependensi |
|------|--------|-------------|------------|
| `src/auto_surg/config.lua` | (variabel global) | state awal: tool, itool, failCount, lastTool, lastState, stuckCount | - |
| `src/auto_surg/tools.lua` | `auto()` | nama tool → ID, anti-stuck, kirim packet | config |
| `src/auto_surg/detect.lua` | `surg(var)` | baca dialog `v2`, 14 aturan prioritas, deteksi gagal + restart | tools, config |
| `src/auto_surg/main.lua` | - | dialog pembuka, log, `AddHook(surg, "OnVariant")` | detect |

## Alur global
`OnVariant` → `surg(var)` → cocokkan pola di `v2` → set `tool` → `auto()` → `SendPacket(dialog_return ... tool<ID>)`

## Masalah diketahui
- auto_surg: anti-stuck tidak mengganti tool yang dikirim (bugs.md #1)

## Changelog
- 2026-11-19: kerangka repo dibuat (struktur kosong).
- 2026-11-19: script pertama masuk: auto_surg (raw + dipecah 4 file + notes + bugs).
