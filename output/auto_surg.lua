-- [output/auto_surg] Auto Surg v2.0 — bot bedah Growtopia (gabungan auto_surg + surg_exact)
-- Tujuan   : baca dialog Surgery, pilih tool yang benar, kirim klik lewat packet, restart otomatis saat gagal.
-- Sumber   : src/auto_surg (Moeyii, "Auto Surg V1.1 Fixed") + aturan teks src/surg_exact (DFNL5)
-- Platform : GrowLauncher 7.0.x — Lua 5.4. Hook `onvariant`, packet teks `SendPacket(2, ...)`.
-- Cara pakai: tempel seluruh file ini ke GrowLauncher, lalu jalankan sekali. Bot langsung aktif.
--
-- Perbaikan dibanding `src/auto_surg` (lihat notes/bugs.md):
--   #1 `itool` dihitung SETELAH anti-stuck memilih tool (dulu packet tetap memakai tool lama).
--   #2 Cabang perdarahan hanya mengirim packet kalau tombol Clamp/Stitches benar-benar ada.
--   #3 Tool yang tombolnya tidak ada dilewati, tidak pernah mengirim klik ke tombol hantu.
--   #4 Anti-stuck pindah ke alternatif dari aturan yang sama, baru jatuh ke daftar cadangan.
--   #5 Dialog non-surgery diabaikan (dulu `The patient` di dialog lain bisa memicu restart).
--   #6 Statistik sukses/gagal + langkah, untuk memantau bot dari log.

-- ============================================================================
-- 1. KONFIGURASI
-- ============================================================================

local CFG = {
    antiStuckBatas = 3,   -- berapa kali (state + tool) sama berulang sebelum ganti tool
    restartOtomatis = true,
    verbose = true,       -- false = log lebih sepi
}

-- ============================================================================
-- 2. ID TOOL (dari notes/auto_surg.md)
-- ============================================================================

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

-- ============================================================================
-- 3. STATE
-- ============================================================================

local S = {
    stateTerakhir = "",
    toolTerakhir  = nil,
    macet         = 0,
    gagal         = 0,
    sukses        = 0,
    langkah       = 0,
}

-- ============================================================================
-- 4. UTILITAS TEKS
-- ============================================================================

-- Pencarian literal (tanpa pattern), aman untuk teks dialog + kode warna.
local function ada(t, s)
    return t ~= nil and t:find(s, 1, true) ~= nil
end

local function adaTombol(t, namaTool)
    local id = ID[namaTool]
    return id ~= nil and ada(t, "tool" .. id)
end

-- Ambil tool pertama dari daftar yang tombolnya tersedia.
local function pilihTersedia(t, daftar)
    for _, nama in ipairs(daftar) do
        if adaTombol(t, nama) then
            return nama
        end
    end
    return nil
end

-- Urutan cadangan saat macet / aturan tidak cocok.
local URUTAN_AMAN = {
    "Scalpel", "Ultrasound", "Antibiotic", "Lab kit", "Sponge",
    "Clamp", "Stitches", "Splint", "Pins", "Fix it",
    "Transfusion", "Defibrillator", "Anesthetic",
}

local function alternatif(t, kecuali)
    for _, nama in ipairs(URUTAN_AMAN) do
        if nama ~= kecuali and adaTombol(t, nama) then
            return nama
        end
    end
    return nil
end

-- ============================================================================
-- 5. ATURAN (urutan = prioritas, pertama cocok menang)
--    Teks-persis surg_exact dipakai lebih dulu; kata kunci longgar sebagai jaring.
-- ============================================================================

local POLA_GAGAL = {
    "smashed your surgical robot",
    "abandoned your patient",
    "license is revoked",
    "failed to save them",
    "You failed",
    "The patient has died",
    "The patient died",
    "patient died",
    "The patient escaped",
    "permanently",
}

local POLA_SUKSES = {
    "saved your patient",
    "You saved",
    "operation was a success",
}

-- Baca jumlah sayatan dari teks dialog. Kode warna `2/`3 diabaikan, angkanya diambil.
-- Contoh: "Incisions: `23" -> 3, "Incisions: `20" -> 0, "Incisions: 0" -> 0
local function hitungSayatan(t)
    local n = t:match("Incisions: `%d(%d+)") or t:match("Incisions: (%d+)")
    return tonumber(n) or 0
end

local function sayatanSudahAda(t)
    return hitungSayatan(t) > 0
end

-- Suhu tubuh dalam Fahrenheit, nil kalau tidak ada.
local function bacaSuhu(t)
    local n = t:match("Temp: `%d([%d%.]+)") or t:match("Temp: ([%d%.]+)")
    return tonumber(n)
end

