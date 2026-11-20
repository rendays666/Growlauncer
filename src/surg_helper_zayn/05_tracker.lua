-- [surg_helper_zayn/05_tracker] track(): hitung sisa bius dan langkah jantung
-- Tujuan : Bandingkan jumlah tool antar dialog untuk tahu langkah terpakai; isi S.sleep_left dan S.heart_moves
-- Dependensi: 04_state_history.lua (S, reset_session)
-- Urutan load: 5 dari 10 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_helper_zayn_v2.0.lua baris 237-259 (salinan verbatim)
-- Catatan: akhiran baris asli CRLF, di sini dinormalisasi ke LF

local function track(s, counts)
    local now = getTime()
    if S.t > 0 and now - S.t > GAP then reset_session() end
    S.t = now
    local moved = false
    if S.counts then
        for id, n in pairs(S.counts) do
            if (counts[id] or 0) < n then moved = true end
        end
    end
    if moved and S.sleep_left then S.sleep_left = math.max(0, S.sleep_left - 1) end
    if s.deep_sleep and (moved or not S.counts) then
        S.sleep_left = s.hyper and SLEEP_MOVES.hyper or SLEEP_MOVES.normal
    end
    if not s.asleep then S.sleep_left = nil end
    if s.heart then
        if S.heart_moves == nil then S.heart_moves = 0
        elseif moved then S.heart_moves = S.heart_moves + 1 end
    else
        S.heart_moves = nil
    end
    S.counts = counts
end
