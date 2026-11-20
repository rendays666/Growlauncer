-- [auto_surg/config] State global awal
-- Tujuan : variabel state yang dipakai tools.lua dan detect.lua
-- Dependensi: tidak ada
-- Urutan load: 1 (config -> tools -> detect -> main)
-- Sumber : raw/sorted/auto_surg_v1.1_fixed.lua baris 3-8 (salinan verbatim)

tool = "0"
itool = 1
failCount = 0
lastTool = ""
lastState = ""
stuckCount = 0