local ATURAN = {
    {
        nama  = "jantung berhenti",
        cocok = function(t) return ada(t, "Heart stopped") or ada(t, "heart has stopped") end,
        tools = { "Defibrillator" },
    },
    {
        nama  = "pandangan buram",
        cocok = function(t)
            return ada(t, "can't see") or ada(t, "cannot see") or ada(t, "can not see") or ada(t, "hard to see")
        end,
        tools = { "Sponge", "Scalpel" },
    },
    {
        nama  = "pasien sadar",
        cocok = function(t)
            return ada(t, "wakes up") or ada(t, "screams") or ada(t, "flails")
                or ada(t, "Awake") or ada(t, "Coming to")
        end,
        tools = { "Anesthetic" },
    },
    {
        nama  = "perdarahan",
        cocok = function(t) return ada(t, "losing blood") end,
        tools = function(t)
            if sayatanSudahAda(t) then
                return { "Stitches", "Clamp" }
            end
            return { "Clamp", "Stitches" }
        end,
    },
    {
        -- Hanya denyut yang lemah/kritis. "Pulse: `3normal" tidak boleh memicu transfusi.
        nama  = "denyut lemah",
        cocok = function(t)
            return ada(t, "Pulse: `4") or ada(t, "Pulse: `6")
                or ada(t, "very weak") or ada(t, "extremely weak")
        end,
        tools = { "Transfusion" },
    },
    {
        -- Demam: warna `4/`6, atau angka di atas 100.4F, atau "climbing rapidly".
        nama  = "suhu tubuh",
        cocok = function(t)
            if ada(t, "Temp: `4") or ada(t, "Temp: `6") or ada(t, "climbing rapidly") or ada(t, "fever") then
                return true
            end
            local suhu = bacaSuhu(t)
            return suhu ~= nil and suhu > 100.4
        end,
        tools = { "Antibiotic", "Lab kit" },
    },
    {
        nama  = "tulang hancur",
        cocok = function(t) return ada(t, "shattered") end,
        tools = function(t)
            if sayatanSudahAda(t) then
                return { "Pins", "Scalpel" }
            end
            return { "Scalpel", "Pins" }
        end,
    },
    {
        nama  = "tulang patah",
        cocok = function(t) return ada(t, "broken") and not ada(t, "shattered") end,
        tools = { "Splint" },
    },
    {
        nama  = "tulang lengan/kaki",
        cocok = function(t) return ada(t, "broke his") end,
        tools = { "Stitches", "Splint" },
    },
    {
        nama  = "belum didiagnosis",
        cocok = function(t) return ada(t, "not been diagnosed") and hitungSayatan(t) == 0 end,
        tools = { "Ultrasound", "Lab kit" },
    },
    {
        -- Sayatan sudah ada: tutup / selesaikan operasi.
        nama  = "selesaikan sayatan",
        cocok = function(t) return sayatanSudahAda(t) end,
        tools = { "Fix it", "Stitches" },
    },
}

-- Dipakai kalau tidak ada aturan yang cocok.
local CADANGAN = {
    {
        nama  = "Fix it + Stitches tersedia",
        cocok = function(t) return ada(t, "tool1296") and ada(t, "tool1270") end,
        tools = { "Stitches", "Fix it" },
    },
    {
        nama  = "Scalpel tersedia",
        cocok = function(t) return ada(t, "tool1260") end,
        tools = { "Scalpel", "Ultrasound" },
    },
    {
        nama  = "Ultrasound tersedia",
        cocok = function(t) return ada(t, "tool4316") end,
        tools = { "Ultrasound", "Lab kit" },
    },
}

-- ============================================================================
-- 6. LOG
-- ============================================================================

local function log(teks)
    LogToConsole("`9[`cAutoSurg2`9] `w" .. teks)
end

local function logRingkas(teks)
    if CFG.verbose then log(teks) end
end

-- ============================================================================
-- 7. PENGIRIMAN PACKET
-- ============================================================================

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

-- ============================================================================
-- 8. HASIL OPERASI (OnConsoleMessage)
-- ============================================================================

local function periksaHasil(t)
    for _, pola in ipairs(POLA_SUKSES) do
        if ada(t, pola) then
            S.sukses = S.sukses + 1
            log("`2Operasi sukses! `w(Total: " .. S.sukses .. " sukses / " .. S.gagal .. " gagal)")
            S.langkah = 0
            return
        end
    end
    for _, pola in ipairs(POLA_GAGAL) do
        if ada(t, pola) then
            S.gagal = S.gagal + 1
            log("`4Operasi gagal. `w(Total: " .. S.sukses .. " sukses / " .. S.gagal .. " gagal)")
            S.langkah = 0
            return
        end
    end
end

-- ============================================================================
-- 9. INTI: pilih tool + anti-stuck
-- ============================================================================

