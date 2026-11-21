# growtopia_api — API GrowLauncher dan packet

Sumber kebenaran: dump API dari launcher asli, `notes/launcher_api_dump_2026-11-21.txt` (diambil lewat Debug Logger `/dbg api`, disimpan apa adanya). **Lua 5.4.**
Dump hanya memuat global yang bertipe function/table/userdata dan melewati library standar (`string`, `table`, `math`, `os`, `io`, dst), jadi ketersediaan `io.open` dan `os.*` belum diketahui. Versi launcher belum dicatat (`growlauncher.getVersion()` ada, tinggal dipanggil di dump berikutnya).

## Fakta dari dump

### Ejaan ganda
Hampir semua fungsi ada dalam dua ejaan (PascalCase dan camelCase) dan keduanya bekerja. Beda huruf di antara script TIDAK berarti loader berbeda.
- **Berpasangan (26):** AddHook/addHook, ApplyHook/applyHook, EditToggle/editToggle, FindItemID/findItemID, FindPath/findPath, GetGems/getGems, GetInventory/getInventory, GetItemInfoByID/getItemInfoByID, GetItemInfoByName/getItemInfoByName, GetLocal/getLocal, GetNPCList/getNPCList, GetObjectList/getObjectList, GetPath/getPath, GetPing/getPing, GetPlayerList/getPlayerList, GetTile/getTile, GetTiles/getTiles, LogToConsole/logToConsole, RemoveHook/removeHook, SearchItems/searchItems, SendPacket/sendPacket, SendPacketRaw/sendPacketRaw, SendVariant/sendVariant, SetLogin/setLogin, SetLoginEnabled/setLoginEnabled, Sleep/sleep.
- **Hanya PascalCase:** AddHookCallback, CallHookCallback, RemoveHookCallback, CSleep, GetWorldName, NewDrawList, SetPathFlag, ImVec2, ImVec4.
- **Hanya camelCase (selain fungsi standar Lua):** addCategory, addIntoModule, addShortcut, removeShortcut, await, bindValue, getValue, setValue, editValue, createPlayer, dumpTable, executeFromAssets, fetch, getAppLibrary, getCurrentWorldName, getDiscordID, getItemInfoManager, getPlayerByNetID, getTime, getWorldTileMap, isInside, load, localPlayer, log, logDebug, warn, randomCSleep, randomSleep, requireModule, runCoroutine, runThread, waitUntil, sendDialog, sendNotification, setBg, setFg, setMinimum, split, writeToLocal.
- Ejaan nama event hook juga longgar: `"OnVariant"`, `"onVariant"`, `"onvariant"` semuanya dipakai oleh script yang berjalan. Kemungkinan tidak peka huruf besar-kecil (belum diuji langsung).

### Tabel dan objek
| Nama | Isi |
|------|-----|
| `growtopia` | checkInventory, checkInventoryCount, confirmDropItem, dropItem, enter, enterGateway, enterPos, getItemID, getItemName, isOnPos, notify, notifyCenter, sendChat, sendDialog, setWeather, tileChange, warpTo |
| `growlauncher` | getVersion(), getVersionInt(), version |
| `tile` | getTile, setBg, setFg |
| `itemInfoManager` | getItemInfoByID, getItemInfoByName |
| `UserInterface` | addButton, addChildButton, addChildInputInt, addChildInputString, addChildItemPicker, addChildSlider, addChildToggle, addChildTooltip, addDialog, addDisplayList, addDivider, addExpandableToggle, addInputInt, addInputString, addItemPicker, addLabel, addLabelApp, addSlider, addTileSelect, addToggle, addToggleButton, addTooltip, generateJSON, new, printJSON, tableToJSON |
| `UIManager` | addSubCategory, generateJSON, new, printJSON |
| `Callback` | hooks |
| `ImGui` | Dear ImGui lengkap (Begin/End, Button, Text, InputText, InputTextMultiline, Checkbox, Combo, tabel, popup, dst). Daftar penuh di file dump |

### Yang tidak ada
`getWorld()`, `getObjects()`, `EditValue`, dan fungsi baca file bernama jelas (mis. `readFromLocal`) TIDAK ada di global. Script Boren hanya memakainya sebagai cadangan. `Preferences` bukan global; dimuat lewat `require("preferences")`.

### Clipboard (penting)
`ImGui.SetClipboardText(text)` dan `ImGui.GetClipboardText()` ada. Ini jalur Copy All yang benar. Belum dites dipanggil dari callback UI (`OnValue`), di luar loop gambar ImGui.
Ada juga `ImGui.InputTextMultiline` dan `ImGui.LogToClipboard` untuk jendela ImGui sendiri, dan hook `__OnDrawLoop__` (loop gambar internal).

### Fungsi lain yang berguna
`fetch` (permintaan HTTP), `await`, `runThread`, `runCoroutine`, `waitUntil`, `executeFromAssets`, `requireModule`, `dumpTable`, `split`, `getTime`, `sendNotification`, `addShortcut`, `bindValue/getValue/setValue`, `getPlayerList`, `getNPCList`, `getObjectList`, `getWorldTileMap`, `localPlayer`, `GetPing`, `SearchItems`.

### Artefak di dump (bukan bawaan launcher)
`OnValue` dan `__DBG_TOKEN` berasal dari Debug Logger yang dijalankan saat dump (script itu mendefinisikan `OnValue` dan menyimpan token reload). Jangan dianggap API bawaan.

