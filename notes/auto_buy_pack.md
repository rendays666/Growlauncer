# auto_buy_pack

**Tujuan:** Beli pack di Store (Gems) berulang lewat packet tanpa membuka shop, lalu drop hasilnya ke world penyimpanan dengan cara anti-retake (item tidak terambil lagi).
**Sumber:** `raw/sorted/auto_buy_pack_boren.lua` (Auto Buy By Boren, GrowLauncher Android/PC, 1906 baris)
**File:** `src/auto_buy_pack/01..12` (segmen, gabungkan berurutan = script asli). Segmen `02_pack_data` adalah data 116 pack, jangan dibaca kecuali perlu.
**Bahasa UI:** Indonesia

## Peta segmen
| Segmen | Isi |
|--------|-----|
| 01 | Preferences (`boren_buy_pack.json`), encoder JSON untuk daftar UI |
| 02 | DATA: `nama:kode_debug:harga:id1,id2,...` per baris (116 pack) |
| 03 | `loadPacksIntoCatalog`; ikut memuat `debugpack.txt` / `ScriptLua/debugpack.txt` kalau ada (kode sama = entri baru menimpa) |
| 04 | `CFG` (disimpan ke prefs) dan `STATE` (runtime) |
| 05 | notify, log, `safeSleep`, coroutine, `setStatus`, `updateStatusList` |
| 06 | parser world/ID, snapshot inventaris, baca input GL, `learnNewPackItems` |
| 07 | pencarian pack: `scorePackMatch` (skor 1000 persis, 800 awalan, 600 awal kata, 450 substring, 350 multi-kata, 200 ID angka) |
| 08 | `applyDropCollectGuard`, `warpToWorld` |
| 09 | hook: konfirmasi beli, dialog drop, blok collect |
| 10 | mesin drop anti-retake |
| 11 | `runBuyPackLoop`, `startBuyPack`, `stopBuyPack` |
| 12 | `buildUI` (2 tab) dan `OnValue` (semua kontrol `bp_*`) |

## Alur utama (`runBuyPackLoop`, segmen 11)
1. Sinkron input dari UI, pasang hook, cocokkan nama pack ke katalog (mengisi kode debug, harga, ID item otomatis).
2. Wajib ada World Save. Warp ke sana, aktifkan guard collect, drop dulu kalau stok sudah melewati ambang.
3. Loop tiap iterasi, urutan cek: online? → di world yang benar? → target tercapai? → gems < harga? → server lapor gems habis / pack ditolak? → perlu drop? → **beli**.
4. Beli: `sendPacket(2, "action|buy\nitem|<kode_debug>\n")`. Verifikasi sampai ~1.3 detik: gems berkurang, atau inventaris bertambah, atau pesan server "bought/purchased". 4 kali gagal beruntun = berhenti.
5. Setelah selesai: drop sisa, matikan guard, notifikasi ringkasan.

## Hook (segmen 09)
- `OnStoreRequest`: ditelan selama bot jalan (shop tidak tampil).
- `OnStorePurchaseResult` / `OnConsoleMessage` / `OnTextOverlay`: set flag `no_gems_flag`, `backpack_full_flag`, `unknown_pack_flag`, `buy_server_confirmed` dari teks server (`not enough gems`, `backpack is full`, `unknown item`, `purchased`, dst).
- `OnDialogRequest`: kalau ada drop tertunda, jawab dialog drop otomatis; selain itu, saat bot jalan, dialog berisi store/purchase/confirm/buy dijawab otomatis dengan mengklik tombol pertamanya (bukan `cancel`/`back`).
- `onSendPacketRaw`: saat `anti_take_active`, blok packet `type == 11` (collect).
- `onSendPacket`: menangani dialog picker `boren_shop_browser` (cari, halaman, pilih).

## Mesin drop (segmen 10)
- `findAntiRetakeDropSlot`: cari tile kosong dekat titik awal (`drop_anchor_x/y`, default posisi pemain), cek tile bisa dilewati, belum penuh, dan (mode ketat) tidak ada objek di lantai.
- Tile dianggap penuh kalau >= `max_stacks_per_tile` tumpukan atau total jumlah >= 3600.
- `moveToDropStand` jalan ke tile berdiri, hadapkan ke arah drop (`sendPacketRaw type=0 state 48/32`).
- `dropSingleItemAntiRetake`: maksimal 200 per drop, `growtopia.confirmDropItem` kalau `use_gl_drop`, cadangan `action|drop`; maksimal 8 percobaan per item.

## Setelan (`CFG`, disimpan)
`pack_name`, `pack_item_ids_text`, `pack_price`, `target_packs` (0 = sampai gems habis), `drop_world`, `drop_door`, `drop_anchor_x/y`, `drop_threshold` (maks 200), `max_stacks_per_tile` (5-19), `use_gl_drop`, `anti_retake`, `auto_learn_items`, `delay_buy` (>=500), `delay_drop` (>=200), `delay_warp` (>=2500).
`auto_learn_items`: item baru yang muncul di inventaris setelah beli otomatis ditambahkan ke daftar ID pack.

## Packet dan API
Lihat `notes/growtopia_api.md` (buy, join_request, drop, dialog_return drop, type 11).

## Gotcha
- Saat bot jalan, penelan dialog bersifat global: dialog apa pun yang berisi kata `store`/`purchase`/`confirm`/`buy` akan dijawab otomatis, termasuk yang tidak berhubungan dengan bot.
- `Auto Collect` dan `Anti Collect` diubah lewat `editToggle` dan dikembalikan ke nilai awal setelah selesai atau dihentikan.
- `warpToWorld(..., forceRewarp = true)` selalu mengirim join ulang saat mulai, walau sudah berada di world tujuan.
- Snapshot inventaris mengabaikan item ID 112 (otomatis, bukan bagian pack).
- Hook terpasang dua jalur (di akhir file dan lewat `ensureHooks`), tapi `STATE.hooks_installed = true` mencegah pemasangan ganda.
