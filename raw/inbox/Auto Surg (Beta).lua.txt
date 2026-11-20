--Auto Surg V1.0

tool = "0"
itool = 1
failCount = 0
lastTool = ""
stuckCount = 0

sendDialog({
    title = "Script By Moeyii",
    message = "Auto Surg\nWarning:\n\n• consumption tea & skill spice before starting.\n• Maximum anti-fail protection.\n• Auto-restart on failure.",
    confirm = "OKE",
    alias = "OKE"
})

LogToConsole("`0[`9Auto Surg`0]`2 MAX Active")
growtopia.notify("`2AUTO SURG MAX ACTIVE")

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
   
   -- Detect if we're stuck on same tool
   if tool == lastTool then
      stuckCount = stuckCount + 1
   else
      stuckCount = 0
      lastTool = tool
   end
   
   -- Anti-stuck protection: if same tool used 5 times, try something else
   if stuckCount >= 5 then
      LogToConsole("`4[ANTI-STUCK] Stuck on "..tool..", trying alternatives...")
      stuckCount = 0
      -- Force try other tools based on situation
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

function surg(var)
   local v2 = var.v2 or ""
   
   if not var.v1:find("OnDialogRequest") then
      return false
   end
   
   -- ULTIMATE FAIL DETECTION - catch any failure message
   if v2:find("died") or v2:find("failed") or v2:find("escaped") or 
      v2:find("The patient") or v2:find("`4The patient") then
      -- Check if it's a failure message (not a status update)
      if not v2:find("tool") and not v2:find("Pulse") and not v2:find("Temp") and 
         not v2:find("Status") and not v2:find("Incisions") and not v2:find("Bones") then
         failCount = failCount + 1
         LogToConsole("`4[FAILED] Surgery #"..failCount.." failed. Restarting...")
         SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|start")
         return true
      end
   end
   
   -- ===== CRITICAL: Must handle ALL possible states =====
   
   -- 1. HEART STOPPED - Absolute priority
   if v2:find("Heart stopped") or v2:find("heart stopped") then
      tool = "Defibrillator"
      auto()
      return true
   end
   
   -- 2. ANESTHESIA ISSUES - Patient must stay sedated
   if v2:find("wakes up") or v2:find("screams") or v2:find("flails") or 
      v2:find("Awake") and v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   end
   
   if v2:find("Coming to") and v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   end
   
   -- 3. BLEEDING - All bleeding states
   if v2:find("losing blood") then
      if v2:find("very quickly") then
         -- Heavy bleeding
         if v2:find("tool4314") then
            tool = "Clamp"
         elseif v2:find("tool1270") then
            tool = "Stitches"
         end
      elseif v2:find("slowly") then
         -- Slow bleeding
         if v2:find("tool4314") then
            tool = "Clamp"
         elseif v2:find("tool1270") then
            tool = "Stitches"
         end
      else
         -- Normal bleeding
         if v2:find("tool4314") then
            tool = "Clamp"
         elseif v2:find("tool1270") then
            tool = "Stitches"
         end
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
   -- If we reach here, try ultrasound or scalpel to progress
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

AddHook(surg, "OnVariant")