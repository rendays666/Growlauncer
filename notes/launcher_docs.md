# launcher_docs — dokumentasi resmi GrowLauncher (ringkasan)

Sumber: https://inieyyy.github.io/Growlauncher-Documentation/ (diambil 2026-11-22; dokumentasi menyebut **GrowLauncher 7.0.38**).
Dump API asli (`launcher_api_dump_2026-11-21.txt`) lebih baru/berbeda dan menang kalau bertentangan. Ringkasan praktis ada di `growtopia_api.md`; file ini menyimpan detail dokumentasi.

## Hook
Daftarkan dengan `addHook(func, name)` lalu `applyHook()`. Lepas dengan `removeHook(name)`. Dokumentasi: dispatcher native membandingkan nama sebagai **huruf kecil**, jadi daftarkan dan lepas dengan huruf kecil. (Script lama memakai `"OnVariant"` dan tetap jalan, jadi huruf besar kemungkinan ikut dinormalkan; tetap pakai huruf kecil.) Parameter ke-3 `noret` ditandai deprecated.

| Nama terdaftar | Callback | Parameter |
|----------------|----------|-----------|
| `onvariant` | `(var, pkt)` | `var`: VariantList (`var.v1..vN`, v1 = nama), `pkt`: TankPacket |
| `ongamepacket` | `(pkt)` | TankPacket dari server |
| `onsendpacketraw` | `(pkt)` | TankPacket yang akan dikirim |
| `onsendpacket` | `(type, pkt)` | `type`: number, `pkt`: string |
| `onvalue` | `(type, name, value)` | `value`: string/number/boolean/table |
| `ondrawimgui` | `(deltaTime)` | tiap frame, untuk ImGui |
| `ondraw` | `(deltaTime)` | tiap frame |
| `ondialog` | `(title, alias, isAccepted)` | respons dialog GL |
| `onsendpacketrawtype` | tidak didokumentasikan | ada di daftar nama, tanpa penjelasan |

- Semantik nilai return hook TIDAK didokumentasikan. Script (Boren, Zayn, Debug Logger) memakai `return true` untuk menelan event; efek pastinya belum terbukti.
- `AddHookCallback(func, name)`, `CallHookCallback(name, ...)`, `RemoveHookCallback(name)` ada, tetapi contoh di dokumentasi bertentangan dengan tanda tangannya (nama di depan, 3 argumen). Jangan diandalkan sebelum diuji.
- Contoh resmi: `addHook(onDraw, "ondraw"); applyHook()`.

## Alias (satu fungsi native, beberapa nama; huruf besar-kecil dibedakan)
`AddHook/addHook`, `EditToggle/editToggle/editValue`, `FindItemID/findItemID`, `FindPath/findPath`, `GetGems/getGems`, `GetInventory/getInventory`, `GetItemInfoByID/getItemInfoByID`, `GetItemInfoByName/getItemInfoByName`, `GetLocal/getLocal/localPlayer`, `GetNPCList/getNPCList`, `GetObjectList/getObjectList`, `GetPing/getPing`, `GetPlayerList/getPlayerList`, `GetTile/getTile`, `GetTiles/getTiles`, `getCurrentWorldName/GetWorldName`, `LogToConsole/logToConsole`, `RemoveHook/removeHook`, `SendPacket/sendPacket`, `SendPacketRaw/sendPacketRaw`, `SendVariant/sendVariant`, `SetLogin/setLogin`, `SetLoginEnabled/setLoginEnabled`, `createPlayer/SetPathFlag` (tidak berhubungan, implementasi sama), `Sleep/sleep`.
Penting: `editValue` dan `editToggle` adalah fungsi yang sama; `editValue("alias", true/false)` membalik toggle mana pun dengan alias itu.

## Fungsi nilai (value)
| Fungsi | Keterangan |
|--------|------------|
| `getValue(type, name)` | type 0=boolean, 1=number, 2=string |
| `setValue(name, value)` | set nilai TANPA memperbarui UI |
| `editValue(name, value)` | tulis ke value store DAN perbarui item UI beralias sama. Angka disimpan sebagai int32 bertanda, boolean sebagai string `true`/`false` |
| `editToggle(name, bool)` | sama dengan `editValue` |
| `bindValue(type, alias, default)` | tidak terdaftar di 7.0.38 menurut dokumentasi, tetapi ADA di dump API (launcher lebih baru) |
| `setOnValue(name, func)` | tidak terdaftar di 7.0.38, tidak ada di dump |
| `setMinimum("6.0.0")` | versi minimum |
| `addIntoModule(json, category)` | tambah modul JSON |

