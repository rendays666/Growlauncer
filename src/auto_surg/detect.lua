-- [auto_surg/detect] surg(var): baca dialog bedah, tentukan tool menurut prioritas
-- Tujuan : hook handler. Cocokkan pola di var.v2, set `tool`, panggil auto()
-- Dipanggil: AddHook(surg, "OnVariant") di main.lua
-- Dependensi: tools.lua (auto), config.lua (failCount), API loader: SendPacket, LogToConsole
-- Urutan load: 3
-- Sumber : raw/sorted/auto_surg_v1.1_fixed.lua baris 79-243 (salinan verbatim)
-- Aturan: pertama yang cocok menang. Tabel lengkap ada di notes/auto_surg.md
-- CATATAN: lihat notes/bugs.md #2 dan #3

function surg(var)
   local v2 = var.v2 or ""
   currentState = v2

   if not var.v1:find("OnDialogRequest") then
      return false
   end

   -- ULTIMATE FAIL DETECTION - catch any failure message
   if v2:find("died") or v2:find("failed") or v2:find("escaped") or
      v2:find("The patient") or v2:find("`4The patient") then
      if not v2:find("tool") and not v2:find("Pulse") and not v2:find("Temp") and
         not v2:find("Status") and not v2:find("Incisions") and not v2:find("Bones") then
         failCount = failCount + 1
         LogToConsole("`4[FAILED] Surgery #"..failCount.." failed. Restarting...")
         SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|start")
         return true
      end
   end

   -- 1. HEART STOPPED - Absolute priority
   -- FIX: only fire if the Defibrillator button (tool4312) is actually present
   if (v2:find("Heart stopped") or v2:find("heart stopped")) and v2:find("tool4312") then
      tool = "Defibrillator"
      auto()
      return true
   end

   -- 2. ANESTHESIA ISSUES - Patient must stay sedated
   -- FIX: only fire if the Anesthetic button (tool1262) is actually present
   if v2:find("tool1262") and
      (v2:find("wakes up") or v2:find("screams") or v2:find("flails") or
       v2:find("Awake") or v2:find("Coming to")) then
      tool = "Anesthetic"
      auto()
      return true
   end

   -- 3. BLEEDING - All bleeding states
   -- FIX: collapsed the three identical branches into one
   if v2:find("losing blood") then
      if v2:find("tool4314") then
         tool = "Clamp"
      elseif v2:find("tool1270") then
         tool = "Stitches"
      end
      auto()
      return true
   end

   -- 4. PULSE - Both critical and warning
   if v2:find("Pulse:") then
      if v2:find("tool4310") then
         tool = "Transfusion"
         auto()
         return true
      end
   end

   -- 5. TEMPERATURE - All states
   if v2:find("Temp:") then
      if v2:find("tool1266") then
         tool = "Antibiotic"
         auto()
         return true
      elseif v2:find("tool4318") then
         tool = "Lab kit"
         auto()
         return true
      end
   end

   -- 6. BONES - Shattered or broken
   if v2:find("shattered") then
      if v2:find("tool4308") then
         tool = "Pins"
         auto()
         return true
      elseif v2:find("tool1260") then
         tool = "Scalpel"
         auto()
         return true
      end
   end

   if v2:find("broken") then
      if v2:find("tool1268") then
         tool = "Splint"
         auto()
         return true
      end
   end

   -- 7. PATIENT INJURIES
   if v2:find("broke his") then
      if v2:find("tool1270") then
         tool = "Stitches"
         auto()
         return true
      end
   end

   -- 8. INCISIONS
   if v2:find("Incisions:") then
      if v2:find("tool1296") then
         tool = "Fix it"
         auto()
         return true
      end
   end

   -- 9. VISIBILITY
   if v2:find("can't see") or v2:find("cannot see") then
      if v2:find("tool1258") then
         tool = "Sponge"
         auto()
         return true
      end
   end

   -- 10. DIAGNOSIS
   if v2:find("not been diagnosed") then
      if v2:find("tool4316") then
         tool = "Ultrasound"
         auto()
         return true
      end
   end

   -- 11. SCALPEL READY - Incision made, need to cut
   if v2:find("tool1260") and v2:find("Incisions:") then
      tool = "Scalpel"
      auto()
      return true
   end

   -- 12. FALLBACK: Fix it before stitches
   if v2:find("tool1296") and v2:find("tool1270") then
      tool = "Fix it"
      auto()
      return true
   end

   -- 13. DEFAULT: Start incision if scalpel available
   if v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   end

   -- 14. ABSOLUTE LAST RESORT: Try to continue surgery
   if v2:find("tool4316") then
      tool = "Ultrasound"
      auto()
      return true
   end

   if v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   end

   return false
end
