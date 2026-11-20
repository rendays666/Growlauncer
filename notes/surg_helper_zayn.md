# surg_helper_zayn

**Tujuan:** BUKAN bot. Penasihat surgery (HUD) yang menulis ulang dialog surgery: menandai tool yang disarankan (hijau = utama, cyan = alternatif), menambah blok peringatan, melacak sisa bius, dan menyimpan riwayat operasi. Pemain tetap mengklik sendiri.
**Sumber:** `raw/sorted/surg_helper_zayn_v2.0.lua` (ZAYN SURGERY ASSISTANT v2.0, 533 baris, CRLF)
**File:** `src/surg_helper_zayn/01..10` (segmen, gabungkan berurutan = script asli; semua `local` dibagi antar segmen)
**Bahasa UI:** Indonesia

## Alur
1. Hook `OnVariant`. `OnConsoleMessage` hanya diperiksa untuk hasil operasi (`check_result`).
2. Untuk `OnDialogRequest`, `rewrite(raw)` hanya aktif kalau teks (tanpa warna, huruf kecil) memuat `pulse:` DAN `incisions:` (itu ciri dialog surgery).
3. `rewrite`: baca tombol `add_button*` (ID tool, stok), `parse_state` baca kondisi pasien, `track` hitung langkah, `plan` jalankan RULES, lalu `recolor` tombol saran dan sisipkan blok `alerts` ke dialog.
4. Pengiriman: `C.mode = "resend"` → `sendVariant({v1="OnDialogRequest", v2=new})` lalu `return true` (dialog asli ditelan). `"inplace"` → ubah `var.v2`.
5. Hook `OnSendPacket` (`on_send`) mencatat setiap klik `dialog_name|surgery`: menambah langkah dan menghitung apakah tool yang diklik adalah saran #1/#2/#3/lainnya.

## Mesin aturan (`02_rules.lua`, 3 tier)
Tiap aturan: `when(s,c)` + `tools` (daftar ID atau fungsi) + teks `why`. `plan()` menjalankan semua aturan berurutan. Tool pertama yang tersedia jadi **primary**; tool lain pada tier yang sama jadi **extras** (maks `EXTRAS = 2`). Aturan kritis tanpa tool tersedia masuk daftar **missing** ("Alat Habis").

| Tier | Kunci aturan |
|------|--------------|
| 1 (kritis) | heart, fever_fast, pulse_crit, blind, awake, bleed, pulse, fever, sleep |
| 2 | prep (antiseptic, maks 5x), diag (ultrasound/lab kit), fix (Fix It) |
| 3 | shatter (scalpel jika belum ada sayatan, pins jika ada), broken (splint), cut (scalpel), close (stitches) |

Detail penting: jantung berhenti + pandangan buram → Sponge dulu. Scalpel yang akan disarankan saat pasien sadar diganti Anesthetic. Anesthetic tidak disarankan saat `near coma`.

## Konstanta (`01_config.lua`)
`TEMP_OK 100.4`, `TEMP_FAST 105`, `PREP_CAP 5`, `REPEAT_WARN 4`, `GAP 300000` (5 menit tanpa dialog = sesi baru), `EXTRAS 2`, `LOW 10` (stok menipis), `KEEP 200` (riwayat disimpan).
Tool ID sama dengan `notes/auto_surg.md`, ditambah **Antiseptic 1264** (tidak ada di bot lain).

## Pelacak bius (`05_tracker.lua`)
Membandingkan stok tiap tool antar dialog: kalau ada yang berkurang berarti satu langkah terpakai. Saat teks `falls into a deep sleep` muncul, `sleep_left` diisi 9 (normal) atau 4 (hyperactive), berkurang tiap langkah. Peringatan "Bius Hampir Habis" saat sisa <= 3 (normal) atau <= 2 (hyper) dan sudah ada sayatan.

## Riwayat (`04_state_history.lua`)
- Hasil gagal: `license is revoked`, `sleep. permanently`, `save them`, `abandoned your patient`, `smashed your surgical robot`. Sukses: `saved your patient`.
- Disimpan ke `require("preferences")` (nama `zayn_surg_v2`) dan file `surgery_history_zayn.txt` lewat `writeToLocal`. Isi: total, sukses, gagal, unknown, skill fail, akurasi saran.

## Gotcha
- `MARK = "[ZAYN]"` dipakai `rewrite` untuk menolak dialog yang sudah diproses, tetapi teks yang dihasilkan memuat `` `w[`#ZAYN`w] `` (ada kode warna di tengah) sehingga `[ZAYN]` utuh tidak pernah muncul. Pencegahan rekursi karenanya bergantung pada `sendVariant` yang tidak memicu hook lagi. **Belum dites.**
- Arti pengecekan `Train-E` (melewati peringatan stok) belum dipastikan dari kode.
- Seluruh logika dibungkus `pcall`; error muncul sebagai log `Error:` dan dialog asli dibiarkan lewat.

## Peta segmen (`src/surg_helper_zayn/`)
| Segmen | Baris raw | Isi |
|--------|-----------|-----|
| 01_config | 1-41 | konstanta, `T`, `NAME`, `fever_tools` |
| 02_rules | 43-127 | `RULES` 3 tier |
| 03_text_utils | 129-152 | `FAIL_TEXT`/`OK_TEXT`, `split_plain`, `nocolor`, `strip`, `why_text` |
| 04_state_history | 154-235 | state sesi, riwayat, `save_hist`, `finish`, `check_result` |
| 05_tracker | 237-259 | `track` (sisa bius, langkah jantung) |
| 06_parser | 261-284 | `parse_state` |
| 07_planner | 286-331 | `tool_ok`, `plan` |
| 08_rewrite | 333-474 | `recolor`, `rewrite` |
| 09_hooks | 476-504 | `on_variant`, `on_send` |
| 10_main | 506-533 | `welcome`, pasang hook |
