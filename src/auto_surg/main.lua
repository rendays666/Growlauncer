-- [auto_surg/main] Entry point: dialog pembuka, log, pasang hook
-- Tujuan : tampilkan peringatan ke pemain, lalu daftarkan surg() ke event OnVariant
-- Dependensi: detect.lua (surg), API loader: sendDialog, LogToConsole, growtopia.notify, AddHook
-- Urutan load: 4 (terakhir)
-- Sumber : raw/auto_surg_v1.1_fixed.lua baris 1, 10-18, 245 (salinan verbatim)
-- Beda urutan dari raw: dialog/log pembuka dijalankan SETELAH fungsi didefinisikan
-- (tidak berpengaruh karena definisi fungsi tidak punya efek samping)

--Auto Surg V1.1 (Fixed)

sendDialog({
    title = "Script By Moeyii",
    message = "Auto Surg\nWarning:\n\n• consumption tea & skill spice before starting.\n• Maximum anti-fail protection.\n• Auto-restart on failure.",
    confirm = "OKE",
    alias = "OKE"
})

LogToConsole("`0[`9Auto Surg`0]`2 MAX Active")
growtopia.notify("`2AUTO SURG MAX ACTIVE")

AddHook(surg, "OnVariant")
