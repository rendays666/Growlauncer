-- [output/auto_surg] Auto Surg v2.1 — bot bedah Growtopia (versi ponytail: efisien)
-- Perubahan utama vs v2.0:
--   * Parse daftar tool tersedia SEKALI per dialog (bukan scan berulang).
--   * Klasifikasi aturan jadi if/elseif tunggal, berhenti di aturan pertama cocok.
--   * Cek ketersediaan tool = lookup O(1), bukan string.find per tool.
--   * Pola gagal/sukses tetap dicek sekali.
-- Platform: GrowLauncher 7.0.x — Lua 5.4. Hook `onvariant`, packet teks `SendPacket(2, ...)`.

local CFG = {
    antiStuckBatas = 3,
    restartOtomatis = true,
    verbose = true,
}

local ID = {
    ["Sponge"]        = 1258,
    ["Scalpel"]       = 1260,
    ["Anesthetic"]    = 1262,
    ["Antibiotic"]    = 1266,
    ["Splint"]        = 1268,
    ["Stitches"]      = 1270,
    ["Fix it"]        = 1296,
    ["Pins"]          = 4308,
    ["Transfusion"]   = 4310,
    ["Defibrillator"] = 4312,
    ["Clamp"]         = 4314,
    ["Ultrasound"]    = 4316,
    ["Lab kit"]       = 4318,
}

local S = {
    stateTerakhir = "",
    toolTerakhir  = nil,
    macet         = 0,
    gagal         = 0,
    sukses        = 0,
    langkah       = 0,
}

local function has(t, s)
    return t ~= nil and t:find(s, 1, true) ~= nil
end

-- Ambil semua id tool yang tersedia dari dialog dalam satu pass.
local function parseTools(t)
    local avail = {}
    if t then
        for id in t:gmatch("tool(%d+)") do
            avail[tonumber(id)] = true
        end
    end
    return avail
end

local function hasTool(avail, nama)
    local id = ID[nama]
    return id ~= nil and avail[id] == true
end

local function pilihTersedia(avail, daftar)
    for i = 1, #daftar do
        local n = daftar[i]
        if avail[ID[n]] then return n end
    end
    return nil
end

local URUTAN_AMAN = {
    "Scalpel", "Ultrasound", "Antibiotic", "Lab kit", "Sponge",
    "Clamp", "Stitches", "Splint", "Pins", "Fix it",
    "Transfusion", "Defibrillator", "Anesthetic",
}

local function alternatif(avail, kecuali)
    for i = 1, #URUTAN_AMAN do
        local n = URUTAN_AMAN[i]
        if n ~= kecuali and avail[ID[n]] then return n end
    end
    return nil
end

local POLA_GAGAL = {
    "smashed your surgical robot", "abandoned your patient", "license is revoked",
    "failed to save them", "You failed", "The patient has died", "The patient died",
    "patient died", "The patient escaped", "permanently",
}

local POLA_SUKSES = {
    "saved your patient", "You saved", "operation was a success",
}

local function hitungSayatan(t)
    local n = t:match("Incisions: `%d(%d+)") or t:match("Incisions: (%d+)")
    return tonumber(n) or 0
end

local function bacaSuhu(t)
    local n = t:match("Temp: `%d([%d%.]+)") or t:match("Temp: ([%d%.]+)")
    return tonumber(n)
end

local function isGagal(t)
    for i = 1, #POLA_GAGAL do
        if has(t, POLA_GAGAL[i]) then return true end
    end
    return false
end

local function isSukses(t)
    for i = 1, #POLA_SUKSES do
        if has(t, POLA_SUKSES[i]) then return true end
    end
    return false
end

-- Klasifikasi aturan (prioritas atas-bawah). Return nama aturan + daftar tool kandidat.
local function classify(t, avail)
    local inc = hitungSayatan(t)
    local hasInc = inc > 0

    if has(t, "Heart stopped") or has(t, "heart has stopped") then
        return "jantung berhenti", { "Defibrillator" }
    end
    if has(t, "can't see") or has(t, "cannot see") or has(t, "can not see") or has(t, "hard to see") then
        return "pandangan buram", { "Sponge", "Scalpel" }
    end
    if has(t, "wakes up") or has(t, "screams") or has(t, "flails") or has(t, "Awake") or has(t, "Coming to") then
        return "pasien sadar", { "Anesthetic" }
    end
    if has(t, "losing blood") then
        if hasInc then return "perdarahan", { "Stitches", "Clamp" } end
        return "perdarahan", { "Clamp", "Stitches" }
    end
    if has(t, "Pulse: `4") or has(t, "Pulse: `6") or has(t, "very weak") or has(t, "extremely weak") then
        return "denyut lemah", { "Transfusion" }
    end
    if has(t, "Temp: `4") or has(t, "Temp: `6") or has(t, "climbing rapidly") or has(t, "fever") then
        return "suhu tubuh", { "Antibiotic", "Lab kit" }
    end
    do
        local suhu = bacaSuhu(t)
        if suhu ~= nil and suhu > 100.4 then
            return "suhu tubuh", { "Antibiotic", "Lab kit" }
        end
    end
    if has(t, "shattered") then
        if hasInc then return "tulang hancur", { "Pins", "Scalpel" } end
        return "tulang hancur", { "Scalpel", "Pins" }
    end
    if has(t, "broken") and not has(t, "shattered") then
        return "tulang patah", { "Splint" }
    end
    if has(t, "broke his") then
        return "tulang lengan/kaki", { "Stitches", "Splint" }
    end
    if has(t, "not been diagnosed") and inc == 0 then
        return "belum didiagnosis", { "Ultrasound", "Lab kit" }
    end
    if hasInc then
        return "selesaikan sayatan", { "Fix it", "Stitches" }
    end

    -- cadangan
    if avail[ID["Fix it"]] and avail[ID["Stitches"]] then
        return "Fix it + Stitches tersedia", { "Stitches", "Fix it" }
    end
    if avail[ID["Scalpel"]] then
        return "Scalpel tersedia", { "Scalpel", "Ultrasound" }
    end
    if avail[ID["Ultrasound"]] then
        return "Ultrasound tersedia", { "Ultrasound", "Lab kit" }
    end
    return nil, nil
