-- [auto_buy_pack/09_hooks] Hook: konfirmasi beli, dialog drop, blok collect (type 11)
-- Tujuan : onVariantHook, onSendPacketHook (popup picker), onSendPacketRawHook, ensureHooks
-- Dependensi: 04, 05, 07
-- Urutan load: 9 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 939-1135 (salinan verbatim)

-- ============================================================================
-- 6. HOOKS (BUY CONFIRMATION / DROP DIALOG / ANTI-TAKE TYPE 11)
-- ============================================================================
local function extractVariantString(val)
    if val == nil then return "" end
    local tv = type(val)
    if tv == "string" or tv == "number" or tv == "boolean" then
        return tostring(val)
    end
    local res = nil
    pcall(function()
        if val.getString then
            res = val:getString()
        elseif val.str then
            res = val.str
        elseif val.text then
            res = val.text
        end
    end)
    if res ~= nil then return tostring(res) end
    local okStr, s = pcall(tostring, val)
    return okStr and s or ""
end

local function extractVariantFields(var)
    if var == nil then return "", "" end
    local raw1, raw2, raw3
    pcall(function() raw1 = var.v1 end)
    pcall(function() raw2 = var.v2 end)
    pcall(function() raw3 = var.v3 end)
    if raw1 == nil then
        pcall(function() raw1 = var[1] or var[0] end)
    end
    if raw2 == nil then
        pcall(function()
            if var[0] ~= nil and var[1] ~= nil then
                raw2 = var[1]
            else
                raw2 = var[2]
            end
        end)
    end
    if raw1 == nil then
        pcall(function()
            if var.get then
                raw1 = var:get(0)
                raw2 = var:get(1)
                raw3 = var:get(2)
            end
        end)
    end
    return extractVariantString(raw1), extractVariantString(raw2), extractVariantString(raw3)
end

local function getClockSec()
    if os and os.clock then
        local ok, c = pcall(os.clock)
        if ok and type(c) == "number" then return c end
    end
    return 0
end

local function shouldSuppressStoreUI()
    if STATE.running then return true end
    local now = getClockSec()
    return now > 0 and STATE.suppress_store_until > now
end