## Fungsi modul
`sendDialog({title, message,...})`, `addCategory(name, icon)`, `addShortcut(name)`, `removeShortcut(name)`, `requireModule(name)`, `addIntoModule(json, category)`, `sendNotification(text)`.
- Ikon = nama Material Icons Rounded (`Verified`, `SportsEsports`, `Settings`, `Info`); nama tak dikenal jadi ikon peringatan.
- Item JSON: `text` (label), `alias` (kunci nilai), `type` (mis. `toggle`), `icon`, `default`, `description`, `autosave`.

## Namespace `growtopia` (16 fungsi)
`enter()`, `warpTo(world)`, `notify(msg)`, `isOnPos(x,y)`→bool, `sendChat(text, toClient?)`, `enterPos()`, `dropItem(id)` (1 buah), `getItemID(name)`, `tileChange(x,y,value)`, `sendDialog(string)`, `setWeather(id)`, `getItemName(id)`, `enterGateway(x,y,n)` (contoh: x,y = posisi/32, n=0), `checkInventory(id)`→bool, `confirmDropItem(id, amount)`, `checkInventoryCount(id)`→number.
`sendChat(text, toClient?)` adalah jalur chat resmi; lebih aman daripada menebak format packet `action|input`.

## Enum tipe TankPacket (`pkt.type`; BUKAN argumen pertama `SendPacket`)
0 STATE, 1 CALL_FUNCTION, 2 UPDATE_STATUS, 3 TILE_CHANGE_REQUEST, 4 SEND_MAP_DATA, 5 SEND_TILE_UPDATE_DATA, 6 SEND_TILE_UPDATE_DATA_MULTIPLE, 7 TILE_ACTIVATE_REQUEST, 8 TILE_APPLY_DAMAGE, 9 SEND_INVENTORY_STATE, 10 ITEM_ACTIVATE_REQUEST, 11 ITEM_ACTIVATE_OBJECT_REQUEST (collect; diblok Boren), 12 SEND_TILE_TREE_STATE, 13 MODIFY_ITEM_INVENTORY, 14 ITEM_CHANGE_OBJECT, 15 SEND_LOCK, 16 SEND_ITEM_DATABASE_DATA, 17 SEND_PARTICLE_EFFECT, 18 SET_ICON_STATE, 19 ITEM_EFFECT, 20 SET_CHARACTER_STATE, 21 PING_REPLY, 22 PING_REQUEST, 23 GOT_PUNCHED, 24 APP_CHECK_RESPONSE, 25 APP_INTEGRITY_FAIL, 26 DISCONNECT, 27 BATTLE_JOIN, 28 BATTLE_EVEN, 29 USE_DOOR, 30 SEND_PARENTAL, 31 GONE_FISHIN, 32 STEAM, 33 PET_BATTLE, 34 NPC, 35 SPECIAL, 36 SEND_PARTICLE_EFFECT_V2, 37 GAME_ACTIVE_ARROW_TO_ITEM, 38 GAME_SELECT_TILE_INDEX.
Pukul tile di `auto_clear` = type 3 (TILE_CHANGE_REQUEST) dengan `value=18` (Fist).
`SendPacket(2, ...)`/`SendPacket(3, ...)` memakai tipe pesan jaringan (2 = pesan teks game, 3 = teks generik), ruang angka yang berbeda dari enum di atas.

## Struct yang disebut (dari teks dokumentasi yang dikirim user)
`Tile`, `TileExtra`, `Player`, `InventoryItem`, `Object`, `ClientNPC`, `Variant`, `vec2`, `vec3`, `packet` (untuk `SendPacketRaw`). Fungsi lain di teks itu: `LogToConsole`, `SendPacket`, `SendPacketRaw`, `Sleep`, `FindPath`, `GetTiles`, `GetLocal`, `EditMemory`, `System`, `FindItemID`, `LoadEnc`, `GetInventory`, `GetObjectList`, `GetPlayerList`, `SendVariant`. Detail field belum disalin ke repo (kirim lagi kalau perlu). `EditMemory`, `System`, `LoadEnc` tidak ada di dump API 2026-11-21.

## Belum terdokumentasi / belum diketahui
- Folder tujuan `writeToLocal`, dan lokasi data `Preferences` (halaman namespace Preferences tidak bisa diambil).
- Halaman UserInterface dan struct Variants belum dibaca.
- Efek `return true` pada hook.
