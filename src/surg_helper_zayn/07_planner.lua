-- [surg_helper_zayn/07_planner] tool_ok() dan plan()
-- Tujuan : Jalankan RULES terhadap state, hasilkan primary + extras + missing, hitung pengulangan
-- Dependensi: 02_rules.lua, 04_state_history.lua (S), 01_config.lua
-- Urutan load: 7 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 286-331 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

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
