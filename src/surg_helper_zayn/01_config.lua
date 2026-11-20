-- [surg_helper_zayn/01_config] Konstanta, ID tool, nama tool, fever_tools
-- Tujuan : Konfigurasi (C), ambang suhu/jeda, tabel T (nama->ID), NAME (ID->nama), fever_tools()
-- Dependensi: tidak ada
-- Urutan load: 1 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 1-41 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

﻿-- ============================================================================
--  ZAYN SURGERY ASSISTANT v2.0
--  Watermark & Custom Aesthetic HUD by Zayn
-- ============================================================================

local SC = "ZAYN SURGERY v2.0"
local WATERMARK = "`w[`#ZAYN`w]"
local C = {
    mode = "resend",
    green_frame = "",
    welcome = true,
    dump = false,
    dump_file = "zayn_surg_dump.txt",
    hist_file = "surgery_history_zayn.txt"
}

local MARK, FIX_ID, TEMP_OK, TEMP_FAST, PREP_CAP, REPEAT_WARN, GAP, EXTRAS, LOW, KEEP =
    "[ZAYN]", 1296, 100.4, 105, 5, 4, 300000, 2, 10, 200

local SLEEP_MOVES = {normal = 9, hyper = 4}
local SLEEP_WARN  = {normal = 3, hyper = 2}

local T = {
    sponge = 1258, scalpel = 1260, anesthetic = 1262, antiseptic = 1264,
    antibiotics = 1266, splint = 1268, stitches = 1270, pins = 4308,
    transfusion = 4310, defib = 4312, clamp = 4314, ultrasound = 4316,
    lab_kit = 4318
}

local NAME = {
    [1258] = "Sponge", [1260] = "Scalpel", [1262] = "Anesthetic",
    [1264] = "Antiseptic", [1266] = "Antibiotics", [1268] = "Splint",
    [1270] = "Stitches", [4308] = "Pins", [4310] = "Transfusion",
    [4312] = "Defibrillator", [4314] = "Clamp", [4316] = "Ultrasound",
    [4318] = "Lab Kit", fix = "Fix It!"
}

local function fever_tools(s, c)
    if c.has_avail and c.avail[T.antibiotics] then return {T.antibiotics} end
    return {T.antibiotics, T.lab_kit}
end
