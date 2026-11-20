-- ============================================================================
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

local function track(s, counts)
    local now = getTime()
    if S.t > 0 and now - S.t > GAP then reset_session() end
    S.t = now
    local moved = false
    if S.counts then
        for id, n in pairs(S.counts) do
            if (counts[id] or 0) < n then moved = true end
        end
    end
    if moved and S.sleep_left then S.sleep_left = math.max(0, S.sleep_left - 1) end
    if s.deep_sleep and (moved or not S.counts) then
        S.sleep_left = s.hyper and SLEEP_MOVES.hyper or SLEEP_MOVES.normal
    end
    if not s.asleep then S.sleep_left = nil end
    if s.heart then
        if S.heart_moves == nil then S.heart_moves = 0
        elseif moved then S.heart_moves = S.heart_moves + 1 end
    else
        S.heart_moves = nil
    end
    S.counts = counts
end

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

local function tool_ok(id, c)
    if id == "fix" then return c.fix ~= nil end
    if id == T.anesthetic and c.no_anesthetic then return false end
    return (not c.has_avail) or c.avail[id] == true
end

local function plan(s, c)
    local res, used, miss_used = {extras = {}, missing = {}}, {}, {}
    for _, rule in ipairs(RULES) do
        local capped = rule.cap and (S.shown[rule.key] or 0) >= PREP_CAP
        if not capped and rule.when(s, c) then
            local tools = type(rule.tools) == "function" and rule.tools(s, c) or rule.tools
            local found = false
            for _, id in ipairs(tools) do
                if tool_ok(id, c) then
                    found = true
                    local crit, tid = rule.crit, id
                    local w = why_text(rule.why_by and rule.why_by[id] or rule.why, s)
                    if tid == T.scalpel and s.awake and tool_ok(T.anesthetic, c) then
                        tid, crit, w = T.anesthetic, true, "Pasien Sadar!"
                    end
                    if not res.primary then
                        S.shown[rule.key] = (S.shown[rule.key] or 0) + 1
                        local key = rule.key .. tostring(tid)
                        S.repeats = (key == S.last_key) and (S.repeats + 1) or 1
                        S.last_key = key
                        if S.repeats >= REPEAT_WARN then w = w .. " [" .. S.repeats + 1 .. "x]" end
                        res.primary = {rule = rule, id = tid, why = w, crit = crit}
                        used[tid] = true
                    elseif rule.tier == res.primary.rule.tier and not used[tid] and #res.extras < EXTRAS then
                        res.extras[#res.extras + 1] = {id = tid, why = w}
                        used[tid] = true
                    end
                end
            end
            if not found and rule.warn and c.has_avail then
                local id = tools[1]
                if id and not miss_used[id] then
                    miss_used[id] = true
                    res.missing[#res.missing + 1] = {id = id, why = why_text(rule.why, s)}
                end
            end
        end
    end
    return res
end

local function recolor(entry, id, color, frame)
    local p = entry.p
    local raw_label = (p[3] ~= nil and p[3] ~= "") and nocolor(p[3]) or NAME[id]
    p[3] = color .. raw_label .. "``"
    if frame and entry.icon and C.green_frame ~= "" and p[4] and p[4] ~= "" then
        p[4] = C.green_frame
    end
    return table.concat(p, "|")
end

local function rewrite(raw)
    if type(raw) ~= "string" or raw:find(MARK, 1, true) then return nil end
    local plain = strip(raw)
    if not (plain:find("pulse:", 1, true) and plain:find("incisions:", 1, true)) then return nil end
    if C.dump then pcall(writeToLocal, C.dump_file, raw) end

    local now = getTime()
    if OP and S.t > 0 and now - S.t > GAP then finish("TIDAK DIKETAHUI", OP.msg or "Timeout") end

    local lines = split_plain(raw, "\n")
    local btn, avail, counts, stock, has_avail, fix, title = {}, {}, {}, {}, false, nil, "?"
    for i, line in ipairs(lines) do
        if line:find("^add_label_with_icon|big|") then
            local parts = split_plain(line, "|")
            title = nocolor(parts[3] or "?")
            parts[3] = "`w" .. title .. " `8| `#ZAYN``"
            lines[i] = table.concat(parts, "|")
        elseif line:find("^add_button") then
            local p = split_plain(line, "|")
            local name, label = (p[2] or ""):lower(), (p[3] or ""):lower()
            local icon = line:find("^add_button_with_icon|") ~= nil
            local itemid = icon and tonumber(p[5]) or nil
            if name == "tool" .. FIX_ID or name:find("fix", 1, true) or label:find("fix it", 1, true) or itemid == FIX_ID then
                fix = {i = i, p = p, icon = icon}
            else
                local id = tonumber(name:match("^tool(%d+)$")) or itemid
                if id and NAME[id] and (itemid == nil or itemid == id) then
                    btn[id] = {i = i, p = p, icon = icon}
                    avail[id], has_avail = true, true
                    counts[id] = tonumber(p[6]) or 0
                    stock[id] = tonumber(p[6])
                end
            end
        end
    end

    if not OP then OP = {t0 = now, moves = 0, pick = {0, 0, 0, 0}, sf = 0, dx = "-", tgt = title, new = true} end
    local dx = plain:match("suffering from ([^!%.]+)")
    if dx then OP.dx = dx end
    if plain:find("skill fail", 1, true) then OP.sf = OP.sf + 1 end

    local s = parse_state(plain)
    track(s, counts)
    local res = plan(s, {
        avail = avail, has_avail = has_avail, fix = fix,
        sleep_left = S.sleep_left, heart_moves = S.heart_moves,
        no_anesthetic = s.near_coma
    })

    S.sug = {}
    local function entry_of(id) return (id == "fix") and fix or btn[id] end
    local function num(id) return id == "fix" and FIX_ID or id end
    local pr = res.primary
    if pr then
        S.sug[1] = num(pr.id)
        if entry_of(pr.id) then lines[entry_of(pr.id).i] = recolor(entry_of(pr.id), pr.id, "`2", true) end
    end
    for k, ex in ipairs(res.extras) do
        S.sug[k + 1] = num(ex.id)
        if entry_of(ex.id) then lines[entry_of(ex.id).i] = recolor(entry_of(ex.id), ex.id, "`e", false) end
    end

    local low = {}
    if OP.new then
        OP.new = false
        if not raw:find("Train-E", 1, true) then
            local ids = {}
            for id in pairs(stock) do ids[#ids + 1] = id end
            table.sort(ids)
            for _, id in ipairs(ids) do
                if stock[id] < LOW then low[#low + 1] = NAME[id] .. " (" .. stock[id] .. ")" end
            end
        end
    end

    local alerts = {}
    alerts[#alerts + 1] = "add_textbox|`8--------------------------------------------------``|left|"

    if pr then
        local badge = (pr.rule.ok and "`2[READY]") or (pr.crit and "`4[CRITICAL]") or "`9[ACTION]"
        local icon_id = (type(pr.id) == "number") and pr.id or FIX_ID
        alerts[#alerts + 1] = string.format(
            "add_label_with_icon|small|%s %s `w%s `7- `o%s``|left|%d|",
            WATERMARK, badge, NAME[pr.id], pr.why, icon_id
        )
        if #res.extras > 0 then
            local ex_parts = {}
            for k, ex in ipairs(res.extras) do
                ex_parts[#ex_parts + 1] = string.format("`e#%d %s `8(%s)", k + 1, NAME[ex.id], ex.why)
            end
            alerts[#alerts + 1] = "add_smalltext|`7   Opsi lain: " .. table.concat(ex_parts, " `8| ") .. "``|left|"
        end
    end

    local status_bar = {}
    if s.asleep and S.sleep_left then
        local sc = (S.sleep_left <= 2) and "`4" or "`a"
        status_bar[#status_bar + 1] = sc .. "Sisa Bius: ~" .. S.sleep_left .. " langkah"
    end
    if s.near_coma then
        status_bar[#status_bar + 1] = "`4NEAR COMA (STOP ANESTHETIC!)"
    end
    if #status_bar > 0 then
        alerts[#alerts + 1] = "add_smalltext|`w   Status: " .. table.concat(status_bar, " `8| ") .. "``|left|"
    end

    if #res.missing > 0 then
        local parts = {}
        for _, m in ipairs(res.missing) do parts[#parts + 1] = NAME[m.id] .. " (" .. m.why .. ")" end
        alerts[#alerts + 1] = "add_smalltext|`4   [!] Alat Habis: " .. table.concat(parts, ", ") .. "``|left|"
    end

    if #low > 0 then
        alerts[#alerts + 1] = "add_smalltext|`6   [!] Stok Menipis: " .. table.concat(low, ", ") .. "``|left|"
    end

    alerts[#alerts + 1] = "add_textbox|`8--------------------------------------------------``|left|"

    if not pr and #res.missing == 0 and #low == 0 then return nil end

    local at = 1
    for i, line in ipairs(lines) do
        if line:find("^add_label_with_icon|") then at = i + 1 break end
    end
    if at == 1 then
        for i, line in ipairs(lines) do
            if line:find("^add_") then at = i break end
        end
    end
    for k, a in ipairs(alerts) do table.insert(lines, at + k - 1, a) end
    return table.concat(lines, "\n")
end

local function on_variant(var)
    local ok, res = pcall(function()
        if var.v1 == "OnConsoleMessage" then check_result(var.v2) return false end
        if var.v1 ~= "OnDialogRequest" then return false end
        local new = rewrite(var.v2)
        if not new then check_result(var.v2) return false end
        if C.mode == "inplace" then var.v2 = new return false end
        sendVariant({v1 = "OnDialogRequest", v2 = new})
        return true
    end)
    if not ok then log("[" .. SC .. "] Error: " .. tostring(res)) return false end
    return res
end

local function on_send(ptype, pkt)
    pcall(function()
        if type(pkt) ~= "string" or not OP or not pkt:find("dialog_name|surgery", 1, true) then return end
        local b = pkt:match("buttonClicked|([^\n|]+)")
        if not b then return end
        OP.moves = OP.moves + 1
        local id, idx = tonumber(b:match("^tool(%d+)$")), 4
        for k, sid in ipairs(S.sug) do
            if sid == id then idx = k break end
        end
        OP.pick[idx] = OP.pick[idx] + 1
        if b == "cancel" then OP.gaveup = true end
    end)
    return false
end

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
