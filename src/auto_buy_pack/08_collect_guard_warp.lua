-- [auto_buy_pack/08_collect_guard_warp] Guard auto-collect dan warp
-- Tujuan : applyDropCollectGuard (matikan Auto Collect, nyalakan Anti Collect), warpToWorld (join_request)
-- Dependensi: 04, 05
-- Urutan load: 8 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 864-938 (salinan verbatim)

-- ============================================================================
-- 5. ANTI-RETAKE COLLECT GUARD & WARP
-- ============================================================================
local function applyDropCollectGuard(droppingNow)
    if not CFG.anti_retake then
        STATE.anti_take_active = false
        return
    end
    STATE.anti_take_active = (droppingNow == true)
    if droppingNow then
        if STATE.saved_ac_toggle == nil then
            STATE.saved_ac_toggle = readGLBool("Auto Collect", false)
            STATE.saved_anti_toggle = readGLBool("Anti Collect", false)
        end
        if editToggle then
            pcall(editToggle, "Auto Collect", false)
            pcall(editToggle, "Anti Collect", true)
            pcall(editToggle, "AutoCollect", false)
            pcall(editToggle, "AntiCollect", true)
        elseif editValue then
            pcall(editValue, "Auto Collect", false)
            pcall(editValue, "Anti Collect", true)
        end
    else
        if editToggle then
            if STATE.saved_ac_toggle ~= nil then
                pcall(editToggle, "Auto Collect", STATE.saved_ac_toggle)
            end
            if STATE.saved_anti_toggle ~= nil then
                pcall(editToggle, "Anti Collect", STATE.saved_anti_toggle)
            end
        end
    end
end

local function warpToWorld(worldName, doorID, forceRewarp)
    worldName = trimStr(worldName):upper()
    doorID = trimStr(doorID)
    if worldName == "" then return false end

    local curW = getCurrentWorldSafe()
    local alreadyHere = (curW == worldName)
    local targetStr = (doorID ~= "") and (worldName .. "|" .. doorID) or worldName
    if alreadyHere and doorID == "" and (not forceRewarp) then
        return true
    end

    local startX, startY = getPlayerTilePos()
    setStatus("Warp World", (doorID ~= "") and ("Menuju " .. worldName .. ":" .. doorID) or ("Menuju " .. worldName))
    if sendPacket then
        pcall(sendPacket, 3, "action|join_request\nname|" .. targetStr .. "\ninvitedWorld|0\n")
    elseif growtopia and growtopia.warpTo then
        pcall(growtopia.warpTo, worldName)
    end

    local maxWait = math.max(2500, tonumber(CFG.delay_warp) or 4500)
    local elapsed = 0
    while STATE.running and elapsed < maxWait do
        safeSleep(250)
        elapsed = elapsed + 250
        if getCurrentWorldSafe() == worldName then
            if (not alreadyHere) or doorID == "" then
                safeSleep(650)
                return true
            end
            local npx, npy = getPlayerTilePos()
            if (startX and npx and (npx ~= startX or npy ~= startY)) or elapsed >= 1000 then
                safeSleep(450)
                return true
            end
        end
    end
    return (getCurrentWorldSafe() == worldName)
end
