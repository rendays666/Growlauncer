-- [surg_helper_zayn/04_state_history] State sesi, riwayat operasi, deteksi hasil
-- Tujuan : reset_session, penyimpanan riwayat (preferences + file), save_hist, finish, check_result
-- Dependensi: 01_config.lua (C, KEEP), 03_text_utils.lua
-- Urutan load: 4 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 154-235 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local S, OP
local function reset_session()
    S = {t = 0, counts = nil, sleep_left = nil, shown = {}, last_key = nil, repeats = 0, sug = {}}
end
reset_session()

local H = {n = 0, ok = 0, fail = 0, unk = 0, sf = 0, pick = {0, 0, 0, 0}, lines = {}}
local pref
do
    local ok, p = pcall(function()
        local m = require("preferences")
        m:new("zayn_surg_v2")
        return m
    end)
    if ok then
        pref = p
        pcall(function() pref:load() end)
        pcall(function()
            H.n, H.ok, H.fail = pref:get("n", 0), pref:get("ok", 0), pref:get("fail", 0)
            H.unk, H.sf = pref:get("unk", 0), pref:get("sf", 0)
            for i = 1, 4 do H.pick[i] = pref:get("p" .. i, 0) end
            local saved = pref:get("lines", "")
            if saved ~= "" then H.lines = split_plain(saved, "@@") end
        end)
    end
end

local function save_hist()
    local total = H.pick[1] + H.pick[2] + H.pick[3] + H.pick[4]
    local function pct(x) return total > 0 and string.format("%.0f%%", x * 100 / total) or "0%" end
    local out = {
        "=== RIWAYAT OPERASI - " .. SC .. " (by Zayn) ===",
        string.format("Total: %d | Sukses: %d | Gagal: %d | Unknown: %d | Skill Fail: %d",
            H.n, H.ok, H.fail, H.unk, H.sf),
        string.format("Akurasi Saran: #1=%d (%s) | #2=%d (%s) | #3=%d (%s) | Lainnya=%d (%s)",
            H.pick[1], pct(H.pick[1]), H.pick[2], pct(H.pick[2]), H.pick[3], pct(H.pick[3]), H.pick[4], pct(H.pick[4])),
        "=========================================================="
    }
    for _, l in ipairs(H.lines) do out[#out + 1] = l end
    pcall(writeToLocal, C.hist_file, table.concat(out, "\n"))
    if pref then
        pcall(function()
            pref:set("n", H.n) pref:set("ok", H.ok) pref:set("fail", H.fail)
            pref:set("unk", H.unk) pref:set("sf", H.sf)
            for i = 1, 4 do pref:set("p" .. i, H.pick[i]) end
            pref:set("lines", table.concat(H.lines, "@@"))
            pref:save()
        end)
    end
end

local function finish(result, note)
    local o = OP
    if not o then return end
    OP = nil
    H.n = H.n + 1
    if result == "SUKSES" then H.ok = H.ok + 1
    elseif result == "GAGAL" then H.fail = H.fail + 1
    else H.unk = H.unk + 1 end
    H.sf = H.sf + o.sf
    for i = 1, 4 do H.pick[i] = H.pick[i] + o.pick[i] end
    local okd, when = pcall(function() return os.date("%Y-%m-%d %H:%M") end)
    if not okd then when = "t" .. tostring(getTime()) end
    table.insert(H.lines, 1, string.format(
        "#%d [%s] | %s | %s | %s | %d Langkah | SF: %d | %ds%s",
        H.n, when, o.tgt, o.dx, result, o.moves, o.sf,
        math.floor((getTime() - o.t0) / 1000), (note and note ~= "") and (" | " .. note) or ""))
    while #H.lines > KEEP do table.remove(H.lines) end
    save_hist()
end

local function check_result(text)
    if not OP or type(text) ~= "string" then return end
    local p = strip(text)
    if p:find("patient", 1, true) or p:find("surg", 1, true) then OP.msg = p:sub(1, 70) end
    for _, w in ipairs(FAIL_TEXT) do
        if p:find(w, 1, true) then finish("GAGAL", p:sub(1, 70)) return end
    end
    for _, w in ipairs(OK_TEXT) do
        if p:find(w, 1, true) then finish("SUKSES", "") return end
    end
end
