-- Debug Logger v1.2 (GrowLauncher)
-- Log semua variant (server -> client), paket kirim, dan paket raw dengan format
-- yang sama seperti debug bawaan launcher, plus COPY ALL.
--
-- Cara pakai:
--   * Buka modul "Debug Logger" di UI, atau pakai perintah chat: /dbg help
--   * COPY ALL mencoba 3 jalur sekaligus: clipboard (kalau launcher punya fungsinya),
--     kotak "Output" (tap, Select All, Copy), dan file debug_log.txt
--   * /dbg api = daftar semua fungsi launcher (untuk mencari fungsi clipboard)

local VER = "1.2"
local TAG = "[DBGLOG]"
local FILE = "debug_log.txt"
local FILE_API = "debug_api.txt"

local C = {
    enabled = true,
    log_variant = true,
    log_send = true,
    log_raw = false,
    log_game = false,
    log_value = false,
    autosave = false,
    max_entries = 500,
}
local filter_inc, filter_exc = {}, {}
local buf, seq = {}, 0
local last_flush = nil

-- instance lama jadi tidak aktif kalau script dimuat ulang
local ME = {}
pcall(function() _G.__DBG_TOKEN = ME end)
local function alive()
    local ok, t = pcall(function() return _G.__DBG_TOKEN end)
    return (not ok) or t == nil or t == ME
end

local function safe(f)
    local ok, r = pcall(f)
    if ok then return r end
    return nil
end

local function say(msg)
    local s = TAG .. " " .. tostring(msg)
    if LogToConsole then pcall(LogToConsole, s) elseif log then pcall(log, s) end
end

local function now_clock()
    return (os and os.clock and safe(os.clock)) or 0
end

-- jam dinding (detik) untuk throttle auto-simpan; os.clock itu waktu CPU, tidak cocok
local function wall()
    return (os and os.time and safe(os.time)) or now_clock()
end

local function stamp()
    return (os and os.date and safe(function() return os.date("%H:%M:%S") end)) or ""
end

