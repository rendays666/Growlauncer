-- [surg_helper_zayn/09_hooks] on_variant dan on_send
-- Tujuan : Hook OnVariant (tulis ulang dialog / cek hasil) dan OnSendPacket (hitung langkah + akurasi saran)
-- Dependensi: 08_rewrite.lua, 04_state_history.lua
-- Urutan load: 9 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 476-504 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local function on_variant(var)
    local ok, res = pcall(function()
        if var.v1 == "OnConsoleMessage" then check_result(var.v2) return false end
        if var.v1 ~= "OnDialogRequest" then return false end
        local new = rewrite(var.v2)
        if not new then check_result(var.v2) return false end
        if C.mode == "inplace" then var.v2 = new return false end
        sendVariant({v1 = "OnDialogRequest", v2 = new})
        return true
    end)
    if not ok then log("[" .. SC .. "] Error: " .. tostring(res)) return false end
    return res
end

local function on_send(ptype, pkt)
    pcall(function()
        if type(pkt) ~= "string" or not OP or not pkt:find("dialog_name|surgery", 1, true) then return end
        local b = pkt:match("buttonClicked|([^\n|]+)")
        if not b then return end
        OP.moves = OP.moves + 1
        local id, idx = tonumber(b:match("^tool(%d+)$")), 4
        for k, sid in ipairs(S.sug) do
            if sid == id then idx = k break end
        end
        OP.pick[idx] = OP.pick[idx] + 1
        if b == "cancel" then OP.gaveup = true end
    end)
    return false
end