end

local function log(teks)
    LogToConsole("`9[`cAutoSurg2`9] `w" .. teks)
end

local function logRingkas(teks)
    if CFG.verbose then log(teks) end
end

local function kirimTool(namaTool)
    local id = ID[namaTool]
    if not id then
        log("`4Tool tidak dikenal: " .. tostring(namaTool))
        return false
    end
    SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|tool" .. id)
    S.langkah = S.langkah + 1
    return true
end

local function kirimStart()
    SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|start")
end

local function periksaHasil(t)
    if isSukses(t) then
        S.sukses = S.sukses + 1
        log("`2Operasi sukses! `w(Total: " .. S.sukses .. " sukses / " .. S.gagal .. " gagal)")
        S.langkah = 0
        return
    end
    if isGagal(t) then
        S.gagal = S.gagal + 1
        log("`4Operasi gagal. `w(Total: " .. S.sukses .. " sukses / " .. S.gagal .. " gagal)")
        S.langkah = 0
    end
end

local function pilihTool(t, avail)
    local namaAturan, daftar = classify(t, avail)
    if not namaAturan then
        logRingkas("`6Tidak ada tombol tool yang cocok untuk dialog ini.")
        return nil, nil, nil
    end

    local terpilih = pilihTersedia(avail, daftar)
    if not terpilih then
        logRingkas("`6Tidak ada tombol tool yang cocok untuk dialog ini.")
        return nil, nil, nil
    end

    if t == S.stateTerakhir and terpilih == S.toolTerakhir then
        S.macet = S.macet + 1
    else
        S.macet = 0
    end

    if S.macet >= CFG.antiStuckBatas then
        local ganti = nil
        for i = 1, #daftar do
            local n = daftar[i]
            if n ~= terpilih and avail[ID[n]] then
                ganti = n
                break
            end
        end
        if not ganti then ganti = alternatif(avail, terpilih) end
        if ganti then
            log("`6[ANTI-STUCK] `w" .. terpilih .. " macet di keadaan yang sama, coba `c" .. ganti)
            terpilih = ganti
        else
            log("`4[ANTI-STUCK] Tidak ada tool alternatif yang tersedia.")
        end
        S.macet = 0
    end

    logRingkas("`w" .. terpilih .. " `7(" .. namaAturan .. ")")
    return terpilih, namaAturan, daftar
end

local function tangani(var)
    if not var then return false end

    local v1 = var.v1 or ""
    local t  = var.v2 or ""

    if has(v1, "OnConsoleMessage") then
        periksaHasil(t)
        return false
    end
    if not has(v1, "OnDialogRequest") then
        return false
    end

    local dialogBedah = has(t, "Pulse:") and has(t, "Incisions:")

    if isGagal(t) and not dialogBedah then
        if not CFG.restartOtomatis then
            log("`4Operasi gagal, restart otomatis dimatikan.")
            return false
        end
        S.gagal = S.gagal + 1
        log("`4Operasi gagal (#" .. S.gagal .. "), mulai ulang...")
        S.stateTerakhir = ""
        S.toolTerakhir = nil
        S.macet = 0
        kirimStart()
        return true
    end

    if not dialogBedah then return false end

    local avail = parseTools(t)
    local tool, namaAturan = pilihTool(t, avail)
    if not tool then return false end
    if not hasTool(avail, tool) then
        log("`4Tombol " .. tool .. " sudah tidak ada, batal kirim.")
        return false
    end

    if kirimTool(tool) then
        S.stateTerakhir = t
        S.toolTerakhir  = tool
        return true
    end
    return false
end

local terpasang = false
if addHook then terpasang = pcall(addHook, tangani, "onvariant") end
if not terpasang and AddHook then terpasang = pcall(AddHook, tangani, "OnVariant") end
if applyHook then pcall(applyHook) end

if not terpasang then
    log("`4Gagal memasang hook onvariant. Cek versi GrowLauncher.")
else
    log("`2Aktif `w— anti-stuck " .. CFG.antiStuckBatas .. "x, restart otomatis " ..
        (CFG.restartOtomatis and "`2ON" or "`4OFF"))
end

if sendDialog then
    pcall(sendDialog, {
        title   = "Auto Surg v2.1",
        message = "Bot bedah siap (versi efisien).\n\n" ..
                  "• Parse tool tersedia sekali per dialog\n" ..
                  "• Anti-stuck: ganti tool otomatis\n" ..
                  "• Restart otomatis saat pasien gagal\n" ..
                  "• Statistik sukses/gagal di log\n\n" ..
                  "Pakai tea & skill spice sebelum mulai.",
        confirm = "OKE",
        alias   = "OKE",
    })
end

if growtopia and growtopia.notify then
    pcall(growtopia.notify, "`2AUTO SURG v2.1 AKTIF")
end

AUTO_SURG = { state = S, config = CFG }
