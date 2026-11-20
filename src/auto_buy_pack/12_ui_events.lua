-- [auto_buy_pack/12_ui_events] UI GrowLauncher dan handler OnValue
-- Tujuan : buildUI (2 tab), OnValue (semua kontrol bp_*), pasang hook awal
-- Dependensi: semua segmen sebelumnya
-- Urutan load: 12 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 1658-1906 (salinan verbatim)

-- ============================================================================
-- 9. SIMPLE GROWLAUNCHER NATIVE UI & EVENT HANDLER
-- ============================================================================
local function classifyPackBucket(entry)
    local hay = (tostring(entry.title or "") .. " " .. tostring(entry.code or "")):lower()
    if hay:find("lock") or hay:find("door") or hay:find("vend") or hay:find("jammer")
        or hay:find("upgrade_backpack") or hay:find("clothes") or hay:find("checkout")
        or hay:find("change_addr") or hay:find("antigravity") or hay:find("building_blocks")
        or hay:find("advertiser") then
        return 1
    elseif hay:find("seed") or hay:find("spray") or hay:find("splice") or hay:find("farm")
        or hay:find("weather") or hay:find("blast") then
        return 2
    elseif hay:find("surg") or hay:find("fish") or hay:find("crime") or hay:find("silkwor")
        or hay:find("geiger") or hay:find("zombie") or hay:find("boo_pack") or hay:find("ecto")
        or hay:find("ghost") or hay:find("chem") or hay:find("science") then
        return 3
    end
    return 4
end

