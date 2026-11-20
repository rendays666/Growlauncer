-- [surg_helper_zayn/02_rules] RULES: mesin aturan 3 tier
-- Tujuan : Daftar aturan prioritas (tier 1 kritis, 2 sterilisasi/diagnosis/fix, 3 tindakan bedah): when() + tools + why
-- Dependensi: 01_config.lua (T, TEMP_*, SLEEP_WARN, fever_tools)
-- Urutan load: 2 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 43-127 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local RULES = {
    -- TIER 1: KRITIS / NYAWA PASIEN
    {key = "heart", tier = 1, crit = true, warn = true,
     when = function(s) return s.heart end,
     tools = function(s, c)
         if s.blind then return {T.sponge} end
         if s.dim and (c.heart_moves or 0) == 0 then return {T.sponge, T.defib} end
         return {T.defib}
     end,
     why = "Jantung Berhenti!", why_by = {[T.sponge] = "Buram + Jantung Berhenti"}},

    {key = "fever_fast", tier = 1, crit = true, warn = true,
     when = function(s) return s.fast or (s.temp and s.temp >= TEMP_FAST) end,
     tools = fever_tools, why = "Demam Ekstrem ({temp}F)",
     why_by = {[T.lab_kit] = "Buka Antibiotik (Suhu {temp}F)"}},

    {key = "pulse_crit", tier = 1, crit = true, warn = true,
     when = function(s) return s.xweak end,
     tools = {T.transfusion}, why = "Denyut Sangat Lemah"},

    {key = "blind", tier = 1, crit = true,
     when = function(s) return s.blind or s.dim end,
     tools = {T.sponge}, why = "Pandangan Buram"},

    {key = "awake", tier = 1, crit = true, warn = true,
     when = function(s) return s.scream or (s.awake and s.incisions > 0) end,
     tools = {T.anesthetic}, why = "Pasien Sadar!"},

    {key = "bleed", tier = 1, crit = true, warn = true,
     when = function(s) return s.bleeding end,
     tools = function(s)
         if s.incisions == 0 then return {T.stitches} end
         return {T.stitches, T.clamp}
     end,
     why = "Pendarahan Aktif"},

    {key = "pulse", tier = 1, warn = true,
     when = function(s) return s.weak_pulse end,
     tools = {T.transfusion}, why = "Denyut Lemah"},

    {key = "fever", tier = 1,
     when = function(s) return s.fever or (s.temp and s.temp > TEMP_OK) end,
     tools = fever_tools, why = "Suhu Tinggi ({temp}F)",
     why_by = {[T.lab_kit] = "Buka Antibiotik ({temp}F)"}},

    {key = "sleep", tier = 1, crit = true,
     when = function(s, c)
         return s.asleep and c.sleep_left and c.sleep_left <= SLEEP_WARN[s.hyper and "hyper" or "normal"] and s.incisions > 0
     end,
     tools = {T.anesthetic}, why = "Bius Hampir Habis"},

    -- TIER 2: STERILISASI, DIAGNOSIS & FIX
    {key = "prep", tier = 2, cap = true,
     when = function(s) return not s.clean end,
     tools = {T.antiseptic}, why = "Area Belum Steril"},

    {key = "diag", tier = 2,
     when = function(s) return s.undiagnosed and s.incisions == 0 end,
     tools = {T.ultrasound, T.lab_kit}, why = "Cek Diagnosis"},

    {key = "fix", tier = 2, ok = true,
     when = function(s, c) return c.fix ~= nil end,
     tools = {"fix"}, why = "Selesaikan Operasi!"},

    -- TIER 3: TINDAKAN BEDAH & PENUTUPAN
    {key = "shatter", tier = 3,
     when = function(s) return s.shattered > 0 end,
     tools = function(s)
         if s.incisions == 0 then return {T.scalpel} end
         return {T.pins}
     end,
     why = "Tulang Hancur ({shat})"},

    {key = "broken", tier = 3,
     when = function(s) return s.broken > 0 end,
     tools = {T.splint}, why = "Tulang Patah ({brok})"},

    {key = "cut", tier = 3,
     when = function(s) return s.undiagnosed end,
     tools = {T.scalpel}, why = "Buat Sayatan"},

    {key = "close", tier = 3,
     when = function(s) return s.incisions > 0 end,
     tools = {T.stitches}, why = "Tutup Sayatan ({inc})"}
}
