-- [auto_buy_pack/06_parsers_inventory] Parser world/ID, inventaris, sinkron input GL, auto-learn isi pack
-- Tujuan : parseWorldAndDoor, parsePackItemIDs, snapshotInventory, getInvCount, hasReachedDropThreshold, readGL*, learnNewPackItems
-- Dependensi: 04, 05
-- Urutan load: 6 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 401-662 (salinan verbatim)

-- ============================================================================
-- 3. PARSERS & WORLD / INVENTORY HELPERS
-- ============================================================================
local function parseWorldAndDoor(rawWorld, rawDoor)
    local w = trimStr(rawWorld)
    local d = trimStr(rawDoor)
    if w:find("|", 1, true) then
        local wn, wd = w:match("^([^|]+)|(.*)$")
        w = trimStr(wn)
        if trimStr(wd) ~= "" then d = trimStr(wd) end
    elseif w:find(":", 1, true) then
        local wn, wd = w:match("^([^:]+):(.*)$")
        w = trimStr(wn)
        if trimStr(wd) ~= "" then d = trimStr(wd) end
    end
    return w:upper(), d
end

local function parsePackItemIDs(rawText)
    local ids = {}
    local seen = {}
    for token in tostring(rawText or ""):gmatch("[^,\r\n;%s]+") do
        local subId = tonumber(token)
        if subId and subId > 0 then
            subId = math.floor(subId)
            if not seen[subId] then
                seen[subId] = true
                table.insert(ids, subId)
            end
        elseif trimStr(token):lower() ~= "nul" and trimStr(token):lower() ~= "null" then
            if findItemID then
                local ok, id = pcall(findItemID, trimStr(token))
                if ok and tonumber(id) and tonumber(id) > 0 then
                    local fid = math.floor(tonumber(id))
                    if not seen[fid] then
                        seen[fid] = true
                        table.insert(ids, fid)
                    end
                end
            end
        end
    end
    return ids
end

local function getItemNameSafe(itemID)
    if getItemInfoByID then
        local ok, info = pcall(getItemInfoByID, itemID)
        if ok and info and info.name and info.name ~= "" then
            return tostring(info.name)
        end
    end
    if growtopia and growtopia.getItemName then
        local ok, nm = pcall(growtopia.getItemName, itemID)
        if ok and nm and nm ~= "" then
            return tostring(nm)
        end
    end
    return "ID " .. tostring(itemID)
end

local function getCurrentWorldSafe()
    if getCurrentWorldName then
        local ok, w = pcall(getCurrentWorldName)
        if ok and type(w) == "string" and w ~= "" then return w:upper() end
    end
    if getWorld then
        local ok, w = pcall(getWorld)
        if ok and w and w.name then return tostring(w.name):upper() end
    end
    return ""
end

local function isOnlineInWorld()
    if getLocal then
        local ok, p = pcall(getLocal)
        if not ok or not p then return false end
    end
    local w = getCurrentWorldSafe()
    return (w ~= "" and w ~= "EXIT")
end

local function getPlayerTilePos()
    if not getLocal then return nil, nil end
    local ok, p = pcall(getLocal)
    if not ok or not p then return nil, nil end
    local px = p.posX or (p.pos and p.pos.x)
    local py = p.posY or (p.pos and p.pos.y)
    if not px or not py then return nil, nil end
    return math.floor((px + 10) / 32), math.floor((py + 10) / 32)
end

local function snapshotInventory()
    local snap = {}
    if getInventory then
        local ok, inv = pcall(getInventory)
        if ok and type(inv) == "table" then
            for _, item in pairs(inv) do
                local id = tonumber(item.id or item.itemID or item.itemid)
                local amt = tonumber(item.amount or item.count) or 0
                if id and id > 0 and id ~= 112 and amt > 0 then
                    snap[id] = (snap[id] or 0) + amt
                end
            end
        end
    end
    return snap
end

local function getInvCount(itemID)
    if growtopia and growtopia.checkInventoryCount then
        local ok, cnt = pcall(growtopia.checkInventoryCount, itemID)
        if ok and type(cnt) == "number" then
            return cnt
        end
    end
    if getInventory then
        local ok, inv = pcall(getInventory)
        if ok and type(inv) == "table" then
            for _, item in pairs(inv) do
                if (item.id or item.itemID or item.itemid) == itemID then
                    return tonumber(item.amount or item.count) or 0
                end
            end
        end
    end
    return 0
end

