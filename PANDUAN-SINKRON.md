# 🔄 Panduan Sinkron Rojo + GitHub — Klik Simulator

Tujuan setup ini: **Mahiru mengedit kode di GitHub → kamu klik Connect di Roblox
Studio → semua perubahan langsung masuk ke game-mu.** Sekali setup, seterusnya
tinggal 2 klik.

Alurnya: `Repo GitHub → (kamu) git pull → Rojo serve → plugin Rojo di Studio → game terupdate`

---

## LANGKAH 1 — Buat repo GitHub (sekali saja, ±1 menit)

1. Buka https://github.com/new
2. **Repository name:** `Klik-Simulator`
3. Pilih **Public**, **JANGAN** centang "Add a README file" (repo harus kosong).
4. Klik **Create repository**, lalu **kirim link repo-nya ke Mahiru di chat**.
   Mahiru akan mengisi repo itu dengan project ini dan memverifikasi isinya.

> Kalau GitHub meminta memilih repo mana saja yang boleh diakses Mahiru
> (halaman instalasi GitHub App), pastikan repo `Klik-Simulator` ikut dipilih.

## LANGKAH 2 — Install alat di PC kamu (sekali saja)

1. **Git** — https://git-scm.com/download/win (install, semua pilihan default).
2. **VS Code** — kalau belum ada: https://code.visualstudio.com
3. Di VS Code, install ekstensi **Rojo** (cari "Rojo" di panel Extensions —
   penerbitnya `Roblox` / rojo-rbx). Ekstensi ini sudah termasuk Rojo CLI.
4. **Plugin Rojo untuk Studio** — buka Roblox Studio → tab **Plugins** →
   **Plugins Folder**… cara termudah: di VS Code, buka Command Palette
   (`Ctrl+Shift+P`) → ketik **"Rojo: Install Roblox Studio Plugin"** → Enter.
   Atau unduh plugin dari halaman Creator Store Rojo lalu pasang manual.

## LANGKAH 3 — Ambil project ke PC kamu

1. Buka terminal (di VS Code: `Terminal → New Terminal`).
2. Jalankan (ganti dengan link repo dari Langkah 1 bila namanya berbeda):
   ```
   git clone https://github.com/Hafidcuy/Klik-Simulator.git
   cd Klik-Simulator
   code .
   ```
3. VS Code akan membuka folder project. Struktur pentingnya:
   - `default.project.json` — peta sinkron Rojo
   - `src/server/MainServer.server.lua` → masuk ke **ServerScriptService**
   - `src/client/ClientMain.client.lua` → masuk ke **StarterGui**

## LANGKAH 4 — Hubungkan Studio (setiap mau kerja)

1. Di VS Code (folder project terbuka), Command Palette (`Ctrl+Shift+P`) →
   **"Rojo: Serve"** → pilih `default.project.json`. Server Rojo jalan di
   `localhost:34872`.
   *(Alternatif terminal: jalankan `rojo serve` di folder project.)*
2. Di **Roblox Studio**: buka place baru/baseplate → tab **Plugins** → klik
   ikon **Rojo** → **Connect**. Status berubah jadi tersambung (hijau).
3. Script dari repo langsung muncul di Explorer:
   `ServerScriptService/MainServer` dan `StarterGui/ClientMain`.
4. Aktifkan save data: **Game Settings → Security → Enable Studio Access to
   API Services → ON**.
5. Tekan **Play (F5)** — map & GUI dibuat otomatis oleh script. Main!

## LANGKAH 5 — Rutinitas update berikutnya (2 klik + 1 perintah)

1. Mahiru bilang "sudah aku push update-nya".
2. Kamu buka terminal di folder project → `git pull`
3. Rojo yang sedang `serve` otomatis menyinkronkan perubahan ke Studio.
   Selesai — tidak perlu copy-paste lagi.

## Kalau ada masalah

| Gejala | Cek |
|---|---|
| Plugin Rojo tidak ada di Studio | Ulangi "Rojo: Install Roblox Studio Plugin" dari VS Code, lalu **restart Studio**. |
| Connect gagal / merah | Pastikan `rojo serve` masih jalan di VS Code dan port-nya sama (default 34872). |
| Script tidak muncul setelah Connect | Pastikan place yang terbuka boleh diedit dan kamu Connect ke project yang benar. |
| Perubahan Mahiru tidak masuk | Jalankan `git pull` dulu — Rojo hanya menyinkronkan isi folder di PC kamu. |
| Data tidak tersimpan saat Play | API Services belum ON (Langkah 4 nomor 4). |

## Bonus: tanpa Rojo pun bisa dites

File `KlikSimulator.rbxlx` (hasil build Rojo yang sudah diverifikasi) bisa
langsung dibuka di Roblox Studio (`File → Open from File…`) untuk mencoba
game-nya tanpa setup sinkron sama sekali.
