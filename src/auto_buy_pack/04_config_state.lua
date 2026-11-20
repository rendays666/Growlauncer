-- [auto_buy_pack/04_config_state] CFG (disimpan) dan STATE (runtime)
-- Tujuan : Semua setelan pengguna + flag runtime (running, no_gems_flag, backpack_full_flag, dst)
-- Dependensi: 01_helpers_prefs_json.lua (loadPref)
-- Urutan load: 4 dari 12 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/auto_buy_pack_boren.lua baris 269-322 (salinan verbatim)

local CFG = {
    pack_name           = tostring(loadPref("pack_name", "world_lock") or "world_lock"),
    pack_item_ids_text  = tostring(loadPref("pack_item_ids_text", "242") or "242"),
    pack_price          = tonumber(loadPref("pack_price", 2000)) or 2000,
    target_packs        = tonumber(loadPref("target_packs", 0)) or 0,

    drop_world          = tostring(loadPref("drop_world", "") or ""),
    drop_door           = tostring(loadPref("drop_door", "") or ""),

    drop_anchor_x       = tonumber(loadPref("drop_anchor_x", 0)) or 0,
    drop_anchor_y       = tonumber(loadPref("drop_anchor_y", 0)) or 0,
    drop_threshold      = tonumber(loadPref("drop_threshold", 200)) or 200,
    max_stacks_per_tile = tonumber(loadPref("max_stacks_per_tile", 18)) or 18,

    use_gl_drop         = (loadPref("use_gl_drop", true) ~= false),
    anti_retake         = (loadPref("anti_retake", true) ~= false),
    auto_learn_items    = (loadPref("auto_learn_items", true) ~= false),
    shop_search         = tostring(loadPref("shop_search", "") or ""),

    delay_buy           = tonumber(loadPref("delay_buy", 1000)) or 1000,
    delay_drop          = tonumber(loadPref("delay_drop", 350)) or 350,
    delay_warp          = tonumber(loadPref("delay_warp", 4500)) or 4500,
}

local STATE = {
    running              = false,
    step                 = "SIAP",
    detail               = string.format("Database %d pack siap! Cari nama pack, isi World Save & START.", #PACK_CATALOG),
    packs_bought         = 0,
    items_dropped        = 0,
    full_drop_tiles      = {},
    backpack_full_flag   = false,
    no_gems_flag         = false,
    unknown_pack_flag    = false,
    pending_drop_id      = nil,
    pending_drop_amt     = nil,
    hooks_installed      = false,
    saved_ac_toggle      = nil,
    saved_anti_toggle    = nil,
    last_dialog_items    = {},
    dialog_page          = 1,
    anti_take_active     = false,
    last_store_msg       = "",
    buy_server_confirmed = false,
    in_coroutine         = false,
    ignore_power_event   = false,
    user_edited_price    = false,
    user_set_target      = false,
    last_seen_search_gl  = nil,
    buying_now           = false,
    suppress_store_until = 0,
    logged_store_block   = false,
}
