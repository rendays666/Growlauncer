-- [auto_buy_pack/10_drop_engine] Mesin drop anti-retake
-- Tujuan : isTilePassable, isDropTileUsable, moveToDropStand, findAntiRetakeDropSlot, dropSingleItemAntiRetake, dropPackItemsToWorld
-- Dependensi: 04, 05, 06, 08
-- Urutan load: 10 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 1136-1409 (salinan verbatim)

-- ============================================================================
-- 7. WORLD DROP ENGINE (ANTI-RETAKE + GL CONFIRM DROP)
-- ============================================================================
local function isTilePassable(tx, ty)
    if tx < 1 or tx > 98 or ty < 1 or ty > 53 then return false end
    if not getTile then return true end
    local ok, t = pcall(getTile, tx, ty)
    if not ok or not t then return true end
    if t.collidable then return false end
    local fg = tonumber(t.fg) or 0
    if fg == 4 or fg == 8 or fg == 2 or fg == 10 or fg == 242 or fg == 202 then
        return false
    end
    return true
end

local function isDropTileUsable(tx, ty)
    if not isTilePassable(tx, ty) then return false end
    local key = tostring(tx) .. "," .. tostring(ty)
    if STATE.full_drop_tiles[key] then return false end

    local fn = getObjectList or getObjects
    if fn then
        local ok, objs = pcall(fn)
        if ok and type(objs) == "table" then
            local stackCount = 0
            local totalQty = 0
            for _, obj in pairs(objs) do
                if obj and obj.pos then
                    local ox = math.floor((obj.pos.x + 10) / 32)
                    local oy = math.floor((obj.pos.y + 10) / 32)
                    if ox == tx and oy == ty then
                        stackCount = stackCount + 1
                        totalQty = totalQty + (tonumber(obj.amount) or 1)
                    end
                end
            end
            if stackCount >= (tonumber(CFG.max_stacks_per_tile) or 18) or totalQty >= 3600 then
                STATE.full_drop_tiles[key] = true
                return false
            end
        end
    end
    return true
end

local function moveToDropStand(standX, standY, dropX)
    if FindPath then
        local okChk, blocked = pcall(FindPath, standX, standY, true)
        if okChk and blocked == true then return false end
        local okMove = pcall(FindPath, standX, standY)
        if not okMove then return false end
        safeSleep(160)
    end

    local px, py = getPlayerTilePos()
    if px and py and (px ~= standX or py ~= standY) then
        return false
    end

    if sendPacketRaw then
        local faceLeft = (dropX < standX)
        pcall(sendPacketRaw, false, {
            type  = 0,
            state = faceLeft and 48 or 32,
            x     = standX * 32,
            y     = standY * 32,
        })
        safeSleep(70)
    end
    return true
end

local function hasFloorObjectsAt(tx, ty)
    local fn = getObjectList or getObjects
    if not fn then return false end
    local ok, objs = pcall(fn)
    if ok and type(objs) == "table" then
        for _, obj in pairs(objs) do
            if obj and obj.pos then
                local ox = math.floor((obj.pos.x + 10) / 32)
                local oy = math.floor((obj.pos.y + 10) / 32)
                if ox == tx and oy == ty then
                    return true
                end
            end
        end
    end
    return false
end

local function hasCleanHorizontalPath(fromX, toX, ty)
    if not fromX then return true end
    local step = (toX >= fromX) and 1 or -1
    for sx = fromX, toX, step do
        if hasFloorObjectsAt(sx, ty) then
            return false
        end
    end
    return true
end