local function hasAnyTrackedItem(itemIDs)
    if getInventory then
        local snap = snapshotInventory()
        for _, id in ipairs(itemIDs) do
            if (snap[id] or 0) > 0 then return true end
        end
        return false
    end
    for _, id in ipairs(itemIDs) do
        if getInvCount(id) > 0 then return true end
    end
    return false
end

local function hasReachedDropThreshold(itemIDs)
    local thresh = math.max(1, math.min(200, tonumber(CFG.drop_threshold) or 200))
    if getInventory then
        local snap = snapshotInventory()
        for _, id in ipairs(itemIDs) do
            if (snap[id] or 0) >= thresh then return true, id end
        end
        return false, nil
    end
    for _, id in ipairs(itemIDs) do
        if getInvCount(id) >= thresh then return true, id end
    end
    return false, nil
end

local function readGLRawString(alias)
    if getValue then
        local sawEmpty = false
        for _, vt in ipairs({ 2, 5, 1 }) do
            local ok, v = pcall(getValue, vt, alias)
            if ok and v ~= nil then
                local s = trimStr(tostring(v))
                if s ~= "" then return s end
                sawEmpty = true
            end
        end
        if sawEmpty then return "" end
    end
    return nil
end

local function readGLString(alias, fallback)
    local s = readGLRawString(alias)
    if s ~= nil and s ~= "" then return s end
    return fallback
end

local function readGLInt(alias)
    if getValue then
        for _, vt in ipairs({ 1, 2, 5 }) do
            local ok, v = pcall(getValue, vt, alias)
            if ok and v ~= nil then
                local cleaned = trimStr(tostring(v)):gsub("[,%s]", "")
                local n = tonumber(cleaned)
                if n then return math.floor(n) end
            end
        end
    end
    return nil
end

local function readGLBool(alias, fallback)
    if getValue then
        local ok, v = pcall(getValue, 0, alias)
        if ok and type(v) == "boolean" then return v end
    end
    return fallback
end

local function syncInputsFromGL()
    local pName = readGLString("bp_pack_name", "")
    if pName ~= "" then CFG.pack_name = trimStr(pName) end

    local iIds = readGLString("bp_item_ids", "")
    if iIds ~= "" then CFG.pack_item_ids_text = trimStr(iIds) end

    local pPrice = readGLInt("bp_pack_price")
    if pPrice and (pPrice > 0 or not STATE.user_edited_price) and pPrice >= 0 then
        CFG.pack_price = pPrice
    end

    local tPacks = readGLInt("bp_target_packs")
    if tPacks and (tPacks > 0 or not STATE.user_set_target) and tPacks >= 0 then
        CFG.target_packs = tPacks
    end

    local dWorld = readGLString("bp_drop_world", "")
    if dWorld ~= "" then CFG.drop_world = trimStr(dWorld):upper() end

    local dDoor = readGLString("bp_drop_door", "")
    if dDoor ~= "" then CFG.drop_door = trimStr(dDoor) end

    local dThresh = readGLInt("bp_drop_thresh")
    if dThresh and dThresh >= 1 then CFG.drop_threshold = math.min(200, dThresh) end

    CFG.use_gl_drop = readGLBool("bp_use_gl_drop", CFG.use_gl_drop)
    CFG.anti_retake = readGLBool("bp_anti_retake", CFG.anti_retake)
    CFG.auto_learn_items = readGLBool("bp_auto_learn", CFG.auto_learn_items)
end

local function learnNewPackItems(beforeInv, itemIDs)
    if not beforeInv then return false end
    local afterInv = snapshotInventory()
    local seen = {}
    for _, id in ipairs(itemIDs) do
        seen[id] = true
    end
    local addedAny = false
    for id, afterAmt in pairs(afterInv) do
        local prevAmt = beforeInv[id] or 0
        if afterAmt > prevAmt and (not seen[id]) then
            seen[id] = true
            table.insert(itemIDs, id)
            addedAny = true
            logMsg(string.format("Auto-Deteksi Isi Pack: +%s (ID %d)", getItemNameSafe(id), id))
        end
    end
    if addedAny then
        local strs = {}
        for _, id in ipairs(itemIDs) do
            table.insert(strs, tostring(id))
        end
        CFG.pack_item_ids_text = table.concat(strs, ", ")
        if editValue then pcall(editValue, "bp_item_ids", CFG.pack_item_ids_text) end
        savePrefs(CFG)
    end
    return addedAny
end
