# auto_clear

**Tujuan:** Membersihkan seluruh world: berjalan ke tiap tile lalu memukul sampai fg/bg hilang, kecuali item yang dilindungi.
**Sumber:** `raw/sorted/auto_clear_kurangtahu.lua` (Simple Auto Clear World, by @_kurangtahu_, 60 baris)
**File:** `src/auto_clear/auto_clear.lua` (satu file, satu tanggung jawab)

## Mekanisme
1. `JANGAN_BREAK` (daftar nama) diubah jadi `SKIP_BREAK[itemID]` lewat `findItemID`. Isi bawaan: My First World Lock, World Lock, Bedrock, Blank, Main Door.
2. `startClear()` mengulang `getTiles()`. Untuk tiap tile: pecahkan fg kalau tidak di SKIP_BREAK; lalu pecahkan bg kalau tidak di SKIP_BREAK dan fg sudah kosong.
3. `breakTile(x,y,id)`: loop 1 mendekat sampai jarak <= 2 tile (`FindPath(x, y-1)`), loop 2 memanggil `punchTile` sampai tile tidak lagi berisi `id`.
4. `punchTile`: `sendPacketRaw(false, {type=3, value=18, x=posX, y=posY, px=x, py=y})` (pukul). Jeda acak lewat `randomSleep`.
5. Saat start: log, `editToggle("ModFly", true)`, `startClear()`.

## API yang dipakai
`getLocal`, `getTile`, `getTiles`, `findItemID`, `sendPacketRaw`, `FindPath`, `randomSleep`, `editToggle`, `LogToConsole`. Lihat `notes/growtopia_api.md`.

## Gotcha (dari membaca kode, belum dites)
- **Tidak ada batas percobaan.** Loop memukul di `breakTile` baru berhenti kalau tile sudah kosong. Tile yang tidak bisa dipecahkan (misalnya terkunci milik orang lain) membuat script memukul selamanya.
- Tile kosong aman karena `Blank` ada di daftar lindung dan diharapkan dipetakan ke ID 0. Kalau `findItemID("Blank")` tidak mengembalikan 0, tile kosong akan dipukul tanpa henti.
- Cabang `if FindPath(x, y - 1) then return end` meninggalkan tile kalau `FindPath` mengembalikan nilai benar. Arti nilai kembalian `FindPath` belum diverifikasi, jadi bisa jadi arti sebenarnya terbalik.
