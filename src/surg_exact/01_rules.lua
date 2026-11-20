-- [surg_exact/01_rules] surg(var): satu elseif per kondisi (teks dialog persis + tombol tool ada)
-- Tujuan : Cocokkan teks dialog persis (termasuk kode warna `4 `6 `3) dan cek tombol tool<ID> ada; set `tool`, panggil auto()
-- Dependensi: auto() = auto_surg/tools.lua TANPA blok anti-stuck (lihat notes/surg_exact.md)
-- Urutan load: 1 dari 2 (gabungkan segmen berurutan = script asli)
-- Sumber : raw/sorted/surg_exact_dfnl5.lua baris 33-200 (salinan verbatim)

function surg(var)
   if var.v1:find("OnDialogRequest") and var.v2:find("`4The patient wakes up!") and var.v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("`4The patient screams and flails!") and var.v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Status: `4Heart stopped!(.+)") and var.v2:find("tool4312") then
      tool = "Defibrillator"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Status: `6Coming to(.+)") and var.v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Pulse: `4(.+)") and var.v2:find("tool4310") then
      tool = "Transfusion"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Temp: `4(%d+)(.+)") and var.v2:find("tool1266") then
      tool = "Antibiotic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Temp: `4(%d+)(.+)") and var.v2:find("tool4318") then
      tool = "Lab kit"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Temp: `6(%d+)(.+)") and var.v2:find("tool1266") then
      tool = "Antibiotic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Temp: `6(%d+)(.+)") and var.v2:find("tool4318") then
      tool = "Lab kit"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Temp: `3(%d+)(.+)") and var.v2:find("tool1266") then
      tool = "Antibiotic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Temp: `3(%d+)(.+)") and var.v2:find("tool4318") then
      tool = "Lab kit"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient is losing blood `4very quickly!(.+)") and var.v2:find("tool4314") then
      tool = "Clamp"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient is losing blood `4very quickly!(.+)") and var.v2:find("tool1270") then
      tool = "Stitches"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient is `6losing blood!(.+)") and var.v2:find("tool4314") then
      tool = "Clamp"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient is `6losing blood!(.+)") and var.v2:find("tool1270") then
      tool = "Stitches"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Incisions: `20(.+)") and var.v2:find("tool1296") then
      tool = "Fix it"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Incisions: `30(.+)") and var.v2:find("tool1296") then
      tool = "Fix it"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("The patient has not been diagnosed.") and var.v2:find("tool4316") then
      tool = "Ultrasound"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Status: `4Awake(.+)") and var.v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+) broken``") and var.v2:find("tool1268") then
      tool = "Splint"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+) broken``") and var.v2:find("tool1268") then
      tool = "Splint"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient broke his arm.") and var.v2:find("tool1270") then
      tool = "Stitches"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Status: `3Awake(.+)") and var.v2:find("tool1262") then
      tool = "Anesthetic"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Pulse: `6(.+)") and var.v2:find("tool4310") then
      tool = "Transfusion"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("`4You can't see what you are doing!(.+)") and var.v2:find("tool1258") then
      tool = "Sponge"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("tool1296") and var.v2:find("tool1270") then
      tool = "Stitches"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+), `6(.+) shattered(.+)") and var.v2:find("tool4308") then
      tool = "Pins"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+), `6(.+) shattered(.+)") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+), `6(.+) shattered(.+)") and var.v2:find("tool4308") then
      tool = "Pins"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+), `6(.+) shattered(.+)") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+), `4(.+) shattered(.+)") and var.v2:find("tool4308") then
      tool = "Pins"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+), `4(.+) shattered(.+)") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+), `4(.+) shattered(.+)") and var.v2:find("tool4308") then
      tool = "Pins"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+), `4(.+) shattered(.+)") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+) shattered(.+)") and var.v2:find("tool4308") then
      tool = "Pins"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `6(.+) shattered(.+)") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+) shattered(.+)") and var.v2:find("tool4308") then
      tool = "Pins"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Bones: `4(.+) shattered(.+)") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient broke his leg.") and var.v2:find("tool1270") then
      tool = "Stitches"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("Patient is losing blood `3slowly.(.+)") and var.v2:find("tool4314") then
      tool = "Clamp"
      auto()
      return true
   elseif var.v1:find("OnDialogRequest") and var.v2:find("tool1260") then
      tool = "Scalpel"
      auto()
      return true
   end
   return false
end