-- Cari nama aturan yang cocok beserta daftar tool kandidatnya.
local function cariAturan(t)
    for _, aturan in ipairs(ATURAN) do
        if aturan.cocok(t) then
            local daftar = type(aturan.tools) == "function" and aturan.tools(t) or aturan.tools
            local terpilih = pilihTersedia(t, daftar)
            if terpilih then
                return terpilih, aturan.nama, daftar
            end
        end
    end
    for _, aturan in ipairs(CADANGAN) do
        if aturan.cocok(t) then
            local terpilih = pilihTersedia(t, aturan.tools)
            if terpilih then
                return terpilih, aturan.nama, aturan.tools
            end
        end
    end
    return nil
end

local function pilihTool(t)
    local terpilih, namaAturan, daftar = cariAturan(t)

    if not terpilih then
        logRingkas("`6Tidak ada tombol tool yang cocok untuk dialog ini.")
        return nil
    end

    -- Anti-stuck: state yang sama + tool yang sama berulang.
    if t == S.stateTerakhir and terpilih == S.toolTerakhir then
        S.macet = S.macet + 1
    else
        S.macet = 0
    end

    if S.macet >= CFG.antiStuckBatas then
        local ganti = nil

        -- 1) alternatif berikutnya dari aturan yang sama
        for _, nama in ipairs(daftar) do
            if nama ~= terpilih and adaTombol(t, nama) then
                ganti = nama
                break
            end
        end

        -- 2) kalau habis, pakai daftar cadangan
        if not ganti then
            ganti = alternatif(t, terpilih)
        end

        if ganti then
            log("`6[ANTI-STUCK] `w" .. terpilih .. " macet di keadaan yang sama, coba `c" .. ganti)
            terpilih = ganti
        else
            log("`4[ANTI-STUCK] Tidak ada tool alternatif yang tersedia.")
        end
        S.macet = 0
    end

    logRingkas("`w" .. terpilih .. " `7(" .. namaAturan .. ")")
    return terpilih
end

-- ============================================================================
-- 10. HANDLER HOOK
-- ============================================================================

local function tangani(var)
    if not var then return false end

    local v1 = var.v1 or ""
    local t  = var.v2 or ""

    -- Hasil operasi lewat pesan konsol
    if ada(v1, "OnConsoleMessage") then
        periksaHasil(t)
        return false
    end

    if not ada(v1, "OnDialogRequest") then
        return false
    end

    local dialogBedah = ada(t, "Pulse:") and ada(t, "Incisions:")

    -- Gagal / pasien kabur / alat rusak: restart, tapi jangan salah tuduh dialog lain
    local gagal = false
    for _, pola in ipairs(POLA_GAGAL) do
        if ada(t, pola) then gagal = true break end
    end

    if gagal and not dialogBedah then
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

    -- Selain dialog bedah: jangan disentuh (dulu bot bisa ikut menekan dialog lain)
    if not dialogBedah then
        return false
    end

    local tool = pilihTool(t)
    if not tool then
        return false
    end

    if not adaTombol(t, tool) then
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

-- ============================================================================
-- 11. PENDAFTARAN HOOK
-- ============================================================================

-- Nama hook resmi huruf kecil + applyHook(). Fallback ke gaya lama kalau perlu.
local terpasang = false
if addHook then
    terpasang = pcall(addHook, tangani, "onvariant")
end
if not terpasang and AddHook then
    terpasang = pcall(AddHook, tangani, "OnVariant")
end
if applyHook then
    pcall(applyHook)
end

-- ============================================================================
-- 12. PEMBUKA
-- ============================================================================

if not terpasang then
    log("`4Gagal memasang hook onvariant. Cek versi GrowLauncher.")
else
    log("`2Aktif `w— anti-stuck " .. CFG.antiStuckBatas .. "x, restart otomatis " ..
        (CFG.restartOtomatis and "`2ON" or "`4OFF"))
end

if sendDialog then
    pcall(sendDialog, {
        title   = "Auto Surg v2.0",
        message = "Bot bedah siap.\n\n" ..
                  "• Aturan teks-persis + fallback kata kunci\n" ..
                  "• Anti-stuck: ganti tool otomatis\n" ..
                  "• Restart otomatis saat pasien gagal\n" ..
                  "• Statistik sukses/gagal di log\n\n" ..
                  "Pakai tea & skill spice sebelum mulai.",
        confirm = "OKE",
        alias   = "OKE",
    })
end

if growtopia and growtopia.notify then
    pcall(growtopia.notify, "`2AUTO SURG v2.0 AKTIF")
end

-- Pintu darurat / debug dari konsol: AUTO_SURG.state, AUTO_SURG.cfg.verbose = false
AUTO_SURG = { state = S, config = CFG }
