-- [surg_helper_zayn/06_parser] parse_state(): baca dialog jadi tabel kondisi
-- Tujuan : Ubah teks dialog (huruf kecil, tanpa warna) menjadi flag heart/blind/awake/bleeding/temp/incisions/dst
-- Dependensi: tidak ada
-- Urutan load: 6 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 261-284 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local function parse_state(p)
    return {
        heart = p:find("heart stopped", 1, true) ~= nil,
        blind = p:find("can't see", 1, true) ~= nil,
        dim = p:find("hard to see", 1, true) ~= nil,
        awake = p:find("status:%s*awake") ~= nil or p:find("status:%s*coming to") ~= nil,
        scream = p:find("scream", 1, true) ~= nil or p:find("wakes up", 1, true) ~= nil or p:find("flails", 1, true) ~= nil,
        asleep = p:find("status:%s*unconscious") ~= nil or p:find("status:%s*near coma") ~= nil,
        near_coma = p:find("status:%s*near coma") ~= nil,
        hyper = p:find("hyperactive", 1, true) ~= nil,
        deep_sleep = p:find("falls into a deep sleep", 1, true) ~= nil,
        bleeding = p:find("losing blood", 1, true) ~= nil,
        weak_pulse = p:find("pulse:%s*weak") ~= nil,
        xweak = p:find("pulse:%s*extremely weak") ~= nil or p:find("pulse:%s*very weak") ~= nil,
        fever = p:find("fever", 1, true) ~= nil,
        fast = p:find("climbing rapidly", 1, true) ~= nil,
        temp = tonumber(p:match("temp:%s*([%d%.]+)")),
        clean = p:find("operation site:%s*clean") ~= nil,
        shattered = tonumber(p:match("(%d+)%s*shattered")) or 0,
        broken = tonumber(p:match("(%d+)%s*broken")) or 0,
        incisions = tonumber(p:match("incisions:%s*(%d+)")) or 0,
        undiagnosed = p:find("has not been diagnosed", 1, true) ~= nil
    }
end
