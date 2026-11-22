# debug_logger (tools/debug_logger.lua, v1.2)

**Tujuan:** pengganti debug bawaan launcher yang hanya bisa menyalin satu entri; menangkap log dan bisa COPY ALL / simpan.
**File:** `tools/debug_logger.lua`; tes: `tools/test_debug_logger.lua` (jalankan dari root repo: `texlua tools/test_debug_logger.lua`, API launcher palsu, 51 tes lulus). Bukan script milik user lain, dibuat di repo ini; tidak lewat inbox.
**Status:** teruji hanya dengan stub. Belum dites di launcher asli: clipboard dari UI, perintah chat `/dbg`, `ongamepacket`, `onvalue`.

## Yang ditangkap
| Sumber | Hook | Default |
|--------|------|---------|
| Variant (server→client) | `onvariant` | ON |
| Paket kirim | `onsendpacket` | ON |
| Paket raw kirim | `onsendpacketraw` | OFF |
| GamePacket (TankUpdate) | `ongamepacket` | OFF |
| Perubahan nilai UI | `onvalue` (nama berawalan `dbg_` diabaikan) | OFF |

Format entri: `-- #n HH:MM:SS` lalu teks gaya launcher (`[nama] param 0: ...`).

## Copy All (tiga jalur sekaligus)
1. Clipboard: `ImGui.SetClipboardText`, lalu dibaca balik dengan `GetClipboardText` → pesan `OK-terverifikasi` / `OK-tapi-isi-beda` / `GAGAL`.
2. Kotak UI `dbg_out` (`editValue`): tap, Select All, Copy.
3. File `debug_log.txt` lewat `writeToLocal` (lokasi folder belum diketahui). `Dump API` menulis `debug_api.txt`.

## Kontrol
UI modul "Debug Logger" (toggle `dbg_power/dbg_v/dbg_s/dbg_r/dbg_g/dbg_val/dbg_auto`, input `dbg_max/dbg_filter/dbg_ignore/dbg_out`, tombol `dbg_btn_copy/last/save/clear/api`). Chat: `/dbg copy [N] | last | save | clear | api | status | on | off | raw | game | value | filter a,b | ignore a,b` (diparse dari paket `|text|/dbg ...` di `onsendpacket`, lalu ditelan dengan `return true`; asumsi format chat belum terbukti).

## Gotcha / keputusan desain
- Token reload `_G.__DBG_TOKEN`: instance lama otomatis nonaktif saat script dimuat ulang. Token ini muncul di dump API sebagai artefak, bukan API launcher.
- `OnValue` global dirantai ke `OnValue` milik script lain (tidak menimpanya).
- Debounce tombol: diblok hanya jika selisih waktu CPU <0.25 s DAN waktu dinding <1 s (waktu CPU saja salah saat launcher idle).
- Auto-simpan memakai `os.time()` (wall clock), bukan `os.clock()`.
- Anti-loop: pesan konsol berawalan `[DBGLOG]` tidak dicatat.
