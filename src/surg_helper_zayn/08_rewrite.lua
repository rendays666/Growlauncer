-- [surg_helper_zayn/08_rewrite] recolor() dan rewrite(): ubah dialog surgery menjadi HUD
-- Tujuan : Parse tombol, jalankan plan, warnai tombol saran, sisipkan blok peringatan ke dialog
-- Dependensi: 03, 04, 05, 06, 07
-- Urutan load: 8 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 333-474 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

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
