-- [auto_buy_pack/11_buy_loop] Loop utama beli pack + start/stop
-- Tujuan : runBuyPackLoop (warp, beli lewat packet, verifikasi, drop), startBuyPack, stopBuyPack
-- Dependensi: 06, 07, 08, 09, 10
-- Urutan load: 11 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 1410-1657 (salinan verbatim)

-- ============================================================================
-- 8. MAIN DIRECT BUY PACK & DROP LOOP (TANPA RENDER SHOP)
-- ============================================================================
local function runBuyPackLoop()
    syncInputsFromGL()
    ensureHooks()

    local packCode = trimStr(CFG.pack_name)
    if packCode == "" and trimStr(CFG.shop_search) ~= "" then
        packCode = trimStr(CFG.shop_search)
    end
    if packCode == "" then
        setStatus("Error Input", "Cari & pilih pack dulu!")
        notifyUser("Cari & pilih pack dulu!")
        return
    end

    -- Auto-cocokkan ke database debugpack (isi nama debug, harga & seluruh ID item otomatis!)
    local matched = findBestPackMatch(packCode)
    if matched and (packCode:find("%s") ~= nil or tonumber(packCode) ~= nil or matched.code:lower() == packCode:lower() or matched.title:lower() == packCode:lower()) then
        packCode = matched.code
        CFG.pack_name = matched.code
        if editValue then pcall(editValue, "bp_pack_name", packCode) end
        if (not STATE.user_edited_price) and (tonumber(matched.price) or 0) > 0 and (CFG.pack_price == 2000 or CFG.pack_price == 0 or packCode ~= "world_lock") then
            CFG.pack_price = math.floor(tonumber(matched.price))
            if editValue then pcall(editValue, "bp_pack_price", tostring(CFG.pack_price)) end
        end
        if trimStr(CFG.pack_item_ids_text) == "" and trimStr(matched.ids or "") ~= "" then
            CFG.pack_item_ids_text = trimStr(matched.ids)
            if editValue then pcall(editValue, "bp_item_ids", CFG.pack_item_ids_text) end
        end
    end

    local itemIDs = parsePackItemIDs(CFG.pack_item_ids_text)
    if #itemIDs == 0 then
        CFG.auto_learn_items = true
    end

    local dropW, dropD = parseWorldAndDoor(CFG.drop_world, CFG.drop_door)
    if dropW == "" then
        setStatus("Error Input", "World Save belum diisi!")
        notifyUser("Isi World Save dulu!")
        return
    end

    STATE.packs_bought         = 0
    STATE.items_dropped        = 0
    STATE.full_drop_tiles      = {}
    STATE.backpack_full_flag   = false
    STATE.no_gems_flag         = false
    STATE.unknown_pack_flag    = false
    STATE.buy_server_confirmed = false
    STATE.last_store_msg       = ""
    STATE.buying_now           = false
    STATE.logged_store_block   = false

    local targetLabel = (CFG.target_packs > 0) and (tostring(CFG.target_packs) .. " pack") or "Sampai Habis"
    logMsg(string.format("Mulai Direct Buy: pack=%s | price=%d | jumlah=%s | world=%s", packCode, CFG.pack_price, targetLabel, dropW))
    setStatus("Masuk World Save", (dropD ~= "") and ("Warp ke " .. dropW .. ":" .. dropD) or ("Warp ke " .. dropW))

    if getCurrentWorldSafe() ~= dropW or dropD ~= "" then
        if not warpToWorld(dropW, dropD, true) then
            setStatus("Gagal Warp Save", "Gagal masuk ke World Save " .. dropW)
            return
        end
    end

    applyDropCollectGuard(true)

    local reachedPre = hasReachedDropThreshold(itemIDs)
    if reachedPre then
        if not dropPackItemsToWorld(itemIDs) then
            return
        end
    end

    local lastBeforeInv = nil
    local consecutiveBuyFails = 0
    while STATE.running do
        if not isOnlineInWorld() then
            setStatus("Menunggu Online", "Koneksi terputus, menunggu kembali online...")
            safeSleep(1500)
        else
            local curW = getCurrentWorldSafe()
            if curW ~= dropW then
                if not warpToWorld(dropW, dropD, true) then
                    safeSleep(1000)
                end
                applyDropCollectGuard(true)
            elseif CFG.target_packs > 0 and STATE.packs_bought >= CFG.target_packs then
                setStatus("Target Tercapai", string.format("Sudah beli %d/%d pack.", STATE.packs_bought, CFG.target_packs))
                break
            elseif CFG.pack_price > 0 and getGems and (function()
                local okG, curGems = pcall(getGems)
                if okG and type(curGems) == "number" and curGems < CFG.pack_price then
                    setStatus("Gems Habis", string.format("Sisa gems (%d) < harga pack (%d).", curGems, CFG.pack_price))
                    return true
                end
                return false
            end)() then
                break
            elseif STATE.no_gems_flag then
                setStatus("Gems Habis", "Server melaporkan gems tidak cukup.")
                break
            elseif STATE.unknown_pack_flag then
                setStatus("Pack Tidak Valid", "Kode debug '" .. packCode .. "' ditolak server!")
                notifyUser("Kode pack ditolak server: " .. packCode)
                break
            else
                local needDrop, fullId = hasReachedDropThreshold(itemIDs)
                if STATE.backpack_full_flag or needDrop then
                    STATE.backpack_full_flag = false
                    setStatus("Drop Item", fullId and (getItemNameSafe(fullId) .. " mencapai batas drop, drop di " .. dropW) or "Tas penuh, drop di " .. dropW)
                    if not dropPackItemsToWorld(itemIDs) then
                        break
                    end
                else
                    applyDropCollectGuard(true)
                    local targetDisp = (CFG.target_packs > 0) and tostring(CFG.target_packs) or "Habis"
                    setStatus("Membeli Pack", string.format("Beli '%s' #%d/%s (%d Gems) di %s", packCode, STATE.packs_bought + 1, targetDisp, CFG.pack_price, dropW))

                    local beforeInv = snapshotInventory()
                    local beforeGems = nil
                    if getGems then
                        local okBg, bg = pcall(getGems)
                        if okBg and type(bg) == "number" then beforeGems = bg end
                    end
                    lastBeforeInv = beforeInv
                    STATE.last_store_msg = ""
                    STATE.buy_server_confirmed = false
                    STATE.buying_now = true
                    STATE.suppress_store_until = getClockSec() + 3.0

                    -- Beli langsung via package tanpa render shop
                    if sendPacket then
                        pcall(sendPacket, 2, "action|buy\nitem|" .. packCode .. "\n")
                    end

                    local buyVerified = false
                    local waitBuy = 0
                    local minDelay = math.max(500, tonumber(CFG.delay_buy) or 1000)
                    while STATE.running and waitBuy < math.max(minDelay, 1300) do
                        safeSleep(100)
                        waitBuy = waitBuy + 100
                        if STATE.no_gems_flag or STATE.unknown_pack_flag or STATE.backpack_full_flag then
                            break
                        end
                        local gotNew = learnNewPackItems(beforeInv, itemIDs)
                        local curG = nil
                        if getGems then
                            local okCg, cg = pcall(getGems)
                            if okCg and type(cg) == "number" then curG = cg end
                        end
                        local invGained = gotNew
                        if not invGained then
                            local nowInv = snapshotInventory()
                            for id, nAmt in pairs(nowInv) do
                                if nAmt > (beforeInv[id] or 0) then
                                    invGained = true
                                    break
                                end
                            end
                        end
                        if (beforeGems and curG and curG < beforeGems) or invGained or STATE.buy_server_confirmed then
                            buyVerified = true
                            if waitBuy >= minDelay then
                                break
                            end
                        end
                    end

                    if buyVerified then
                        consecutiveBuyFails = 0
                        STATE.packs_bought = STATE.packs_bought + 1
                        updateStatusList()
                    elseif STATE.no_gems_flag or STATE.unknown_pack_flag or STATE.backpack_full_flag then
                        -- Ditangani iterasi berikutnya
                    else
                        consecutiveBuyFails = consecutiveBuyFails + 1
                        logMsg(string.format("Pembelian #%d belum terkonfirmasi (%d/4). Msg: %s", consecutiveBuyFails, 4, tostring(STATE.last_store_msg)))
                        if consecutiveBuyFails >= 4 then
                            local errTxt = (STATE.last_store_msg ~= "") and STATE.last_store_msg or ("Store tidak merespon kode '" .. packCode .. "'")
                            setStatus("Gagal Beli Pack", errTxt)
                            notifyUser("Gagal beli pack: " .. errTxt)
                            break
                        else
                            safeSleep(600)
                        end
                    end
                    STATE.buying_now = false
                end
            end
        end
    end

    if STATE.running and STATE.packs_bought > 0 then
        safeSleep(650)
        if lastBeforeInv then
            learnNewPackItems(lastBeforeInv, itemIDs)
        end
    end

    if STATE.running and hasAnyTrackedItem(itemIDs) then
        setStatus("Drop Akhir", "Drop semua sisa hasil beli ke " .. dropW)
        dropPackItemsToWorld(itemIDs)
    end

    applyDropCollectGuard(false)
    if STATE.running then
        notifyUser(string.format("Auto Buy selesai! Dibeli: %d pack | Dropped: %d item", STATE.packs_bought, STATE.items_dropped))
    end
end

local function setPowerToggleSilent(val)
    if not editToggle then return end
    STATE.ignore_power_event = true
    pcall(editToggle, "bp_run_power", val == true)
    STATE.ignore_power_event = false
end

local function startBuyPack()
    if STATE.running then return end
    ensureHooks()
    STATE.running = true
    updateStatusList()

    local function runner()
        local ok, err = pcall(runBuyPackLoop)
        if not ok then
            setStatus("Error", tostring(err))
            notifyUser("Error Buy Pack: " .. tostring(err))
        end
        STATE.running = false
        applyDropCollectGuard(false)
        setPowerToggleSilent(false)
        updateStatusList()
    end

    runInCoroutineSafe(runner)
end

local function stopBuyPack()
    STATE.running = false
    applyDropCollectGuard(false)
    setPowerToggleSilent(false)
    setStatus("Berhenti", "Dihentikan oleh user.")
end