local function buildUI()
    if not (UserInterface and UserInterface.new and addIntoModule) then
        return
    end
    if addCategory then
        pcall(addCategory, "Auto Buy By Boren", "ShoppingCart")
    end

    -- Tab 1: Buy Pack + List Pack Menyatu di UI GL Asli (Tanpa Console ImGui Terpisah!)
    local uiBuy = UserInterface.new("1. Buy Pack", "ShoppingCart")
    uiBuy:addLabelApp("Auto Buy By Boren", "ShoppingCart")
    uiBuy:addToggleButton("START / STOP Buy Pack", false, "bp_run_power")
    uiBuy:addDisplayList("Status Bot (Console)", "[]", "bp_status_list")
    uiBuy:addDivider()
    uiBuy:addInputString("Cari Pack (Ketik Nama)", CFG.shop_search, "Cari", "Ketik nama mis: Small Seed / Surg / Blast", "Search", "bp_shop_search")
    uiBuy:addButton("Cari Spesifik di List GL", "bp_btn_filter_list")
    uiBuy:addButton("Pilih Hasil Pencarian (Popup Klik)", "bp_btn_open_search_popup")
    uiBuy:addDisplayList("Hasil Pencarian Spesifik (Tampilan Teks)", "[]", "bp_shop_results_list")

    if uiBuy.addDialog and uiBuy.addChildButton then
        local bucketDefs = {
            { title = "Pilih Pack: Locks, Basics & Baju", sub = "World Lock, Small Lock, Vend, Jammer, Baju, Upgrade" },
            { title = "Pilih Pack: Seeds, Farm, Weather & Blast", sub = "SSP, Rare Seed, Spray, Splice, Weather, Blast" },
            { title = "Pilih Pack: Profesi (Surg, Fish, Ghost, Crime)", sub = "Surgical Kit, Fishing, Ghost, Crime, Geiger, Science" },
            { title = "Pilih Pack: Theme Packs & Aksesoris", sub = "Astro, Vegas, Superhero, Shades, Vehicles, dll" },
        }
        local buckets = { {}, {}, {}, {} }
        for idx, entry in ipairs(PACK_CATALOG) do
            local b = classifyPackBucket(entry)
            table.insert(buckets[b], { idx = idx, entry = entry })
        end
        for b = 1, 4 do
            if #buckets[b] > 0 then
                local dlg = uiBuy:addDialog(bucketDefs[b].title, string.format("%s (%d pack)", bucketDefs[b].sub, #buckets[b]), {})
                if dlg and dlg.menu then
                    for _, itemRef in ipairs(buckets[b]) do
                        local it = itemRef.entry
                        local pTxt = (tonumber(it.price) or 0) > 0 and (tostring(it.price) .. "g") or "Store"
                        local btnLabel = string.format("%s (%s) [%s]", it.title, pTxt, it.code)
                        uiBuy:addChildButton(dlg.menu, btnLabel, "bp_dp_" .. tostring(itemRef.idx))
                    end
                end
            end
        end
    end

    uiBuy:addDivider()
    uiBuy:addInputString("Nama Pack Terpilih (Debug / Nama)", CFG.pack_name, "Pack", "Otomatis terisi tanpa perlu isi ID", "ShoppingBag", "bp_pack_name")
    uiBuy:addInputInt("Price (Harga 1 Pack)", tostring(CFG.pack_price), "Price", "100", "Diamond", "bp_pack_price")
    uiBuy:addInputInt("Jumlah Pack yg Dibeli (0 = Sampai Habis)", tostring(CFG.target_packs), "Jumlah Pack", "200 (0 = Sampai Habis)", "Flag", "bp_target_packs")
    if uiBuy.addExpandableToggle and uiBuy.addChildInputString and uiBuy.addChildToggle then
        local advIds = uiBuy:addExpandableToggle("Pengaturan ID Item (Otomatis dari Debug List)", false, "bp_adv_ids", false, true)
        uiBuy:addChildToggle(advIds.list_child, "Auto-Deteksi ID Tambahan saat Beli", CFG.auto_learn_items, "bp_auto_learn")
        uiBuy:addChildInputString(advIds.list_child, "ID Item Pack (Terisi Otomatis)", CFG.pack_item_ids_text, "ID List", "Otomatis dari list debug", "FormatListNumbered", "bp_item_ids")
    else
        uiBuy:addInputString("ID Item Pack (Terisi Otomatis)", CFG.pack_item_ids_text, "ID List", "Otomatis dari list debug", "FormatListNumbered", "bp_item_ids")
        uiBuy:addToggle("Auto-Deteksi ID Tambahan saat Beli", CFG.auto_learn_items, "bp_auto_learn", true)
    end

    -- Tab 2: World Save & Drop Settings
    local uiDrop = UserInterface.new("2. World Save", "Inventory")
    uiDrop:addLabelApp("Auto Buy By Boren - World Save", "Inventory")
    uiDrop:addInputString("World Save / Drop", CFG.drop_world, "World Save", "NAMAWORLD atau WORLD|DOOR", "Public", "bp_drop_world")
    uiDrop:addInputString("Door ID Save (Opsional)", CFG.drop_door, "Door ID", "Kosongkan jika tanpa ID", "DoorFront", "bp_drop_door")
    uiDrop:addInputInt("Auto-Drop Per (Max 200, Sisa tetap Drop)", tostring(CFG.drop_threshold), "Batas", "200", "Layers", "bp_drop_thresh")
    uiDrop:addDivider()
    uiDrop:addToggle("Pakai Drop GL (Tanpa Popup Allow)", CFG.use_gl_drop, "bp_use_gl_drop", true)
    uiDrop:addToggle("Anti-Take Item Saat Drop (Blok Collect & Hindari Item)", CFG.anti_retake, "bp_anti_retake", true)
    uiDrop:addButton("Set Titik Awal Drop di Posisi Saya", "bp_btn_set_drop_pos")
    uiDrop:addButton("Reset Titik Drop ke Otomatis (0,0)", "bp_btn_reset_drop_pos")
    uiDrop:addSlider("Max Stack Per Tile", 5, 19, CFG.max_stacks_per_tile, 1, false, "bp_max_stacks")
    uiDrop:addSlider("Delay Buy (ms)", 500, 3000, CFG.delay_buy, 100, false, "bp_delay_buy")
    uiDrop:addSlider("Delay Drop (ms)", 200, 1500, CFG.delay_drop, 50, false, "bp_delay_drop")
    uiDrop:addSlider("Delay Warp (ms)", 3000, 8000, CFG.delay_warp, 250, false, "bp_delay_warp")

    pcall(addIntoModule, uiBuy:generateJSON(), "Auto Buy By Boren")
    pcall(addIntoModule, uiDrop:generateJSON(), "Auto Buy By Boren")
    updateStatusList()
    updatePackResultsList()
    if runCoroutine then
        runInCoroutineSafe(function()
            safeSleep(450)
            updateStatusList()
            updatePackResultsList()
        end)
    end
end

local lastBtnTime = {}

local function applySearchQuery(newQuery, notifyIfMultiple)
    CFG.shop_search = trimStr(newQuery)
    STATE.last_seen_search_gl = readGLRawString("bp_shop_search")
    local found = updatePackResultsList() or buildFilteredPackList(CFG.shop_search)
    local qL = CFG.shop_search:lower()
    if qL ~= "" and (#found == 1 or (found[1] and (found[1].code:lower() == qL or found[1].title:lower() == qL))) then
        applySelectedPack(found[1])
    elseif notifyIfMultiple then
        notifyUser(string.format("Ditemukan %d pack untuk '%s'!", #found, CFG.shop_search))
    end
end

local function resolveLatestSearchQuery()
    local qRaw = readGLRawString("bp_shop_search")
    if qRaw ~= nil and qRaw ~= STATE.last_seen_search_gl then
        STATE.last_seen_search_gl = qRaw
        return qRaw
    end
    return CFG.shop_search
end

function OnValue(vtype, name, value)
    if type(name) ~= "string" then return end

    if name:sub(1, 7) == "bp_btn_" then
        local now = os and os.clock and os.clock() or 0
        if lastBtnTime[name] and (now - lastBtnTime[name]) < 0.25 then return end
        lastBtnTime[name] = now
    end

    if name == "bp_run_power" then
        if STATE.ignore_power_event then return end
        local wantOn = (value == true or value == 1 or value == "true" or value == "1")
        if wantOn == STATE.running then return end
        if wantOn then
            startBuyPack()
        else
            stopBuyPack()
        end
    elseif name:sub(1, 6) == "bp_dp_" then
        local idx = tonumber(name:sub(7))
        if idx and PACK_CATALOG[idx] then
            applySelectedPack(PACK_CATALOG[idx])
        end
    elseif name == "bp_shop_search" then
        applySearchQuery(value, false)
    elseif name == "bp_btn_filter_list" then
        ensureHooks()
        applySearchQuery(resolveLatestSearchQuery(), true)
    elseif name == "bp_btn_open_search_popup" then
        ensureHooks()
        CFG.shop_search = trimStr(resolveLatestSearchQuery())
        updatePackResultsList()
        openPackPickerDialog(CFG.shop_search, 1)
    elseif name == "bp_pack_name" then
        local newInput = trimStr(value)
        local changed = (newInput:lower() ~= trimStr(CFG.pack_name):lower())
        if changed then
            STATE.user_edited_price = false
        end
        CFG.pack_name = newInput
        if changed and newInput ~= "" then
            local exact = findBestPackMatch(newInput)
            if exact and (exact.code:lower() == newInput:lower() or exact.title:lower() == newInput:lower() or tonumber(newInput) ~= nil) then
                applySelectedPack(exact)
            end
        end
    elseif name == "bp_auto_learn" then
        CFG.auto_learn_items = (value == true or value == 1 or value == "true" or value == "1")
    elseif name == "bp_item_ids" then
        CFG.pack_item_ids_text = trimStr(value)
    elseif name == "bp_pack_price" then
        local n = tonumber((tostring(value):gsub("[,%s]", "")))
        if n and n >= 0 then
            CFG.pack_price = math.floor(n)
            STATE.user_edited_price = true
        end
        updateStatusList()
    elseif name == "bp_target_packs" then
        local n = tonumber((tostring(value):gsub("[,%s]", "")))
        if n and n >= 0 then
            CFG.target_packs = math.floor(n)
            STATE.user_set_target = (CFG.target_packs > 0)
        end
        updateStatusList()
    elseif name == "bp_drop_world" then
        CFG.drop_world = trimStr(value):upper()
    elseif name == "bp_drop_door" then
        CFG.drop_door = trimStr(value)
    elseif name == "bp_drop_thresh" then
        local n = tonumber(value)
        if n and n >= 1 then CFG.drop_threshold = math.min(200, math.floor(n)) end
    elseif name == "bp_use_gl_drop" then
        CFG.use_gl_drop = (value == true or value == 1 or value == "true" or value == "1")
    elseif name == "bp_anti_retake" then
        CFG.anti_retake = (value == true or value == 1 or value == "true" or value == "1")
    elseif name == "bp_btn_set_drop_pos" then
        local px, py = getPlayerTilePos()
        if px and py then
            CFG.drop_anchor_x = px
            CFG.drop_anchor_y = py
            notifyUser(string.format("Titik awal drop diset ke (%d, %d)", px, py))
        else
            notifyUser("Masuk ke world dulu untuk set posisi drop!")
        end
    elseif name == "bp_btn_reset_drop_pos" then
        CFG.drop_anchor_x = 0
        CFG.drop_anchor_y = 0
        notifyUser("Titik awal drop direset ke otomatis (0,0)")
    elseif name == "bp_max_stacks" then
        local n = tonumber(value)
        if n then CFG.max_stacks_per_tile = math.max(5, math.min(19, math.floor(n))) end
    elseif name == "bp_delay_buy" then
        local n = tonumber(value)
        if n then CFG.delay_buy = math.max(500, math.floor(n)) end
    elseif name == "bp_delay_drop" then
        local n = tonumber(value)
        if n then CFG.delay_drop = math.max(200, math.floor(n)) end
    elseif name == "bp_delay_warp" then
        local n = tonumber(value)
        if n then CFG.delay_warp = math.max(2500, math.floor(n)) end
    end

    savePrefs(CFG)
end

if addHook then
    pcall(addHook, onVariantHook, "onvariant")
    pcall(addHook, onSendPacketHook, "onsendpacket")
    pcall(addHook, onSendPacketRawHook, "onsendpacketraw")
    STATE.hooks_installed = true
end

if applyHook then
    pcall(applyHook)
end

pcall(buildUI)
