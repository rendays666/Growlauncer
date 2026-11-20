# growtopia_api — API loader dan packet yang terlihat di script

Hanya yang benar-benar muncul di script di repo ini. Loader berbeda memakai penulisan huruf berbeda untuk fungsi yang sama.

## Fungsi (variasi nama)
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
| Nama world | `getCurrentWorldName()` atau `getWorld()` (`.name`) | auto_buy_pack |
| Jumlah item | `growtopia.checkInventoryCount(id)` atau `getInventory()` (item: `id`/`itemID`, `amount`/`count`) | auto_buy_pack |
| Toggle/nilai UI | `editToggle(name, bool)`, `editValue(name, v)` | auto_clear, auto_buy_pack |
| Simpan data | `require("preferences")` / `Preferences:new(file)` | surg_helper_zayn, auto_buy_pack |
| Tulis file | `writeToLocal(file, text)` | surg_helper_zayn |
| UI GrowLauncher | `UserInterface.new`, `addIntoModule`, `addCategory`, callback `OnValue(vtype,name,value)` | auto_buy_pack |
| Gems / inventaris / objek | `getGems()`, `getInventory()`, `getObjectList()`/`getObjects()` | auto_buy_pack |
| Drop | `growtopia.confirmDropItem(id, amt)` | auto_buy_pack |

Argumen hook `OnVariant`: `var.v1` (nama variant, mis. `OnDialogRequest`, `OnConsoleMessage`), `var.v2` (isi teks). Return `true` = menelan event.

## Packet (format string yang dikirim)
| Aksi | Packet |
|------|--------|
| Klik tombol surgery | `SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|tool<ID>")` |
| Mulai/ulang operasi | sama, `buttonClicked|start` |
| Beli pack | `sendPacket(2, "action|buy\nitem|<kode_debug>\n")` |
| Masuk world | `sendPacket(3, "action|join_request\nname|<WORLD>[|<DOOR>]\ninvitedWorld|0\n")` |
| Drop item | `sendPacket(2, "action|drop\n|itemID|<id>\n")` |
| Jawab dialog drop | `sendPacket(2, "action|dialog_return\ndialog_name|<nama>\nitemID|<id>|\ncount|<n>\n")` |

## Packet mentah (`sendPacketRaw(false, {...})`)
| Aksi | Tabel |
|------|-------|
| Pukul tile | `{type=3, value=18, x=posX, y=posY, px=tileX, py=tileY}` |
| Hadap arah | `{type=0, state=48 (kiri) / 32 (kanan), x=tileX*32, y=tileY*32}` |
| Packet collect (diblok di `onSendPacketRaw`) | `type == 11` |

## ID tool surgery
Ada di `notes/auto_surg.md`. Antiseptic 1264 hanya dipakai `surg_helper_zayn`.