local function onVariantHook(var, pkt)
    if var == nil then return false end
    local v1, v2, v3 = extractVariantFields(var)
    if v1 == "" then return false end
    local v1Low = v1:lower()
    local payload = (v2 ~= "" and v2) or (v3 ~= "" and v3) or ""
    local low = payload:lower()

    if v1Low == "onstorerequest" then
        if shouldSuppressStoreUI() then
            if not STATE.logged_store_block then
                STATE.logged_store_block = true
                logMsg("Tampilan Shop (OnStoreRequest) diblokir agar beli pack tetap di background.")
            end
            return true
        end
    elseif v1Low == "onstorepurchaseresult" then
        local cleanMsg = trimStr(payload:gsub("`.", ""))
        if cleanMsg ~= "" then
            STATE.last_store_msg = cleanMsg
            logMsg("Hasil Beli Store: " .. cleanMsg)
        end
        if low:find("not enough gems") or low:find("don't have enough gems") or low:find("insufficient gems") then
            STATE.no_gems_flag = true
        elseif low:find("backpack is full") or low:find("inventory is full") or low:find("can't carry") then
            STATE.backpack_full_flag = true
        elseif low:find("unknown item") or low:find("cannot purchase") or low:find("not available") then
            STATE.unknown_pack_flag = true
        elseif low:find("purchased") or low:find("bought") or low:find("success") then
            STATE.buy_server_confirmed = true
        end
        if shouldSuppressStoreUI() then
            return true
        end
    elseif v1Low == "onconsolemessage" or v1Low == "ontextoverlay" then
        local cleanMsg = trimStr(payload:gsub("`.", ""))
        if STATE.running and cleanMsg ~= "" and (low:find("gem") or low:find("buy") or low:find("pack") or low:find("store") or low:find("wait") or low:find("full") or low:find("unknown") or low:find("bought") or low:find("purchased")) then
            STATE.last_store_msg = cleanMsg
            logMsg("Server: " .. cleanMsg)
        end
        if low:find("not enough gems") or low:find("don't have enough gems") or low:find("insufficient gems") then
            STATE.no_gems_flag = true
        elseif low:find("backpack is full") or low:find("inventory is full") or low:find("can't carry any more") then
            STATE.backpack_full_flag = true
        elseif low:find("unknown item") or low:find("cannot purchase") or low:find("not available") then
            STATE.unknown_pack_flag = true
        elseif low:find("bought") or low:find("purchased") then
            STATE.buy_server_confirmed = true
        end
    elseif v1Low == "ondialogrequest" then
        if STATE.running and STATE.pending_drop_id and (low:find("drop") or low:find("how many")) then
            local dropAmt = tonumber(STATE.pending_drop_amt) or 1
            local idStr = tostring(STATE.pending_drop_id)
            local dialogName = payload:match("end_dialog|([^|\n]+)") or "drop_item"
            if dialogName:lower():find("drop") then
                if sendPacket then
                    pcall(sendPacket, 2, string.format("action|dialog_return\ndialog_name|%s\nitemID|%s|\ncount|%d\n", dialogName, idStr, dropAmt))
                end
                return true
            end
        elseif shouldSuppressStoreUI() and (not low:find("boren_shop_browser")) and (low:find("store") or low:find("purchase") or low:find("confirm") or low:find("buy") or (STATE.buying_now and (low:find("spend") or low:find("pack")))) then
            local dialogName = payload:match("end_dialog|([^|\r\n]+)")
            if dialogName and trimStr(dialogName) ~= "" and sendPacket then
                local btnName = payload:match("add_button|([^|\r\n]+)|")
                local extraBtn = (btnName and trimStr(btnName) ~= "" and btnName ~= "cancel" and btnName ~= "back")
                    and ("buttonClicked|" .. trimStr(btnName) .. "\n") or ""
                pcall(sendPacket, 2, "action|dialog_return\ndialog_name|" .. trimStr(dialogName) .. "\n" .. extraBtn)
                logMsg("Konfirmasi beli otomatis: " .. trimStr(dialogName))
            end
            return true
        end
    end
    return false
end

local function onSendPacketHook(ptype, pktStr)
    if type(pktStr) ~= "string" then return false end

    if pktStr:find("dialog_name|boren_shop_browser", 1, true) then
        local btn = pktStr:match("buttonClicked|([^\n|\r]+)") or ""
        local qIn = pktStr:match("shop_q|([^\n|\r]*)")
        if btn == "shop_clear_q" then
            CFG.shop_search = ""
            if editValue then pcall(editValue, "bp_shop_search", "") end
            savePrefs(CFG)
            updatePackResultsList()
            openPackPickerDialog("", 1)
        elseif btn == "shop_page_prev" then
            openPackPickerDialog(CFG.shop_search, (STATE.dialog_page or 1) - 1)
        elseif btn == "shop_page_next" then
            openPackPickerDialog(CFG.shop_search, (STATE.dialog_page or 1) + 1)
        elseif btn:sub(1, 10) == "shop_pick_" then
            local pidx = tonumber(btn:sub(11))
            local picked = pidx and STATE.last_dialog_items[pidx]
            if picked then
                applySelectedPack(picked)
            end
        elseif btn == "shop_search" or qIn ~= nil then
            CFG.shop_search = trimStr(qIn or CFG.shop_search)
            if editValue then pcall(editValue, "bp_shop_search", CFG.shop_search) end
            savePrefs(CFG)
            updatePackResultsList()
            openPackPickerDialog(CFG.shop_search, 1)
        end
        return true
    end
    return false
end

local function onSendPacketRawHook(pkt)
    if STATE.anti_take_active and type(pkt) == "table" and tonumber(pkt.type) == 11 then
        return true
    end
    return false
end

local function ensureHooks()
    if STATE.hooks_installed then return end
    STATE.hooks_installed = true
    if addHook then
        pcall(addHook, onVariantHook, "onvariant")
        pcall(addHook, onSendPacketHook, "onsendpacket")
        pcall(addHook, onSendPacketRawHook, "onsendpacketraw")
    end
    if applyHook then
        pcall(applyHook)
    end
end
