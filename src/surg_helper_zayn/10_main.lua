-- [surg_helper_zayn/10_main] Dialog sambutan, pasang hook, log
-- Tujuan : welcome() lalu addHook x2 + applyHook
-- Dependensi: 09_hooks.lua
-- Urutan load: 10 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 506-533 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local function welcome()
    local d = {
        "set_default_color|`o",
        "add_label_with_icon|big|`#ZAYN `wSURGERY ASSISTANT `8v2.0``|left|1260|",
        "add_textbox|`8==================================================``|left|",
        "add_smalltext|`7Custom Aesthetic HUD & Smart Surgery Predictor by `#Zayn``|left|",
        "add_spacer|small|",
        "add_label_with_icon|small|`2Fitur Utama & Panduan:``|left|1270|",
        "add_smalltext|`w- `2Hijau (`2Primary`w) `o: Alat prioritas utama yang wajib diklik.``|left|",
        "add_smalltext|`w- `eCyan (`eAlternatif`w) `o: Opsi alat kedua jika kondisi bersamaan.``|left|",
        "add_smalltext|`w- `aTracker Bius `o: Menghitung estimasi sisa langkah sebelum pasien sadar.``|left|",
        "add_smalltext|`w- `4Alert System `o: Deteksi Near Coma, alat habis, & stok < 10.``|left|",
        "add_spacer|small|",
        "add_label_with_icon|small|`9Catatan Penting:``|left|1296|",
        "add_smalltext|`o- Gunakan `2Tea `oatau `2Skill Spice `osebelum operasi untuk mengurangi Skill Fail.``|left|",
        "add_smalltext|`o- Riwayat operasi tersimpan otomatis di `w" .. C.hist_file .. "``|left|",
        "add_textbox|`8==================================================``|left|",
        "add_quick_exit|",
        "end_dialog|zayn_surg_ui|Tutup|Mulai Operasi|"
    }
    growtopia.sendDialog(table.concat(d, "\n"))
end

addHook(on_variant, "onVariant")
addHook(on_send, "onSendPacket")
applyHook()
log("[" .. SC .. "] Successfully loaded! Watermark: ZAYN")
if C.welcome then pcall(welcome) end
