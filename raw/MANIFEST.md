# MANIFEST — daftar file raw

Dibaca AI sebelum memproses inbox, untuk mendeteksi file yang sudah pernah masuk.
Kolom hash: sha256 isi file. Nama asli = nama file saat dikirim ke inbox (nama di `sorted/` sudah dirapikan).

| File di `sorted/` | Nama asli | Jenis | sha256 | Modul / catatan |
|-------------------|-----------|-------|--------|-----------------|
| `auto_surg_v1.1_fixed.lua` | Auto_Surg_Fixed.lua.txt | asli | `0a949eddd515fdb580f71f62e41aa075b1f1e8e4a9d9e915725b9774157368a0` | `src/auto_surg/`, `notes/auto_surg.md` |
| `auto_surg_v1.0_beta.lua` | Auto Surg (Beta).lua.txt | varian lama dari auto_surg | `dea2a0b2de1735b04e7d7bc8d597e78961ed54bd2efa62fb5136b3205a49bcf3` | tidak dipecah; selisih di `notes/auto_surg.md` |
| `surg_exact_dfnl5.lua` | AUTO_SURG__DFNL5_.lua.txt | asli | `62a2e4b9a38b1272ccd9272674bb8ab9fdf08d98deacc72b7649b59535851a6e` | `src/surg_exact/`, `notes/surg_exact.md` |
| `surg_exact_ceximo_edit.lua` | Edit_Ceximo_Auto_Surgery.lua.txt | varian dari surg_exact_dfnl5 | `bfb48d045731cc764d176532ba9c40e25a3f0b3a3e836dc0edb73a5e77c962a2` | tidak dipecah; selisih di `notes/surg_exact.md` |
| `surg_helper_zayn_v2.0.lua` | Surg Helper_Zayn.lua.txt | asli | `04246db07d642326a9e39a0f31634623d78072eb57f3ffbbd3af7b0766b16d0f` | `src/surg_helper_zayn/`, `notes/surg_helper_zayn.md` |
| `auto_clear_kurangtahu.lua` | Auto Clear by __kurangtahu_.lua.txt | asli | `2e55378fee988e6d98c553b2ef83ff4edda158fe4ac611dc9f13f0e32e7c4cf1` | `src/auto_clear/`, `notes/auto_clear.md` |
| `auto_buy_pack_boren.lua` | auto_buy_pack.lua.txt | asli | `7d526dce5fd500e0102f4a4d5dbbf4df268e8e8da12ab070155d6be40bb1e03a` | `src/auto_buy_pack/`, `notes/auto_buy_pack.md` |

Catatan: `Auto_Surg_Fixed.lua.txt` pernah ada di inbox dan dihapus oleh user (commit "Delete raw/inbox/Auto_Surg_Fixed.lua.txt"); kemungkinan duplikat dari `auto_surg_v1.1_fixed.lua` yang sudah terdaftar.

## Inbox saat ini
_(kosong)_

## Cara AI menghitung hash
`sha256sum raw/inbox/<file>` lalu cocokkan dengan kolom sha256 di atas.
