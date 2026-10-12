# Brief Bisnis - Kedai Renjana Budget & Cash Flow Planning

**Perusahaan (fiktif):** Kedai Renjana
**Peran kamu:** Data/Financial Analyst lepas, diminta bantu bikin model perencanaan
**Stakeholder:** Kirana, pemilik sekaligus pemegang pembukuan Kedai Renjana
**Cara kerja:** ASAP (kolaborasi langsung dari awal)

---

## Latar Belakang

Kedai Renjana adalah kedai kopi kecil yang mulai beroperasi Juni 2022 di area perkantoran (outlet pertama, "Renjana Utama"). Karena responnya bagus, April 2024 Kirana buka outlet kedua ("Renjana Kedua") di dekat kampus untuk menjangkau segmen mahasiswa.

Selama ini Kirana pegang sendiri pembukuannya secara sederhana, catat pemasukan dan pengeluaran per bulan, belum pernah bikin proyeksi ke depan secara formal. Sekarang dia dihadapkan dua keputusan besar sekaligus.

## Business Problem

> "Supplier kopi biji langgananku bilang harga bakal naik, tapi belum pasti berapa persen, kemungkinan antara 10-20%. Di saat yang sama ada dua tempat yang cocok buat outlet ketiga, tapi aku belum tahu kapan waktu yang aman buat buka, dan mana yang lebih masuk akal. Aku enggak mau pinjam bank, jadi semua modal outlet baru harus dari kas sendiri. Aku butuh semacam model yang bisa aku pakai buat coba-coba skenario sebelum ambil keputusan, bukan cuma feeling."

Beberapa hal yang sengaja belum dijelaskan Kirana secara pasti, jadi bagian yang perlu didiskusikan/ditentukan bareng sebelum masuk ke perhitungan skenario:

- **Ambang kas cadangan yang dianggap "aman".** Kirana belum punya angka pasti. Dia pernah dengar rule of thumb "kas cadangan = 3-6 bulan biaya tetap (Sewa + Gaji)" tapi belum memutuskan mana yang mau dipakai untuk Kedai Renjana.
- **Kapan waktu paling masuk akal untuk membuka outlet ketiga**, kalau memang jadi dibuka, belum ditentukan (bulan ke berapa dalam proyeksi 12 bulan ke depan).
- **Berapa persen tepatnya kenaikan harga kopi biji** juga belum pasti (rentang 10-20% dari supplier), jadi perlu disimulasikan di beberapa titik, bukan satu angka tunggal.

## Data yang Tersedia

- `Penjualan_Harian.csv` - riwayat omzet harian kedua outlet, Januari 2024 - Desember 2025 (24 bulan)
- `Biaya_Bulanan.xlsx` - riwayat biaya bulanan kedua outlet per kategori (Bahan Baku, Gaji, Sewa, Utilitas, Marketing, Maintenance, Lain-lain)
- `Parameter_Asumsi.xlsx` - kumpulan asumsi dan angka referensi dari Kirana untuk membangun proyeksi dan skenario (harga kopi, capex 2 kandidat lokasi outlet baru, kurva ramp-up, dan sebagainya)
- `Referensi_Outlet.xlsx` - data outlet eksisting dan 2 kandidat lokasi outlet baru

## Constraints

- Modal outlet baru harus 100% dari kas internal, tidak ada opsi pinjaman.
- Proyeksi yang diminta minimal untuk 12 bulan ke depan (Januari - Desember 2026).
- Model harus bisa dipakai ulang oleh Kirana sendiri untuk mengubah asumsi (bukan cuma satu angka hasil akhir yang statis), jadi butuh Scenario Manager, Data Table, dan/atau Goal Seek, bukan sekadar hitungan manual sekali pakai.
- Kirana bukan orang finance, jadi sheet ringkasan hasil harus mudah dibaca tanpa perlu paham rumus di baliknya.

## Catatan Disclosure Data

*Dataset ini adalah data simulasi, dibuat untuk keperluan portofolio, dirancang menyerupai pola bisnis kedai kopi kecil multi-outlet agar analisisnya realistis. Bukan data perusahaan asli.*
