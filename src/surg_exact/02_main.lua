-- [surg_exact/02_main] Init state dan pasang hook
-- Tujuan : Set tool/itool awal lalu AddHook(surg, "OnVariant")
-- Dependensi: 01_rules.lua
-- Urutan load: 2 dari 2 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_exact_dfnl5.lua baris 202-205 (salinan verbatim)

tool = ""
itool = 0

AddHook(surg, "OnVariant")
