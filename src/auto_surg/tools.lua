-- [auto_surg/tools] auto(): pilih ID tool, anti-stuck, kirim packet
-- Tujuan : ubah nama tool (global `tool`) jadi ID, deteksi macet, kirim klik tombol
-- Dipanggil: detect.lua (surg) setelah mengisi `tool`
-- Dependensi: config.lua (state), API loader: SendPacket, LogToConsole
-- Urutan load: 2
-- Sumber : raw/sorted/auto_surg_v1.1_fixed.lua baris 20-77 (salinan verbatim)
-- CATATAN: lihat notes/bugs.md #1 (itool dihitung sebelum anti-stuck)

function auto()
   if tool == "Sponge" then
      itool = 1258
   elseif tool == "Splint" then
      itool = 1268
   elseif tool == "Antibiotic" then
      itool = 1266
   elseif tool == "Anesthetic" then
      itool = 1262
   elseif tool == "Scalpel" then
      itool = 1260
   elseif tool == "Stitches" then
      itool = 1270
   elseif tool == "Lab kit" then
      itool = 4318
   elseif tool == "Pins" then
      itool = 4308
   elseif tool == "Clamp" then
      itool = 4314
   elseif tool == "Transfusion" then
      itool = 4310
   elseif tool == "Ultrasound" then
      itool = 4316
   elseif tool == "Defibrillator" then
      itool = 4312
   elseif tool == "Fix it" then
      itool = 1296
   end

   -- FIX: anti-stuck now based on whether the game state (v2) itself
   -- stopped changing, not just "same tool used twice in a row".
   -- This stops false positives when a tool is legitimately reused
   -- (e.g. Scalpel for several incisions).
   if lastState == currentState and tool == lastTool then
      stuckCount = stuckCount + 1
   else
      stuckCount = 0
   end
   lastTool = tool
   lastState = currentState

   if stuckCount >= 5 then
      LogToConsole("`4[ANTI-STUCK] Stuck on "..tool..", trying alternatives...")
      stuckCount = 0
      if tool == "Scalpel" then
         tool = "Ultrasound"
      elseif tool == "Ultrasound" then
         tool = "Antibiotic"
      elseif tool == "Antibiotic" then
         tool = "Lab kit"
      else
         tool = "Scalpel"
      end
   end

   SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|tool"..itool)
   LogToConsole("`9[`c"..tool.."`9] `cUsed")
end
