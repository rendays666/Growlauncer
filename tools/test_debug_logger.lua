-- Uji tools/debug_logger.lua dengan API launcher palsu. Jalankan dari root repo: texlua tools/test_debug_logger.lua
local SCRIPT = (arg and arg[1]) or "tools/debug_logger.lua"

local pass, fail = 0, 0
local function check(name, cond, extra)
    if cond then pass = pass + 1; print("PASS  " .. name)
    else fail = fail + 1; print("FAIL  " .. name .. (extra and ("  -> " .. tostring(extra)) or "")) end
end

-- ---- dialog dari user (potongan nyata) ----
local DIALOG = table.concat({
 "embed_data|netID|1",
 "add_popup_name|WrenchMenu|",
 "set_default_color|`o",
 "add_player_info|`2Dr.Lalafii``|57|160108|162550|",
 "add_button|renew_pvp_license|Get Card Battle License|noflags|0|0|",
 "add_custom_label|(66/183)|target:alist;top:0.72;left:0.5;size:small|",
 "add_textbox|`oCurrent world: `wCUREWOSH`` (`w6``, `w54``) (`w1`` person)````|left|",
 "end_dialog|popup||Continue|",
 "add_quick_exit|",
 "",
 "action|wrench",
 "|netid|1"}, "\n")

