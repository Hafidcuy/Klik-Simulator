# 🖱️ Klik Simulator — Roblox

Game simulator Roblox yang dikembangkan dengan **Rojo + GitHub**:
kode ditulis sebagai file `.lua` biasa, lalu disinkronkan ke Roblox Studio
dengan plugin Rojo.

## Fitur

- Tombol **KLIK!** dengan teks melayang `+N` — hasil klik = Kekuatan Klik × Pengali
- **Toko Upgrade** kekuatan klik (harga naik ×1,6 per level)
- **Telur Pet** 500 klik — 7 pet Common s/d Mythic, 3 pet terbaik otomatis aktif
- **Rebirth** — reset klik & upgrade (pet tetap), pengali permanen +×1
- **DataStore** — save otomatis (Klik, Rebirth, level upgrade, pet)
- **Map & GUI dibuat otomatis oleh kode** — tidak ada aset manual

## Struktur

```
default.project.json            <- peta sinkron Rojo
src/server/MainServer.server.lua  -> ServerScriptService
src/client/ClientMain.client.lua  -> StarterGui
PANDUAN-SINKRON.md              <- panduan setup & sinkron lengkap
```

## Mulai Cepat

1. Install plugin Rojo di Studio + ekstensi Rojo di VS Code
   (panduan lengkap: [PANDUAN-SINKRON.md](PANDUAN-SINKRON.md))
2. `rojo serve` di folder ini
3. Di Studio: Plugins → Rojo → **Connect**
4. Game Settings → Security → **Enable Studio Access to API Services**
5. **Play**

## Mengubah Game

Semua angka game ada di bagian `KONFIGURASI GAME` pada
`src/server/MainServer.server.lua`: harga telur (`EGG_COST`), harga rebirth
(`BASE_REBIRTH_COST`), dan tabel pet `PETS` (total `Chance` harus 100).
