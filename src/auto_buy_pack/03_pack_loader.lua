-- [auto_buy_pack/03_pack_loader] PACK_CATALOG, parser katalog, muat debugpack.txt
-- Tujuan : loadPacksIntoCatalog (kode pack unik, entri lebih baru menimpa), baca debugpack.txt kalau ada
-- Dependensi: 02_pack_data.lua
-- Urutan load: 3 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 210-268 (salinan verbatim)

local PACK_CATALOG = {}
local PACK_BY_CODE = {}

local function trimStr(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function sanitizeDialogText(s)
    return trimStr(tostring(s or ""):gsub("`.", "")):gsub("[|\r\n]+", " ")
end

local function loadPacksIntoCatalog(rawText)
    for line in tostring(rawText or ""):gmatch("[^\r\n]+") do
        local ln = trimStr(line)
        if ln ~= "" and ln:sub(1, 2) ~= "--" and ln ~= "]]" and (not ln:find("^packs%s*=")) then
            local name, code, priceStr, idsStr = ln:match("^([^:]+):([^:]*):([^:]*):(.*)$")
            name = trimStr(name)
            code = trimStr(code)
            if name ~= "" and code ~= "" then
                local cleanIds = {}
                for tok in tostring(idsStr or ""):gmatch("[^,%s;]+") do
                    local n = tonumber(tok)
                    if n and n > 0 then
                        table.insert(cleanIds, tostring(math.floor(n)))
                    end
                end
                local entry = {
                    title = name,
                    code = code,
                    price = tonumber(priceStr) or 0,
                    ids = table.concat(cleanIds, ","),
                }
                local key = code:lower()
                local existingIdx = PACK_BY_CODE[key]
                if existingIdx then
                    PACK_CATALOG[existingIdx] = entry
                else
                    table.insert(PACK_CATALOG, entry)
                    PACK_BY_CODE[key] = #PACK_CATALOG
                end
            end
        end
    end
end

loadPacksIntoCatalog(EMBEDDED_DEBUG_PACKS)

if io and io.open then
    for _, path in ipairs({ "debugpack.txt", "ScriptLua/debugpack.txt" }) do
        local f = io.open(path, "r")
        if f then
            local content = f:read("*a")
            f:close()
            loadPacksIntoCatalog(content)
            break
        end
    end
end
