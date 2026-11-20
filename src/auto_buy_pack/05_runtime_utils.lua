-- [auto_buy_pack/05_runtime_utils] notify, log, sleep aman, coroutine, status
-- Tujuan : notifyUser, logMsg, safeSleep, runInCoroutineSafe, setStatus, updateStatusList
-- Dependensi: 04_config_state.lua
-- Urutan load: 5 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 323-400 (salinan verbatim)

local function notifyUser(msg)
    msg = tostring(msg or "")
    if growtopia and growtopia.notify then
        pcall(growtopia.notify, msg)
    elseif sendNotification then
        pcall(sendNotification, msg)
    end
end

local function logMsg(msg)
    msg = "[Auto Buy By Boren] " .. tostring(msg or "")
    if LogToConsole then
        pcall(LogToConsole, msg)
    elseif log then
        pcall(log, msg)
    end
end

local function safeSleep(ms)
    local waitMs = math.max(0, tonumber(ms) or 0)
    if waitMs == 0 then return end
    if STATE.in_coroutine and CSleep then
        pcall(CSleep, waitMs)
    elseif sleep then
        pcall(sleep, waitMs)
    elseif CSleep then
        pcall(CSleep, waitMs)
    end
end

local function runInCoroutineSafe(fn)
    local wrapped = function()
        STATE.in_coroutine = true
        local ok, err = pcall(fn)
        STATE.in_coroutine = false
        if not ok then
            logMsg("Coroutine Error: " .. tostring(err))
        end
    end
    if runCoroutine then
        local okC, errC = pcall(runCoroutine, wrapped)
        if not okC then
            STATE.in_coroutine = false
            logMsg("Gagal runCoroutine: " .. tostring(errC))
            wrapped()
        end
    else
        wrapped()
    end
end

local updateStatusList

local function setStatus(step, detail)
    STATE.step = tostring(step or "Berjalan")
    STATE.detail = tostring(detail or "")
    logMsg(STATE.step .. " - " .. STATE.detail)
    if updateStatusList then
        pcall(updateStatusList)
    end
end

updateStatusList = function()
    if not editValue then return end
    local gemStr = "-"
    if getGems then
        local okG, g = pcall(getGems)
        if okG and g then gemStr = tostring(g) end
    end
    local runLabel = STATE.running and ("BERJALAN: " .. STATE.step) or ("BERHENTI (" .. STATE.step .. ")")
    local targetTxt = (CFG.target_packs > 0) and (tostring(STATE.packs_bought) .. "/" .. tostring(CFG.target_packs)) or (tostring(STATE.packs_bought) .. " (Habis)")
    local rows = {
        { runLabel, STATE.detail },
        { "How Many: " .. targetTxt .. " | Price: " .. tostring(CFG.pack_price), "Gems: " .. gemStr .. " | Drop: " .. tostring(STATE.items_dropped) },
    }
    pcall(editValue, "bp_status_list", encodeJsonValue(rows))
end
