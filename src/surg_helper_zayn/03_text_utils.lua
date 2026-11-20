-- [surg_helper_zayn/03_text_utils] Teks gagal/sukses dan utilitas string
-- Tujuan : FAIL_TEXT/OK_TEXT, split_plain, nocolor, strip, why_text
-- Dependensi: tidak ada
-- Urutan load: 3 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 129-152 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local FAIL_TEXT = {"license is revoked", "sleep. permanently", "save them", "abandoned your patient", "smashed your surgical robot"}
local OK_TEXT = {"saved your patient"}

local function split_plain(s, sep)
    local out, pos = {}, 1
    while true do
        local a, b = s:find(sep, pos, true)
        if not a then out[#out + 1] = s:sub(pos) return out end
        out[#out + 1] = s:sub(pos, a - 1)
        pos = b + 1
    end
end

local function nocolor(s) return (s:gsub("`.", "")) end
local function strip(s) return nocolor(s):lower() end

local function why_text(why, s)
    return (why:gsub("{(%w+)}", function(k)
        if k == "inc" then return tostring(s.incisions) end
        if k == "shat" then return tostring(s.shattered) end
        if k == "brok" then return tostring(s.broken) end
        if k == "temp" then return s.temp and string.format("%.1f", s.temp) or "?" end
    end))
end