-- ============ format ============
local function fmt(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "string" then return v end
    if t == "table" and depth < 3 then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do
            parts[#parts + 1] = tostring(k) .. "=" .. fmt(v[k], depth + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

-- baca semua parameter variant (param 0 = nama variant)
local function get_params(var)
    local out = {}
    if var == nil then return out end
    local mode
    if safe(function() return var.v1 end) ~= nil then mode = "v"
    elseif safe(function() return var[0] end) ~= nil then mode = "0"
    elseif safe(function() return var[1] end) ~= nil then mode = "1"
    elseif safe(function() return var:get(0) end) ~= nil then mode = "get" end
    if not mode then return out end
    for i = 0, 19 do
        local val
        if mode == "v" then val = safe(function() return var["v" .. (i + 1)] end)
        elseif mode == "0" then val = safe(function() return var[i] end)
        elseif mode == "1" then val = safe(function() return var[i + 1] end)
        else val = safe(function() return var:get(i) end) end
        if val == nil then break end
        out[#out + 1] = val
    end
    return out
end

local function fmt_variant(p)
    local lines = {}
    for i, v in ipairs(p) do
        lines[#lines + 1] = "param " .. tostring(i - 1) .. ": " .. fmt(v)
    end
    return "[" .. tostring(p[1]) .. "] " .. table.concat(lines, "\n")
end

-- ============ filter ============
local function parse_list(s)
    local t = {}
    for item in tostring(s or ""):gmatch("[^,]+") do
        item = item:match("^%s*(.-)%s*$"):lower()
        if item ~= "" then t[#t + 1] = item end
    end
    return t
end

local function hit(list, s)
    s = tostring(s):lower()
    for _, k in ipairs(list) do
        if s:find(k, 1, true) then return true end
    end
    return false
end

local function allowed(name, text)
    if #filter_exc > 0 and hit(filter_exc, name) then return false end
    if #filter_inc > 0 and not (hit(filter_inc, name) or hit(filter_inc, text)) then return false end
    return true
end

-- ============ buffer ============
local build, save_file

local function push(name, text)
    if not allowed(name, text) then return end
    seq = seq + 1
    buf[#buf + 1] = { n = seq, t = stamp(), text = text }
    while #buf > C.max_entries do table.remove(buf, 1) end
    if C.autosave and (last_flush == nil or wall() - last_flush >= 2) then
        last_flush = wall()
        save_file((build()))
    end
end

-- gabungkan entri; last = hanya N terakhir. return teks, jumlah entri
function build(last)
    local from = 1
    if last and last < #buf then from = #buf - last + 1 end
    local out, count = {}, 0
    for i = from, #buf do
        local e = buf[i]
        out[#out + 1] = "-- #" .. tostring(e.n) .. " " .. e.t
        out[#out + 1] = e.text
        out[#out + 1] = ""
        count = count + 1
    end
    return table.concat(out, "\n"), count
end

function save_file(text, path)
    path = path or FILE
    if writeToLocal and pcall(writeToLocal, path, text) then return true end
    if io and io.open then
        local f = safe(function() return io.open(path, "w") end)
        if f then
            local ok = pcall(function() f:write(text) end)
            pcall(function() f:close() end)
            return ok
        end
    end
    return false
end

-- ============ clipboard (deteksi otomatis, belum terbukti ada) ============
local function find_clip()
    local flat = { "setClipboard", "SetClipboard", "setClipboardText", "SetClipboardText",
                   "copyToClipboard", "CopyToClipboard", "copyClipboard", "clipboardCopy" }
    for _, n in ipairs(flat) do
        local f = safe(function() return _G[n] end)
        if type(f) == "function" then return n, f end
    end
    -- ImGui.SetClipboardText terbukti ada di dump API launcher (2026-11-21)
    local nested = { { "ImGui", "SetClipboardText" },
                     { "growtopia", "setClipboard" }, { "growtopia", "copyToClipboard" },
                     { "growtopia", "copy" }, { "clipboard", "set" }, { "clipboard", "copy" },
                     { "Clipboard", "set" }, { "Clipboard", "setText" } }
    for _, pair in ipairs(nested) do
        local f = safe(function() return _G[pair[1]][pair[2]] end)
        if type(f) == "function" then return pair[1] .. "." .. pair[2], f end
    end
    return nil, nil
end

-- ============ aksi ============
local function do_copy(last)
    local text, count = build(last)
    if count == 0 then say("Log kosong, belum ada yang tertangkap.") return end
    local res = {}
    local label, fn = find_clip()
    if fn then
        local ok, r = pcall(fn, text)
        local state = (ok and r ~= false) and "OK" or "GAGAL"
        -- verifikasi: baca balik clipboard kalau launcher menyediakan GetClipboardText
        if state == "OK" and label == "ImGui.SetClipboardText" then
            local back = safe(function() return ImGui.GetClipboardText() end)
            if back ~= nil then
                state = (back == text) and "OK-terverifikasi" or "OK-tapi-isi-beda"
            end
        end
        res[#res + 1] = "clipboard=" .. state .. "(" .. label .. ")"
    else
        res[#res + 1] = "clipboard=tidak-ada"
    end
    local box = editValue and pcall(editValue, "dbg_out", text)
    res[#res + 1] = "kotak-output=" .. (box and "OK" or "tidak-ada")
    if not last then
        res[#res + 1] = "file=" .. (save_file(text) and ("OK(" .. FILE .. ")") or "GAGAL")
    end
    say((last and ("Copy " .. tostring(last) .. " terakhir") or "Copy ALL") .. ": " .. tostring(count)
        .. " entri, " .. tostring(#text) .. " karakter | " .. table.concat(res, " | "))
end

local function do_save()
    local text, count = build()
    if count == 0 then say("Log kosong.") return end
    say("Simpan: " .. (save_file(text) and ("OK -> " .. FILE) or "GAGAL") .. " (" .. tostring(count) .. " entri)")
end

local function do_clear()
    buf = {}
    pcall(function() if editValue then editValue("dbg_out", "") end end)
    say("Log dikosongkan.")
end

-- daftar fungsi/tabel global launcher, untuk mencari fungsi yang belum diketahui
local function do_api()
    -- os dan io sengaja ikut didaftar (untuk tahu apakah io.open tersedia)
    local std = { string = 1, table = 1, math = 1, coroutine = 1, package = 1,
                  debug = 1, utf8 = 1, _G = 1, _ENV = 1 }
    local lines, clipish = { "_VERSION=" .. tostring(_VERSION) }, {}
    lines[#lines + 1] = "growlauncher.version=" .. tostring(safe(function() return growlauncher.version end))
    lines[#lines + 1] = "growlauncher.getVersion()=" .. tostring(safe(function() return growlauncher.getVersion() end))
    local function mark(name)
        local l = name:lower()
        if l:find("clip", 1, true) or l:find("copy", 1, true) then clipish[#clipish + 1] = name end
    end
    local names = {}
    pcall(function()
        for k in pairs(_G) do
            -- sembunyikan token internal script ini supaya tidak terbaca sebagai API launcher
            if type(k) == "string" and k:sub(1, 6) ~= "__DBG_" then names[#names + 1] = k end
        end
    end)
    table.sort(names)
    for _, k in ipairs(names) do
        local v = safe(function() return _G[k] end)
        local t = type(v)
        if t == "function" then
            lines[#lines + 1] = "function " .. k
            mark(k)
        elseif (t == "table" or t == "userdata") and not std[k] then
            local subs = {}
            pcall(function()
                for sk, sv in pairs(v) do
                    if type(sk) == "string" then
                        subs[#subs + 1] = sk .. (type(sv) == "function" and "()" or "")
                        mark(k .. "." .. sk)
                    end
                end
            end)
            table.sort(subs)
            lines[#lines + 1] = t .. " " .. k .. ": " .. table.concat(subs, ", ")
        end
    end
    local ok = save_file(table.concat(lines, "\n"), FILE_API)
    say("Dump API: " .. tostring(#lines) .. " baris -> " .. (ok and FILE_API or "gagal simpan"))
    say("Kandidat clipboard/copy: " .. (#clipish > 0 and table.concat(clipish, ", ") or "tidak ada"))
    pcall(function() if editValue then editValue("dbg_out", table.concat(lines, "\n")) end end)
end

local function do_status()
    say("Aktif=" .. tostring(C.enabled) .. " variant=" .. tostring(C.log_variant)
        .. " kirim=" .. tostring(C.log_send) .. " raw=" .. tostring(C.log_raw)
        .. " | entri=" .. tostring(#buf) .. "/" .. tostring(C.max_entries)
        .. " | hanya=[" .. table.concat(filter_inc, ",") .. "] abaikan=[" .. table.concat(filter_exc, ",") .. "]")
end

local function do_help()
    say("/dbg copy [N] | last | save | clear | api | status | on | off | raw | game | value | filter a,b | ignore a,b")
end

local function handle_cmd(s)
    local a, rest = s:match("^(%S*)%s*(.-)%s*$")
    a = (a or ""):lower()
    if a == "copy" then do_copy(tonumber(rest))
    elseif a == "last" then do_copy(1)
    elseif a == "save" then do_save()
    elseif a == "clear" then do_clear()
    elseif a == "api" then do_api()
    elseif a == "status" then do_status()
    elseif a == "on" then C.enabled = true say("Logging ON")
    elseif a == "off" then C.enabled = false say("Logging OFF")
    elseif a == "raw" then C.log_raw = not C.log_raw say("Log raw = " .. tostring(C.log_raw))
    elseif a == "game" then C.log_game = not C.log_game say("Log GamePacket = " .. tostring(C.log_game))
    elseif a == "value" then C.log_value = not C.log_value say("Log Value = " .. tostring(C.log_value))
    elseif a == "filter" then filter_inc = parse_list(rest) say("Hanya tampilkan: [" .. table.concat(filter_inc, ",") .. "]")
    elseif a == "ignore" then filter_exc = parse_list(rest) say("Abaikan: [" .. table.concat(filter_exc, ",") .. "]")
    else do_help() end
end

-- ============ hook ============
local function on_variant(var)
    if not alive() or not C.enabled or not C.log_variant then return false end
    pcall(function()
        local p = get_params(var)
        if #p == 0 then return end
        if tostring(p[1]) == "OnConsoleMessage" and tostring(p[2] or ""):find(TAG, 1, true) then return end
        push(tostring(p[1]), fmt_variant(p))
    end)
    return false
end

local function on_send(ptype, pkt)
    if not alive() or type(pkt) ~= "string" then return false end
    local cmd = pkt:match("|text|/dbg%s*([^\n]*)")
    if cmd then
        pcall(handle_cmd, cmd)
        return true
    end
    if C.enabled and C.log_send then
        pcall(function()
            local first = pkt:match("^[^\n]*") or ""
            push("SEND " .. first, "[SEND type=" .. tostring(ptype) .. "]\n" .. pkt)
        end)
    end
    return false
end

-- onGamePacket(pkt): paket TankUpdate dari server (setara "GameTankUpdate" di debug bawaan)
local function on_game(pkt)
    if alive() and C.enabled and C.log_game and type(pkt) == "table" then
        pcall(function() push("GAMEPACKET", "[GAMEPACKET] " .. fmt(pkt)) end)
    end
    return false
end

-- onValue(type,name,value): perubahan nilai UI (setara "Value Debugger")
local function on_value_hook(vtype, name, value)
    if alive() and C.enabled and C.log_value and type(name) == "string" and name:sub(1, 4) ~= "dbg_" then
        pcall(function()
            push("VALUE " .. name, "[VALUE] type=" .. tostring(vtype) .. " name=" .. name .. " value=" .. tostring(value))
        end)
    end
    return false
end

local function on_raw(pkt)
    if alive() and C.enabled and C.log_raw and type(pkt) == "table" then
        pcall(function() push("SENDRAW", "[SENDRAW] " .. fmt(pkt)) end)
    end
    return false
end

-- ============ UI ============
local prevOnValue = OnValue
local last_btn = {}

function OnValue(vtype, name, value)
    if type(name) ~= "string" or name:sub(1, 4) ~= "dbg_" then
        if prevOnValue then return prevOnValue(vtype, name, value) end
        return
    end
    if not alive() then return end
    if name:sub(1, 8) == "dbg_btn_" then
        -- blok hanya kalau waktu CPU DAN jam dinding sama-sama menunjukkan klik ganda;
        -- os.clock saja tidak cukup karena waktu CPU lambat saat launcher idle
        local c, w = now_clock(), wall()
        local last = last_btn[name]
        if last and c - last.c < 0.25 and w - last.w < 1 then return end
        last_btn[name] = { c = c, w = w }
    end
    local on = (value == true or value == 1 or value == "true" or value == "1")
    if name == "dbg_power" then C.enabled = on
    elseif name == "dbg_v" then C.log_variant = on
    elseif name == "dbg_s" then C.log_send = on
    elseif name == "dbg_r" then C.log_raw = on
    elseif name == "dbg_g" then C.log_game = on
    elseif name == "dbg_val" then C.log_value = on
    elseif name == "dbg_auto" then C.autosave = on
    elseif name == "dbg_max" then
        local n = tonumber(value)
        if n and n >= 10 then C.max_entries = math.floor(n) end
    elseif name == "dbg_filter" then filter_inc = parse_list(value)
    elseif name == "dbg_ignore" then filter_exc = parse_list(value)
    elseif name == "dbg_btn_copy" then do_copy(nil)
    elseif name == "dbg_btn_last" then do_copy(1)
    elseif name == "dbg_btn_save" then do_save()
    elseif name == "dbg_btn_clear" then do_clear()
    elseif name == "dbg_btn_api" then do_api()
    end
end

local function build_ui()
    if not (UserInterface and UserInterface.new and addIntoModule) then
        say("UI launcher tidak tersedia, pakai perintah chat: /dbg help")
        return
    end
    local ok, err = pcall(function()
        if addCategory then pcall(addCategory, "Debug Logger", "BugReport") end
        local ui = UserInterface.new("Debug Logger", "BugReport")
        ui:addLabelApp("Debug Logger v" .. VER, "BugReport")
        ui:addToggleButton("START / STOP Logging", true, "dbg_power")
        ui:addToggle("Log Variant (server ke client)", true, "dbg_v", true)
        ui:addToggle("Log Paket Kirim (client ke server)", true, "dbg_s", true)
        ui:addToggle("Log Paket Raw (ramai)", false, "dbg_r", true)
        ui:addToggle("Log GamePacket (TankUpdate, ramai)", false, "dbg_g", true)
        ui:addToggle("Log perubahan Value UI", false, "dbg_val", true)
        ui:addToggle("Auto-simpan ke file (tiap 2 detik)", false, "dbg_auto", true)
        ui:addInputInt("Maks entri disimpan", tostring(C.max_entries), "Maks", "500", "Layers", "dbg_max")
        ui:addInputString("Hanya tampilkan (pisah koma)", "", "Filter", "mis: OnDialogRequest, wrench", "FilterList", "dbg_filter")
        ui:addInputString("Abaikan (pisah koma)", "", "Abaikan", "mis: OnSetPos, OnUpdateRespawnTimeout", "VisibilityOff", "dbg_ignore")
        ui:addButton("COPY ALL", "dbg_btn_copy")
        ui:addButton("Copy 1 Entri Terakhir", "dbg_btn_last")
        ui:addButton("Simpan ke File", "dbg_btn_save")
        ui:addButton("Hapus Log", "dbg_btn_clear")
        ui:addButton("Dump API Launcher (cari fungsi clipboard)", "dbg_btn_api")
        ui:addInputString("Output (tap, Select All, Copy)", "", "Output", "isi muncul setelah Copy All", "ContentCopy", "dbg_out")
        addIntoModule(ui:generateJSON(), "Debug Logger")
    end)
    if not ok then say("Gagal membuat UI: " .. tostring(err) .. " | pakai /dbg help") end
end

-- ============ start ============
local function install_hooks()
    if addHook then
        -- nama event huruf kecil sesuai dokumentasi resmi
        pcall(addHook, on_variant, "onvariant")
        pcall(addHook, on_send, "onsendpacket")
        pcall(addHook, on_raw, "onsendpacketraw")
        pcall(addHook, on_game, "ongamepacket")
        pcall(addHook, on_value_hook, "onvalue")
        if applyHook then pcall(applyHook) end
    elseif AddHook then
        pcall(AddHook, on_variant, "OnVariant")
        pcall(AddHook, on_send, "OnSendPacket")
        pcall(AddHook, on_game, "OnGamePacket")
    else
        say("Fungsi hook tidak ditemukan, script tidak bisa menangkap apa pun.")
    end
end

install_hooks()
build_ui()
local clip_name = find_clip()
say("v" .. VER .. " aktif. Clipboard API: "
    .. (clip_name or "tidak ditemukan (pakai kotak Output / file; jalankan /dbg api)")
    .. ". Ketik /dbg help")
