-- [auto_buy_pack/01_helpers_prefs_json] Header, Preferences, encoder JSON
-- Tujuan : loadPrefsObj/loadPref/savePrefs (boren_buy_pack.json) dan encodeJsonValue untuk daftar di UI
-- Dependensi: API loader: Preferences atau require("Preferences")
-- Urutan load: 1 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 1-87 (salinan verbatim)

--[[
    Auto Buy By Boren - Auto Buy Pack & Anti-Retake World Drop (GrowLauncher Android/PC)
    Fitur:
    1. Pencarian pack langsung dari List Debug (tanpa buka/render Shop).
       Nama pack, nama debug (Pack ID), harga gems, dan seluruh ID item isi pack otomatis terisi.
    2. Mendukung Price (harga 1 pack) & How Many (target pack, 0 = sampai gems habis).
    3. Auto Buy langsung via packet (action|buy\nitem|<debug_name>\n) di World Save + Drop Anti-Take.
]]

-- ============================================================================
-- 1. SAFE HELPERS & JSON / PREFERENCES
-- ============================================================================
local function loadPrefsObj()
    if Preferences and Preferences.new then
        local ok, p = pcall(function() return Preferences:new("boren_buy_pack.json") end)
        if ok and p then return p end
    end
    local okReq, PrefMod = pcall(require, "Preferences")
    if okReq and PrefMod and PrefMod.new then
        local ok, p = pcall(function() return PrefMod:new("boren_buy_pack.json") end)
        if ok and p then return p end
    end
    return nil
end

local PREF_STORE = loadPrefsObj()

local function loadPref(key, defaultVal)
    if PREF_STORE and PREF_STORE.get then
        local ok, val = pcall(function() return PREF_STORE:get(key, defaultVal) end)
        if ok and val ~= nil then return val end
    end
    return defaultVal
end

local function savePrefs(cfg)
    if not (PREF_STORE and PREF_STORE.set) then return end
    for k, v in pairs(cfg) do
        local tv = type(v)
        if tv == "string" or tv == "number" or tv == "boolean" then
            pcall(function() PREF_STORE:set(k, v) end)
        end
    end
    if PREF_STORE.save then
        pcall(function() PREF_STORE:save() end)
    end
end

local function escapeJsonStr(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return '"' .. s .. '"'
end

local function encodeJsonValue(v)
    local tv = type(v)
    if tv == "nil" then return "null"
    elseif tv == "boolean" then return v and "true" or "false"
    elseif tv == "number" then return tostring(v)
    elseif tv == "string" then return escapeJsonStr(v)
    elseif tv == "table" then
        local isArr = true
        local maxIdx = 0
        for k, _ in pairs(v) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                isArr = false
                break
            end
            if k > maxIdx then maxIdx = k end
        end
        if isArr then
            local parts = {}
            for i = 1, maxIdx do
                table.insert(parts, encodeJsonValue(v[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, val in pairs(v) do
                table.insert(parts, escapeJsonStr(k) .. ":" .. encodeJsonValue(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end