-- ---- stub API launcher ----
local console, files, boxes, hooks, ui_calls = {}, {}, {}, {}, {}
function LogToConsole(s) console[#console + 1] = s end
function writeToLocal(path, text) files[path] = text end
function editValue(name, v) boxes[name] = v end
function addHook(fn, name) hooks[name] = fn end
function applyHook() end
function addCategory(n, i) ui_calls[#ui_calls + 1] = "cat:" .. n end
function addIntoModule(json, mod) ui_calls[#ui_calls + 1] = "module:" .. mod .. ":" .. json end
UserInterface = { new = function(title, icon)
    local o = { items = {} }
    local function add(kind) return function(self, ...) self.items[#self.items + 1] = kind .. ":" .. tostring(select(-1, ...)) end end
    o.addLabelApp = add("label"); o.addToggleButton = add("togglebtn"); o.addToggle = add("toggle")
    o.addInputInt = add("int"); o.addInputString = add("str"); o.addButton = add("btn")
    function o:generateJSON() return table.concat(self.items, ",") end
    return o
end }
local prevCalls = {}
function OnValue(vt, name, value) prevCalls[#prevCalls + 1] = name end   -- OnValue milik script lain (mis. Boren)

local function last_console() return console[#console] or "" end

-- ---- muat script ----
dofile(SCRIPT)
check("5 hook terpasang", hooks.onvariant and hooks.onsendpacket and hooks.onsendpacketraw and hooks.ongamepacket and hooks.onvalue)
check("UI dibuat (1 modul, 13+ kontrol)", ui_calls[#ui_calls] and ui_calls[#ui_calls]:find("module:Debug Logger") and select(2, ui_calls[#ui_calls]:gsub(",", ",")) >= 13)
check("pesan start menyebut clipboard tidak ditemukan", last_console():find("tidak ditemukan", 1, true))

-- ---- tangkap variant, format = launcher ----
hooks.onvariant({ v1 = "OnDialogRequest", v2 = DIALOG })
hooks.onvariant({ v1 = "OnUpdateRespawnTimeout", v2 = 0 })
local r = hooks.onsendpacket(2, "action|wrench\n|netid|1")
check("hook kirim tidak menelan paket biasa", r == false)
hooks.onvariant({ v1 = "OnConsoleMessage", v2 = "[DBGLOG] pesan sendiri" })   -- harus diabaikan (anti-loop)

hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
local out = files["debug_log.txt"]
check("file debug_log.txt terisi", out and #out > 100)
local expect_dialog = "[OnDialogRequest] param 0: OnDialogRequest\nparam 1: " .. DIALOG
check("format variant identik dengan debug bawaan (param 0/param 1)", out:find(expect_dialog, 1, true) ~= nil)
check("variant angka: param 1: 0", out:find("[OnUpdateRespawnTimeout] param 0: OnUpdateRespawnTimeout\nparam 1: 0", 1, true) ~= nil)
check("paket kirim tercatat", out:find("[SEND type=2]\naction|wrench\n|netid|1", 1, true) ~= nil)
check("pesan [DBGLOG] sendiri tidak ikut tercatat (anti-loop)", not out:find("pesan sendiri", 1, true))
check("perintah /dbg tidak ikut tercatat", not out:find("/dbg copy", 1, true))
check("kotak Output terisi sama dengan file", boxes.dbg_out == out)
check("perintah /dbg ditelan (return true)", hooks.onsendpacket(2, "action|input\n|text|/dbg status") == true)
check("log copy menyebut 3 jalur", last_console() and console[#console - 1]:find("Copy ALL: 3 entri", 1, true) and console[#console - 1]:find("clipboard=tidak-ada", 1, true))

-- ---- bentuk var lain ----
hooks.onvariant({ [0] = "OnZero", [1] = "a", [2] = "b" })
hooks.onvariant({ "OnOne", "x", "y" })
hooks.onvariant(setmetatable({}, { __index = function(_, k) if k == "get" then return nil end end }))  -- var kosong
local getobj = { get = function(self, i) return ({ [0] = "OnGet", [1] = "g1" })[i] end }
hooks.onvariant(getobj)
hooks.onvariant({ v1 = "OnMulti", v2 = "p1", v3 = 42, v4 = { x = 1, y = 2 } })
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
out = files["debug_log.txt"]
check("var 0-based", out:find("[OnZero] param 0: OnZero\nparam 1: a\nparam 2: b", 1, true))
check("var 1-based", out:find("[OnOne] param 0: OnOne\nparam 1: x\nparam 2: y", 1, true))
check("var dengan :get()", out:find("[OnGet] param 0: OnGet\nparam 1: g1", 1, true))
check("v3 angka dan v4 tabel", out:find("param 2: 42\nparam 3: {x=1, y=2}", 1, true))

-- ---- var yang melempar error tidak merusak ----
local bad = setmetatable({}, { __index = function() error("boom") end })
local okbad = pcall(hooks.onvariant, bad)
check("var yang error tidak melempar", okbad)

-- ---- raw ----
hooks.onsendpacketraw({ type = 3, value = 18, x = 1, y = 2 })
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("raw default mati (tidak tercatat)", not files["debug_log.txt"]:find("SENDRAW", 1, true))
hooks.onsendpacket(2, "action|input\n|text|/dbg raw")
hooks.onsendpacketraw({ type = 3, value = 18, x = 1, y = 2 })
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("raw dicatat setelah /dbg raw", files["debug_log.txt"]:find("[SENDRAW] {type=3, value=18, x=1, y=2}", 1, true))

-- ---- filter ----
hooks.onsendpacket(2, "action|input\n|text|/dbg clear")
hooks.onsendpacket(2, "action|input\n|text|/dbg ignore OnUpdateRespawnTimeout, onzero")
hooks.onvariant({ v1 = "OnUpdateRespawnTimeout", v2 = 0 })
hooks.onvariant({ v1 = "OnZero", v2 = "q" })
hooks.onvariant({ v1 = "OnDialogRequest", v2 = DIALOG })
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
out = files["debug_log.txt"]
check("ignore menyembunyikan nama (case-insensitive)", not out:find("OnUpdateRespawnTimeout", 1, true) and not out:find("OnZero", 1, true) and out:find("OnDialogRequest", 1, true))
hooks.onsendpacket(2, "action|input\n|text|/dbg ignore")
hooks.onsendpacket(2, "action|input\n|text|/dbg filter wrenchmenu")
hooks.onvariant({ v1 = "OnSetPos", v2 = "1,2" })
hooks.onvariant({ v1 = "OnDialogRequest", v2 = DIALOG })
hooks.onsendpacket(2, "action|input\n|text|/dbg clear")
hooks.onvariant({ v1 = "OnSetPos", v2 = "1,2" })
hooks.onvariant({ v1 = "OnDialogRequest", v2 = DIALOG })
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
out = files["debug_log.txt"]
check("filter 'wrenchmenu' cocok isi dialog, OnSetPos disaring", out:find("WrenchMenu", 1, true) and not out:find("OnSetPos", 1, true))
hooks.onsendpacket(2, "action|input\n|text|/dbg filter")

-- ---- copy N terakhir tidak menimpa file penuh ----
hooks.onsendpacket(2, "action|input\n|text|/dbg clear")
for i = 1, 5 do hooks.onvariant({ v1 = "OnN" .. i, v2 = "v" .. i }) end
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
local full = files["debug_log.txt"]
hooks.onsendpacket(2, "action|input\n|text|/dbg copy 2")
check("copy 2: kotak Output berisi 2 entri terakhir", boxes.dbg_out:find("OnN5", 1, true) and boxes.dbg_out:find("OnN4", 1, true) and not boxes.dbg_out:find("OnN3", 1, true))
check("copy 2 tidak menimpa file penuh", files["debug_log.txt"] == full)

-- ---- batas entri ----
OnValue("int", "dbg_max", "10")
for i = 1, 25 do hooks.onvariant({ v1 = "OnCap" .. i, v2 = "v" }) end
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
local _, n = files["debug_log.txt"]:gsub("%-%- #", "")
check("batas entri 10 dipatuhi", n == 10, n)
check("entri tertua terbuang, terbaru dipertahankan", not files["debug_log.txt"]:find("OnCap1\n", 1, true) and files["debug_log.txt"]:find("OnCap25", 1, true))

-- ---- clipboard terdeteksi ----
local clip
function setClipboard(t) clip = t end
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("clipboard dipanggil bila fungsinya ada", clip == files["debug_log.txt"], clip and #clip)
check("log melaporkan clipboard=OK(setClipboard)", console[#console]:find("clipboard=OK(setClipboard)", 1, true))
setClipboard = nil
growtopia = { setClipboard = function(t) clip = "G:" .. t:sub(1, 3) end }
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("clipboard nested growtopia.setClipboard", clip and clip:sub(1, 2) == "G:" and console[#console]:find("growtopia.setClipboard", 1, true))
growtopia = nil

-- ---- UI OnValue ----
OnValue("button", "dbg_btn_clear", true)
check("tombol Hapus Log", boxes.dbg_out == "")
hooks.onvariant({ v1 = "OnBtn", v2 = "1" })
OnValue("button", "dbg_btn_last", true)
check("tombol Copy 1 terakhir mengisi kotak", boxes.dbg_out and boxes.dbg_out:find("OnBtn", 1, true))
OnValue("toggle", "dbg_power", false)
hooks.onvariant({ v1 = "OnPaused", v2 = "1" })
OnValue("toggle", "dbg_power", true)
OnValue("button", "dbg_btn_save", true)
check("STOP logging menghentikan tangkapan", not files["debug_log.txt"]:find("OnPaused", 1, true))
OnValue("other", "bp_btn_x", 1)
check("OnValue milik script lain diteruskan (tidak bentrok)", prevCalls[#prevCalls] == "bp_btn_x")

-- ---- dump API ----
function setClipboardText() end
OnValue("button", "dbg_btn_api", true)
check("dump API tersimpan dan menandai kandidat clipboard", files["debug_api.txt"] and files["debug_api.txt"]:find("setClipboardText", 1, true) and console[#console]:find("setClipboardText", 1, true))
setClipboardText = nil

-- ---- autosave ----
OnValue("toggle", "dbg_auto", true)
files["debug_log.txt"] = nil
hooks.onvariant({ v1 = "OnAuto", v2 = "1" })
check("autosave menulis file saat ada entri", files["debug_log.txt"] and files["debug_log.txt"]:find("OnAuto", 1, true))
OnValue("toggle", "dbg_auto", false)

-- ---- clipboard ImGui (bentuk launcher asli: tanpa SetClipboard global) ----
local store
ImGui = { SetClipboardText = function(t) store = t end, GetClipboardText = function() return store end }
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("ImGui.SetClipboardText dipakai, isi sama dengan file", store ~= nil and store == files["debug_log.txt"])
check("ImGui clipboard terverifikasi via GetClipboardText", console[#console]:find("clipboard=OK-terverifikasi(ImGui.SetClipboardText)", 1, true))
ImGui.GetClipboardText = function() return "isi lain" end
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("deteksi bila isi clipboard tidak sama", console[#console]:find("OK-tapi-isi-beda", 1, true))
ImGui.SetClipboardText = function() error("native error") end
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("error pada SetClipboardText dilaporkan GAGAL, tidak crash", console[#console]:find("clipboard=GAGAL(ImGui.SetClipboardText)", 1, true))
check("kotak Output + file tetap jalan walau clipboard gagal", console[#console]:find("kotak-output=OK", 1, true) and console[#console]:find("file=OK", 1, true))

-- ---- dump API bersih ----
growlauncher = { version = "9.9.9", getVersion = function() return "9.9.9" end }
local function wait_wall(sec) local t0 = os.time(); local c0 = os.clock(); while os.time() - t0 < sec or os.clock() - c0 < 0.3 do end end
wait_wall(1.1)   -- lewati jendela debounce tombol yang sama
OnValue("button", "dbg_btn_api", true)
local api = files["debug_api.txt"]
check("dump tidak memuat token internal __DBG_", not api:find("__DBG_", 1, true))
check("dump mencatat versi launcher", api:find("growlauncher.version=9.9.9", 1, true) and api:find("growlauncher.getVersion()=9.9.9", 1, true))
check("dump memuat tabel io/os", api:find("table io:", 1, true) and api:find("table os:", 1, true))
check("dump menandai ImGui.SetClipboardText sebagai kandidat clipboard", console[#console]:find("ImGui.SetClipboardText", 1, true))
ImGui, growlauncher = nil, nil

-- ---- muat ulang: instance lama jadi inert, tidak ada log ganda ----
local old_variant = hooks.onvariant
dofile(SCRIPT)
local new_variant = hooks.onvariant
wait_wall(1.1)
OnValue("button", "dbg_btn_clear", true)
old_variant({ v1 = "OnOld", v2 = "1" })
new_variant({ v1 = "OnNew", v2 = "1" })
hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
check("setelah reload, instance lama tidak mencatat (tanpa duplikat)", not boxes.dbg_out:find("OnOld", 1, true) and boxes.dbg_out:find("OnNew", 1, true))

-- ---- debounce: klik ganda diblok, klik sah setelah jeda tidak diblok ----
wait_wall(1.1)
local before = #console
OnValue("button", "dbg_btn_save", true)
OnValue("button", "dbg_btn_save", true)   -- double-fire seketika
local saves = 0
for i = before + 1, #console do if console[i]:find("Simpan:", 1, true) then saves = saves + 1 end end
check("double-fire tombol seketika hanya diproses 1x", saves == 1, saves)
wait_wall(1.1)
before = #console
OnValue("button", "dbg_btn_save", true)
check("klik sah setelah jeda (>1 detik) tetap diproses", console[#console] ~= nil and #console > before and console[#console]:find("Simpan:", 1, true))

-- ---- v1.2: gamepacket + value ----
do
    local before = #console
    hooks.ongamepacket({ type = 3, x = 10, y = 20 })          -- default OFF
    hooks.onvalue(1, "foo", true)
    handle = nil
    hooks.onsendpacket(2, "action|input\n|text|/dbg game")
    hooks.onsendpacket(2, "action|input\n|text|/dbg value")
    local r1 = hooks.ongamepacket({ type = 3, x = 10, y = 20 })
    local r2 = hooks.onvalue(1, "foo", true)
    hooks.onvalue(1, "dbg_v", true)                           -- harus diabaikan
    check("gamepacket/value mengembalikan false", r1 == false and r2 == false)
    hooks.onsendpacket(2, "action|input\n|text|/dbg copy")
    local out = tostring(boxes.dbg_out or "")
    check("GAMEPACKET masuk log", out:find("[GAMEPACKET]", 1, true) and out:find("type=3", 1, true))
    check("VALUE masuk log, dbg_ diabaikan", out:find("[VALUE] type=1 name=foo value=true", 1, true) and not out:find("name=dbg_v", 1, true))
    check("tidak masuk saat OFF", select(2, out:gsub("%[GAMEPACKET%]", "")) == 1)
end

print(string.format("\n%d lulus, %d gagal", pass, fail))
os.exit(fail == 0 and 0 or 1)

