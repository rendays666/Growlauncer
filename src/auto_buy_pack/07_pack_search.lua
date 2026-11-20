-- [auto_buy_pack/07_pack_search] Pencarian dan pemilihan pack dari katalog
-- Tujuan : scorePackMatch (skor 1000/800/600/450/350/200), buildFilteredPackList, applySelectedPack, findBestPackMatch, popup picker
-- Dependensi: 03_pack_loader.lua, 04
-- Urutan load: 7 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 663-863 (salinan verbatim)

-- ============================================================================
-- 4. SEARCH & SELECT PACK DARI DEBUG LIST (TANPA RENDER SHOP)
-- ============================================================================
local function scorePackMatch(entry, q, words, isNumericQ)
    local titleL = entry.title:lower()
    local codeL = entry.code:lower()
    if q == "" then return 100 end

    -- 1. Cocok persis (exact match)
    if codeL == q or titleL == q then return 1000 end
    -- 2. Diawali query (prefix match)
    if titleL:sub(1, #q) == q or codeL:sub(1, #q) == q then return 800 end
    -- 3. Awal kata cocok (word boundary match)
    if (" " .. titleL):find(" " .. q, 1, true) or ("_" .. codeL):find("_" .. q, 1, true) then
        return 600
    end
    -- 4. Substring di judul atau kode debug
    if titleL:find(q, 1, true) or codeL:find(q, 1, true) then
        return 450
    end
    -- 5. Multi-kata (semua kata ada di judul atau kode debug, tidak tembus ke ratusan ID acak)
    if #words > 1 then
        local textHay = titleL .. " " .. codeL
        local allOk = true
        for _, w in ipairs(words) do
            if not textHay:find(w, 1, true) then
                allOk = false
                break
            end
        end
        if allOk then return 350 end
    end
    -- 6. Khusus query angka murni: cocokkan persis per token ID item (mis. "242", "5706")
    if isNumericQ then
        local idsHay = "," .. tostring(entry.ids or "") .. ","
        if idsHay:find("," .. q .. ",", 1, true) then
            return 200
        end
    end
    return nil
end

local function buildFilteredPackList(queryStr)
    local q = trimStr(queryStr):lower()
    local words = {}
    if q ~= "" then
        for w in q:gmatch("%S+") do
            table.insert(words, w)
        end
    end
    local isNumericQ = (q ~= "" and q:match("^%d+$") ~= nil)

    local scored = {}
    for origIdx, item in ipairs(PACK_CATALOG) do
        local sc = scorePackMatch(item, q, words, isNumericQ)
        if sc then
            table.insert(scored, { item = item, score = sc, origIdx = origIdx })
        end
    end

    if q ~= "" then
        table.sort(scored, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            if #a.item.title ~= #b.item.title then return #a.item.title < #b.item.title end
            return a.origIdx < b.origIdx
        end)
    end

    local list = {}
    for _, s in ipairs(scored) do
        table.insert(list, s.item)
    end
    return list
end

local function updatePackResultsList()
    if not editValue then return end
    local q = trimStr(CFG.shop_search)
    local items = buildFilteredPackList(q)
    local rows = {}
    if q == "" then
        table.insert(rows, { string.format("Ketik nama di 'Cari Pack' (%d pack siap)", #PACK_CATALOG), "Atau pilih langsung dari kategori 'Pilih Pack' di bawah" })
        local limit = math.min(10, #items)
        for i = 1, limit do
            local it = items[i]
            local priceTxt = (tonumber(it.price) or 0) > 0 and (tostring(it.price) .. "g") or "Store"
            table.insert(rows, { string.format("%d. %s", i, sanitizeDialogText(it.title)), sanitizeDialogText(it.code) .. " | " .. priceTxt })
        end
    else
        local limit = math.min(25, #items)
        for i = 1, limit do
            local it = items[i]
            local priceTxt = (tonumber(it.price) or 0) > 0 and (tostring(it.price) .. " Gems") or "Store"
            table.insert(rows, { string.format("%d. %s", i, sanitizeDialogText(it.title)), "Kode: " .. sanitizeDialogText(it.code) .. " | " .. priceTxt })
        end
        if #rows == 0 then
            table.insert(rows, { "Tidak ada pack cocok: " .. q, "Coba kata lain mis: seed / surg / lock" })
        end
    end
    pcall(editValue, "bp_shop_results_list", encodeJsonValue(rows))
    return items
end

local function applySelectedPack(entry)
    if not entry then return end
    CFG.pack_name = entry.code
    if (tonumber(entry.price) or 0) > 0 then
        CFG.pack_price = math.floor(tonumber(entry.price))
        STATE.user_edited_price = false
        if editValue then pcall(editValue, "bp_pack_price", tostring(CFG.pack_price)) end
    end

    CFG.pack_item_ids_text = trimStr(entry.ids or "")
    CFG.auto_learn_items = true
    if editToggle then pcall(editToggle, "bp_auto_learn", true) end

    if editValue then
        pcall(editValue, "bp_pack_name", CFG.pack_name)
        pcall(editValue, "bp_item_ids", CFG.pack_item_ids_text)
    end
    savePrefs(CFG)

    local idInfo = (CFG.pack_item_ids_text ~= "") and "ID Otomatis Siap" or "Auto-Deteksi Saat Beli"
    local infoMsg = string.format("Dipilih: %s (%s) | %d Gems | %s",
        entry.title, entry.code, tonumber(entry.price) or 0, idInfo)
    setStatus("Pack Siap", infoMsg)
    notifyUser(infoMsg)
end

local function findBestPackMatch(rawInput)
    local q = trimStr(rawInput):lower()
    if q == "" then return nil end

    local idxNum = tonumber(q)
    if idxNum and idxNum >= 1 and math.floor(idxNum) == idxNum then
        local curFiltered = buildFilteredPackList(CFG.shop_search)
        if curFiltered[idxNum] then return curFiltered[idxNum] end
    end

    for _, it in ipairs(PACK_CATALOG) do
        if it.code:lower() == q then return it end
    end
    for _, it in ipairs(PACK_CATALOG) do
        if it.title:lower() == q then return it end
    end
    local filtered = buildFilteredPackList(rawInput)
    return filtered[1]
end

local function openPackPickerDialog(queryStr, pageOverride)
    if queryStr ~= nil then
        CFG.shop_search = trimStr(queryStr)
        savePrefs(CFG)
    end
    local items = buildFilteredPackList(CFG.shop_search)
    STATE.last_dialog_items = items

    local perPage = 15
    local totalPages = math.max(1, math.ceil(#items / perPage))
    local page = tonumber(pageOverride) or 1
    if page < 1 then page = 1 end
    if page > totalPages then page = totalPages end
    STATE.dialog_page = page

    if growtopia and growtopia.sendDialog then
        local lines = {
            "set_default_color|`o",
            "add_label_with_icon|big|`wAuto Buy By Boren - Cari Pack``|left|112|",
            string.format("add_textbox|`oList Debug: `2%d`o pack | Ditemukan: `2%d`o | Hal `w%d/%d`o.|left|", #PACK_CATALOG, #items, page, totalPages),
            "add_spacer|small|",
            string.format("add_text_input|shop_q|Cari Nama Pack:|%s|32|", sanitizeDialogText(CFG.shop_search or "")),
            "add_button|shop_search|`2Cari|noflags|0|0|",
            "add_button|shop_clear_q|`9Tampilkan Semua|noflags|0|0|",
            "add_spacer|small|",
        }
        if #items == 0 then
            table.insert(lines, "add_textbox|`4Tidak ada pack cocok dengan kata pencarianmu.|left|")
        else
            local startIdx = (page - 1) * perPage + 1
            local endIdx = math.min(#items, startIdx + perPage - 1)
            for i = startIdx, endIdx do
                local it = items[i]
                local priceTxt = (tonumber(it.price) or 0) > 0 and (tostring(it.price) .. " Gems") or "Gratis/Store"
                table.insert(lines, string.format("add_button|shop_pick_%d|`w%s (`5%s`w) [`2%s`w]|noflags|0|0|", i, sanitizeDialogText(it.title), priceTxt, sanitizeDialogText(it.code)))
            end
            if totalPages > 1 then
                if page > 1 then
                    table.insert(lines, "add_button|shop_page_prev|`6<< Sebelumnya|noflags|0|0|")
                end
                if page < totalPages then
                    table.insert(lines, "add_button|shop_page_next|`6Berikutnya >>|noflags|0|0|")
                end
            end
        end
        table.insert(lines, "end_dialog|boren_shop_browser|Tutup||")
        pcall(growtopia.sendDialog, table.concat(lines, "\n"))
        return true
    end
    return false
end