## Pemakaian di script repo
| Fungsi | Penulisan yang terlihat | Dipakai di |
|--------|-------------------------|-----------|
| Kirim packet | `SendPacket(type, str)` | auto_surg, surg_exact (DFNL5) |
| | `sendPacket(type, str)` | surg_exact (Ceximo), auto_buy_pack |
| Kirim packet mentah | `sendPacketRaw(false, {table})` | auto_clear, auto_buy_pack |
| Log | `LogToConsole(str)` | auto_surg, surg_exact (DFNL5), auto_clear, auto_buy_pack (utama) |
| | `log(str)` | surg_exact (Ceximo), surg_helper_zayn, auto_buy_pack (cadangan) |
| Notifikasi | `growtopia.notify(str)` | auto_surg, auto_buy_pack |
| Dialog | `sendDialog({title,message,confirm,alias})` | auto_surg |
| | `growtopia.sendDialog(str)` | surg_helper_zayn |
| Kirim variant | `sendVariant({v1=..., v2=...})` | surg_helper_zayn |
| Hook | `AddHook(fn, "OnVariant")` | auto_surg, surg_exact (DFNL5, Ceximo) |
| | `addHook(fn, "onVariant")` + `applyHook()` | surg_helper_zayn |
| | `addHook(fn, "onvariant"/"onsendpacket"/"onsendpacketraw")` + `applyHook()` | auto_buy_pack |
| Tidur | `Sleep(ms)` | surg_exact (Ceximo) |
| | `randomSleep(min,max)` | auto_clear |
| | `CSleep`/`sleep` + `runCoroutine` | auto_buy_pack |
| Pemain | `getLocal()` (`posX`, `posY`) | auto_clear |
| Tile | `getTile(x,y)` (`fg`, `bg`, `collidable`), `getTiles()` | auto_clear, auto_buy_pack |
| Gerak | `FindPath(x,y)` (argumen ke-3 `true` dipakai sebagai cek) | auto_clear, auto_buy_pack |
| Item (nama ke ID) | `findItemID(name)` | auto_clear |
| Item (ID ke nama) | `getItemInfoByID(id)` (`.name`) atau `growtopia.getItemName(id)` | auto_buy_pack |
| Nama world | `getCurrentWorldName()` (ada di launcher); `getWorld()` hanya cadangan di script dan tidak ada di launcher | auto_buy_pack |
| Jumlah item | `growtopia.checkInventoryCount(id)` atau `getInventory()` (item: `id`/`itemID`, `amount`/`count`) | auto_buy_pack |
| Toggle/nilai UI | `editToggle(name, bool)`, `editValue(name, v)` | auto_clear, auto_buy_pack |
| Simpan data | `require("preferences")` | surg_helper_zayn, auto_buy_pack |
| Tulis file | `writeToLocal(file, text)` (folder tujuan belum diketahui) | surg_helper_zayn |
| UI GrowLauncher | `UserInterface.new`, `addIntoModule`, `addCategory`, callback `OnValue(vtype,name,value)` | auto_buy_pack |
| Gems / inventaris / objek | `getGems()`, `getInventory()`, `getObjectList()` | auto_buy_pack |
| Drop | `growtopia.confirmDropItem(id, amt)` | auto_buy_pack |

Argumen hook `OnVariant`: `var.v1` (nama variant, mis. `OnDialogRequest`, `OnConsoleMessage`), `var.v2` (isi teks), `var.v3` (dipakai Boren). Return `true` dipakai script (Boren, Zayn) untuk menelan event; efek pastinya belum diuji langsung. Hook kirim: `OnSendPacket(ptype, str)` dan `OnSendPacketRaw(pkt)`, juga dipakai Boren dengan return `true` untuk memblok.

## Packet (format string yang dikirim)
| Aksi | Packet |
|------|--------|
| Klik tombol surgery | `SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|tool<ID>")` |
| Mulai/ulang operasi | sama, `buttonClicked|start` |
| Beli pack | `sendPacket(2, "action|buy\nitem|<kode_debug>\n")` |
| Masuk world | `sendPacket(3, "action|join_request\nname|<WORLD>[|<DOOR>]\ninvitedWorld|0\n")` |
| Drop item | `sendPacket(2, "action|drop\n|itemID|<id>\n")` |
| Jawab dialog drop | `sendPacket(2, "action|dialog_return\ndialog_name|<nama>\nitemID|<id>|\ncount|<n>\n")` |
| Wrench pemain (terlihat di debug launcher) | `action|wrench\n|netid|<id>` |
| Chat (ASUMSI, belum terbukti di launcher ini; dipakai perintah `/dbg` di Debug Logger) | `action|input\n|text|<pesan>` |

## Packet mentah (`sendPacketRaw(false, {...})`)
| Aksi | Tabel |
|------|-------|
| Pukul tile | `{type=3, value=18, x=posX, y=posY, px=tileX, py=tileY}` |
| Hadap arah | `{type=0, state=48 (kiri) / 32 (kanan), x=tileX*32, y=tileY*32}` |
| Packet collect (diblok di `onSendPacketRaw`) | `type == 11` |

## Format debug bawaan launcher
Variant: `[<nama>] param 0: <nama>` lalu `param 1: ...`, dst. Paket kirim ditampilkan mentah. Debug Logger memakai format yang sama supaya hasilnya bisa dibandingkan.

## ID tool surgery
Ada di `notes/auto_surg.md`. Antiseptic 1264 hanya dipakai `surg_helper_zayn`.
