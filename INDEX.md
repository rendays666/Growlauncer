# INDEX — Peta Utama Growlauncer

> Baca file ini PERTAMA di setiap sesi. Dari sini, buka hanya file yang relevan.
> Jangan baca `raw/` kecuali benar-benar perlu (mahal, panjang).

## Cara pakai
1. Cari script yang relevan di tabel "Cari berdasarkan kebutuhan".
2. Buka `notes/<modul>.md` (mekanisme, aturan, gotcha). Biasanya cukup sampai sini.
3. Buka `src/<modul>/` hanya untuk melihat atau mengedit kodenya. Segmen bernomor, header tiap file menjelaskan isinya.
4. `raw/sorted/` = script asli utuh (arsip, tidak diubah). `raw/inbox/` = belum diproses.
5. Masalah yang sudah diketahui: `notes/bugs.md`. API dan packet: `notes/growtopia_api.md` (ringkas) dan `notes/launcher_docs.md` (dokumentasi resmi: hook, alias, enum packet).
6. `tools/` = alat buatan sendiri (bukan script user lain), mis. Debug Logger.

## Kalau user bilang "ada yang baru di inbox"
1. Tarik versi terbaru dari GitHub (user mengunggah langsung ke repo). Kalau history berubah (forced update), bandingkan dulu, jangan menimpa commit lokal tanpa cadangan.
2. `ls raw/inbox/` dan baca `raw/MANIFEST.md`.
3. Ikuti aturan di `raw/README.md`: cek hash, varian atau logic baru, jangan dobel.
4. Pindahkan ke `raw/sorted/` (nama rapi), update MANIFEST, tabel di bawah, notes, dan changelog.

## Cari berdasarkan kebutuhan
| Kebutuhan | Modul | Notes |
|-----------|-------|-------|
| Bot surgery, pencocokan kata kunci + anti-stuck + restart otomatis | `auto_surg` | `notes/auto_surg.md` |
| Bot surgery, pencocokan teks persis per kondisi | `surg_exact` | `notes/surg_exact.md` |
| Penasihat surgery (HUD, bukan bot), pelacak bius, riwayat | `surg_helper_zayn` | `notes/surg_helper_zayn.md` |
| Bersihkan seluruh world | `auto_clear` | `notes/auto_clear.md` |
| Beli pack lewat packet + drop anti-retake | `auto_buy_pack` | `notes/auto_buy_pack.md` |
| Nama fungsi launcher, format packet, clipboard, ImGui | (lintas script) | `notes/growtopia_api.md` (daftar penuh: `notes/launcher_api_dump_2026-11-21.txt`) |
| Signature hook, alias, enum tipe packet, fungsi `growtopia.*` | (dokumentasi resmi) | `notes/launcher_docs.md` |
| Log/debug dengan Copy All (debug bawaan hanya bisa copy satu) | `tools/debug_logger.lua` | `notes/debug_logger.md` |

## Fakta cepat GrowLauncher (dari dump API 2026-11-21)
- Lua **5.4**. Hampir semua fungsi punya dua ejaan (`SendPacket`/`sendPacket`, dst), keduanya bekerja; `editValue` = `editToggle`.
- Hook: daftarkan nama huruf kecil (`onvariant`, `onsendpacket`, `onsendpacketraw`, `ongamepacket`, `onvalue`, `ondraw`, `ondrawimgui`, `ondialog`) + `applyHook()`. Semantik `return true` tidak didokumentasikan.
- Chat resmi: `growtopia.sendChat(text, toClient?)`.
- Clipboard: `ImGui.SetClipboardText(text)` / `ImGui.GetClipboardText()`.
- `writeToLocal(file, text)` ada, folder tujuannya belum diketahui (dan lokasi `Preferences`). Tidak ada fungsi baca file bernama jelas.
- `getWorld()` dan `getObjects()` TIDAK ada (script Boren hanya memakainya sebagai cadangan).