local function findAntiRetakeDropSlot(anchorX, anchorY)
    local px, py = getPlayerTilePos()
    local offsetsY = { 0, -1, 1, -2, 2 }
    for _, requireCleanFloor in ipairs({ true, false }) do
        if (not requireCleanFloor) and px and py and px >= 1 and px <= 97 and (not hasFloorObjectsAt(px, py)) and isDropTileUsable(px + 1, py) then
            return px + 1, py, px
        end
        for _, dy in ipairs(offsetsY) do
            local ty = anchorY + dy
            if ty >= 2 and ty <= 53 then
                if requireCleanFloor and px and py == ty and px >= 1 and px <= 97 and (not hasFloorObjectsAt(px, ty)) then
                    local dxRight = px + 1
                    if isDropTileUsable(dxRight, ty) and (not hasFloorObjectsAt(dxRight, ty)) then
                        return dxRight, ty, px
                    end
                end
                for dx = 0, -24, -1 do
                    local dropX = anchorX + dx
                    local standX = dropX - 1
                    if dropX >= 2 and dropX <= 98 and standX >= 1 and isTilePassable(standX, ty) and isDropTileUsable(dropX, ty) then
                        local pathOk = (not requireCleanFloor) or ((not hasFloorObjectsAt(standX, ty)) and (not hasFloorObjectsAt(dropX, ty)) and ((py ~= ty) or hasCleanHorizontalPath(px, standX, ty)))
                        if pathOk then
                            return dropX, ty, standX
                        end
                    end
                end
                for dx = 1, 16 do
                    local dropX = anchorX + dx
                    local standX = dropX + 1
                    if dropX >= 1 and dropX <= 97 and standX <= 98 and isTilePassable(standX, ty) and isDropTileUsable(dropX, ty) then
                        local pathOk = (not requireCleanFloor) or ((not hasFloorObjectsAt(standX, ty)) and (not hasFloorObjectsAt(dropX, ty)) and ((py ~= ty) or hasCleanHorizontalPath(px, standX, ty)))
                        if pathOk then
                            return dropX, ty, standX
                        end
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function dropSingleItemAntiRetake(itemID, anchorX, anchorY)
    local amt = getInvCount(itemID)
    if amt <= 0 then return true end

    local attempts = 0
    while STATE.running and amt > 0 and attempts < 8 do
        attempts = attempts + 1
        local dropX, dropY, standX = findAntiRetakeDropSlot(anchorX, anchorY)
        if not dropX then
            setStatus("World Drop Penuh", "Tidak ditemukan tile kosong di world drop!")
            return false
        end

        if not moveToDropStand(standX, dropY, dropX) then
            STATE.full_drop_tiles[tostring(dropX) .. "," .. tostring(dropY)] = true
        else
            local beforeAmt = getInvCount(itemID)
            local dropAmt = math.min(200, beforeAmt)
            STATE.pending_drop_id = itemID
            STATE.pending_drop_amt = dropAmt

            local usedConfirmDrop = false
            if CFG.use_gl_drop and growtopia and growtopia.confirmDropItem then
                pcall(growtopia.confirmDropItem, itemID, dropAmt)
                usedConfirmDrop = true
            elseif sendPacket then
                pcall(sendPacket, 2, string.format("action|drop\n|itemID|%d\n", itemID))
            end

            local waited = 0
            local afterAmt = beforeAmt
            while STATE.running and waited < 1400 do
                safeSleep(60)
                waited = waited + 60
                afterAmt = getInvCount(itemID)
                if afterAmt < beforeAmt then break end
            end

            if afterAmt >= beforeAmt and usedConfirmDrop and sendPacket and STATE.running then
                pcall(sendPacket, 2, string.format("action|drop\n|itemID|%d\n", itemID))
                waited = 0
                while STATE.running and waited < 1200 do
                    safeSleep(60)
                    waited = waited + 60
                    afterAmt = getInvCount(itemID)
                    if afterAmt < beforeAmt then break end
                end
            end

            STATE.pending_drop_id = nil
            STATE.pending_drop_amt = nil

            if afterAmt < beforeAmt then
                STATE.items_dropped = STATE.items_dropped + (beforeAmt - afterAmt)
                safeSleep(CFG.delay_drop)
                amt = afterAmt
            else
                STATE.full_drop_tiles[tostring(dropX) .. "," .. tostring(dropY)] = true
                amt = afterAmt
            end
        end
    end

    return (getInvCount(itemID) <= 0)
end

local function dropPackItemsToWorld(itemIDs)
    if not hasAnyTrackedItem(itemIDs) then
        return true
    end

    local dropW, dropD = parseWorldAndDoor(CFG.drop_world, CFG.drop_door)
    if dropW == "" then
        setStatus("Error Drop", "World Save belum diisi!")
        notifyUser("Isi World Save dulu!")
        return false
    end

    applyDropCollectGuard(true)

    if getCurrentWorldSafe() ~= dropW then
        if not warpToWorld(dropW, dropD) then
            setStatus("Gagal Warp Drop", "Gagal masuk ke world save " .. dropW)
            return false
        end
    end

    applyDropCollectGuard(true)
    safeSleep(250)

    local px, py = getPlayerTilePos()
    local anchorX = (tonumber(CFG.drop_anchor_x) or 0) > 0 and math.floor(CFG.drop_anchor_x) or (px or 50)
    local anchorY = (tonumber(CFG.drop_anchor_y) or 0) > 0 and math.floor(CFG.drop_anchor_y) or (py or 23)

    if getInventory then
        local snap = snapshotInventory()
        for _, itemID in ipairs(itemIDs) do
            if not STATE.running then break end
            if (snap[itemID] or 0) > 0 then
                setStatus("Drop Pack", string.format("Drop %s x%d di %s (Anti-Retake)", getItemNameSafe(itemID), snap[itemID], dropW))
                if not dropSingleItemAntiRetake(itemID, anchorX, anchorY) then
                    return false
                end
            end
        end
    else
        for _, itemID in ipairs(itemIDs) do
            if not STATE.running then break end
            local cnt = getInvCount(itemID)
            if cnt > 0 then
                setStatus("Drop Pack", string.format("Drop %s x%d di %s (Anti-Retake)", getItemNameSafe(itemID), cnt, dropW))
                if not dropSingleItemAntiRetake(itemID, anchorX, anchorY) then
                    return false
                end
            end
        end
    end

    local fpx, fpy = getPlayerTilePos()
    if fpx and fpy then
        local stepAwayX = (fpx <= anchorX) and (fpx - 1) or (fpx + 1)
        if stepAwayX >= 1 and stepAwayX <= 98 and isTilePassable(stepAwayX, fpy) and (not hasFloorObjectsAt(stepAwayX, fpy)) then
            if FindPath then pcall(FindPath, stepAwayX, fpy) end
            safeSleep(120)
        end
    end

    return true
end