## Script yang terdaftar
| Modul | Raw (`raw/sorted/`) | Src | Platform | Oleh |
|-------|---------------------|-----|----------|------|
| auto_surg | `auto_surg_v1.1_fixed.lua` (varian: `auto_surg_v1.0_beta.lua`) | `src/auto_surg/` (4 file) | Growtopia Lua | Moeyii |
| surg_exact | `surg_exact_dfnl5.lua` (varian: `surg_exact_ceximo_edit.lua`) | `src/surg_exact/` (2 file) | Growtopia Lua | DFNL5; edit Ceximo |
| surg_helper_zayn | `surg_helper_zayn_v2.0.lua` | `src/surg_helper_zayn/` (10 segmen) | Growtopia Lua | Zayn |
| auto_clear | `auto_clear_kurangtahu.lua` | `src/auto_clear/` (1 file) | Growtopia Lua | @_kurangtahu_ |
| auto_buy_pack | `auto_buy_pack_boren.lua` | `src/auto_buy_pack/` (12 segmen) | GrowLauncher Android/PC | Boren |

## Alat (`tools/`)
| Alat | File | Catatan |
|------|------|---------|
| Debug Logger v1.2 (log variant/kirim/raw/gamepacket/value + Copy All) | `tools/debug_logger.lua`, tes `tools/test_debug_logger.lua` | `notes/debug_logger.md` |

## Struktur modul
- **auto_surg** (urutan: config → tools → detect → main): `auto()` ID tool + anti-stuck + packet; `surg(var)` 14 aturan prioritas + deteksi gagal.
- **surg_exact** (01_rules → 02_main): satu `elseif` per kondisi. `auto()` tidak disalin (sama dengan `auto_surg/tools.lua` tanpa anti-stuck).
- **surg_helper_zayn** (01..10): config, rules, text_utils, state_history, tracker, parser, planner, rewrite, hooks, main. Peta di notes.
- **auto_clear**: satu file.
- **auto_buy_pack** (01..12): helpers, pack_data, pack_loader, config_state, runtime_utils, parsers_inventory, pack_search, collect_guard_warp, hooks, drop_engine, buy_loop, ui_events. Peta di notes.

## Alur global
- Surgery bot: `OnVariant` → `surg(var)` → cocokkan `v2` → set `tool` → `auto()` → `SendPacket(dialog_return ... tool<ID>)`.
- Surgery HUD: `OnVariant` → `rewrite` (parse → track → plan → recolor) → kirim dialog baru; pemain klik sendiri.
- Auto buy pack: warp → beli (`action|buy`) → verifikasi → drop anti-retake → ulang sampai target/gems habis.

## Masalah diketahui (ringkas, detail di `notes/bugs.md`)
- auto_surg: anti-stuck tidak mengganti tool yang dikirim (#1)
- surg_exact (Ceximo): `auto1()` tidak terdefinisi, aturan robot error (#5)
- auto_clear: loop memukul tanpa batas (#8)

## Changelog
- 2026-11-19: kerangka repo dibuat (struktur kosong).
- 2026-11-19: script pertama masuk: auto_surg (raw + dipecah 4 file + notes + bugs).
- 2026-11-19: raw/ dibagi jadi inbox/ (belum disortir) dan sorted/ (sudah), plus MANIFEST.md dan aturan anti-duplikasi.
- 2026-11-20: 6 script dari inbox diproses: auto_surg_v1.0_beta (varian), surg_exact + Ceximo (varian), surg_helper_zayn, auto_clear, auto_buy_pack. Tambah notes/growtopia_api.md.
- 2026-11-21: dump API launcher disimpan (`notes/launcher_api_dump_2026-11-21.txt`); `growtopia_api.md` ditulis ulang berdasarkan dump. Koreksi: beda huruf (`sendPacket` vs `SendPacket`) bukan tanda loader berbeda.
- 2026-11-22: dokumentasi resmi GrowLauncher diringkas ke `notes/launcher_docs.md` (hook, alias, value/module functions, `growtopia.*`, enum packet). `growtopia_api.md` dikoreksi (nama hook huruf kecil, alias `editValue`=`editToggle`, hook baru `ongamepacket`/`onvalue`). Tambah `tools/debug_logger.lua` v1.2 + tes + `notes/debug_logger.md`.
