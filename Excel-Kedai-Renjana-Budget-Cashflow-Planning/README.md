# Kedai Renjana Budget & Cash Flow Planning

Model perencanaan kas di Excel (Data Table, Scenario Manager, Goal Seek) untuk kedai kopi 2-outlet yang harus memutuskan dua hal sekaligus: menghadapi kenaikan harga kopi biji dan membuka outlet ketiga tanpa pinjaman bank.

## Business Problem
Kedai Renjana adalah kedai kopi kecil dengan dua outlet (Renjana Utama sejak Juni 2022, Renjana Kedua sejak April 2024). Supplier kopi biji langganan akan menaikkan harga sekitar 10-20% (belum pasti), dan di saat yang sama pemiliknya, Kirana, sedang menimbang dua lokasi untuk outlet ketiga: Lokasi C (dekat stasiun) dan Lokasi D (dekat perumahan). Modal outlet baru harus 100% dari kas sendiri, dan Kirana belum punya patokan berapa kas cadangan yang dianggap aman.

Pertanyaan yang dijawab model ini: lokasi dan waktu buka mana yang paling ringan untuk kas, kapan modalnya balik, dan seberapa besar kenaikan harga kopi yang masih bisa ditanggung kalau semuanya terjadi bersamaan. Modelnya dibuat supaya Kirana (yang bukan orang finance) bisa mengganti asumsi sendiri dan melihat hasilnya langsung.

## Screenshot

**Pola omzet 24 bulan (BQ1)**

![Omzet bulanan per outlet](images/00-grafik-omzet-bulanan-per-outlet.png)

**Proyeksi baseline 2026 (BQ3)**: omzet, biaya, margin, dan kas akhir bulan untuk Januari-Desember 2026.

![Proyeksi 2026](images/01-proyeksi-2026.png)

**Data Table: simulasi kenaikan harga kopi biji (BQ4)**: kas akhir Desember dan rata-rata margin bulanan untuk kenaikan 10%, 15%, 20%. Angka paling atas (tanpa kenaikan) adalah baseline.

![Data Table kenaikan harga kopi](images/02-data-table-kenaikan-harga-kopi.png)

**Model outlet baru (BQ5)**: contoh Lokasi D dibuka bulan ke-1. Kurva ramp-up, capex, dan kas gabungan dihitung per bulan.

![Skenario Lokasi D bulan 1](images/03-skenario-lokasi-d-bulan-1.png)

**Scenario Manager: 5 skenario dalam satu tabel (BQ5)**

![Scenario Summary](images/04-scenario-summary.png)

**Kas 2026 untuk kelima skenario terhadap ambang kas minimum (BQ5-BQ6)**: grafik ini digenerate dari angka model.

![Kas 2026 lima skenario](images/07-grafik-kas-2026-lima-skenario.png)

**Ambang kas minimum (BQ6)**

![Ambang kas minimum](images/06-ambang-kas-minimum.png)

**Goal Seek: hasil pencarian kenaikan harga kopi maksimum (BQ6)**: sel `Proyeksi!O27` setelah Goal Seek dijalankan.

![Hasil Goal Seek](images/05-goal-seek-hasil-260persen.png)

**Toleransi kenaikan harga kopi per skenario (BQ6)**: grafik ini digenerate dari angka model.

![Toleransi kenaikan harga kopi](images/08-grafik-toleransi-kenaikan-harga-kopi.png)

## Pendekatan
1. **Bersihkan data.** Omzet harian dan biaya bulanan kedua outlet punya empat masalah yang sengaja dibuat realistis: jumlah transaksi kosong 5 hari karena mesin kasir rusak, 6 hari tutup renovasi yang tercatat omzet 0, 3 baris duplikat dari masa transisi sistem kasir, dan biaya sewa yang salah masuk kategori "Lain-lain" di dua bulan. Semuanya ditangani sebelum dipakai.
2. **Ringkas ke tabel bulanan** dengan `SUMIFS` dan PivotTable, lalu hitung margin per outlet dan kas berjalan dari kas awal Rp12 juta (1 Januari 2024).
3. **Proyeksi baseline 2026**: omzet dan biaya tiap bulan 2026 = bulan yang sama di 2025 dikali rata-rata pertumbuhan tahunan masing-masing outlet.
4. **Stress test dengan tiga alat what-if**: Data Table untuk sensitivitas harga kopi, Scenario Manager untuk membandingkan lokasi dan waktu buka, Goal Seek untuk mencari titik toleransi kombinasi keduanya.

## Formula/Fitur Kunci
- `=B14*(1+$O$15)` (sheet `Proyeksi`): dipakai untuk memproyeksikan omzet Januari 2026 dari Januari 2025 dengan rata-rata pertumbuhan tahunan outlet (24,2% Utama, 17,0% Kedua).
- `=N29 + L29*(1-55%) + L29*55%*(1+$O$27)` (kolom Biaya Utama Akhir): dipakai untuk menaikkan hanya porsi kopi biji (55% dari bahan baku) sebesar persentase di sel input `O27`, sementara biaya lain tidak berubah. Kolom biaya dasar dipisah dari kolom "Akhir" supaya baseline tetap utuh dan tidak ada circular reference.
- `=IF(F6=0,0,IF($B$1="C", VLOOKUP(MIN(F6,12),$A$6:$C$17,2,FALSE),IF($B$1="D",VLOOKUP(MIN(F6,12),$A$6:$C$17,3,FALSE),0)))` (sheet `Skenario_Outlet_Baru`): dipakai untuk mengambil persen ramp-up omzet outlet baru dari tabel per lokasi berdasarkan "bulan sejak buka", bukan bulan kalender. Mengubah asumsi ramp-up cukup mengedit tabel, tanpa menyentuh formula.
- `=Proyeksi!I25+Proyeksi!H29+L6` lalu `=M6+Proyeksi!H30+L7`: dipakai untuk kas gabungan = kas akhir 2025 + margin dua outlet eksisting + net kas outlet baru (termasuk capex di bulan buka), dihitung kumulatif per bulan.
- **Data Table satu variabel** (`Proyeksi!A44:C47`, input `O27`): dipakai untuk melihat kas akhir Desember dan rata-rata margin untuk kenaikan 10/15/20% sekaligus.
- **Scenario Manager** (5 skenario, sel yang diubah `B1:B2` di `Skenario_Outlet_Baru`): dipakai untuk berpindah antara tidak buka, Lokasi C, Lokasi D, masing-masing dibuka bulan ke-1 atau ke-4, dengan satu klik.
- **Goal Seek** (set cell `Skenario_Outlet_Baru!M17`, by changing `Proyeksi!O27`): dipakai untuk mencari kenaikan harga kopi biji yang membuat kas akhir 2026 turun tepat ke ambang minimum.

## Findings

**Kondisi awal (BQ1-BQ2)**
- Kas Kedai Renjana per akhir Desember 2025 adalah **Rp232.145.000**, tumbuh dari Rp12 juta di Januari 2024. Rata-rata margin bulanan 2025: Renjana Utama Rp8,40 juta, Renjana Kedua Rp4,28 juta, gabungan Rp12,68 juta.
- Renjana Kedua rugi di empat bulan pertama (April-Juli 2024, saat masih ramp-up) dan positif sejak Agustus 2024. Satu-satunya pengecualian adalah Juli 2025 (rugi Rp0,9 juta saat libur semester).
- Omzet Utama tumbuh rata-rata 24,2% per tahun, Kedua 17,0% per tahun (dihitung dari September-Desember saja, supaya bulan-bulan awal Kedua yang masih ramp-up tidak menggelembungkan angkanya). Biaya tumbuh lebih lambat: 13,1% (Utama) dan 11,0% (Kedua).
- Pola musiman: Utama memuncak tiap Desember (Rp33,6 juta di 2024, Rp39,9 juta di 2025, sekitar 28-30% di atas bulan sebelumnya), sementara Kedua turun tajam di Juli dan Januari, konsisten dengan libur semester kampus (Juli 2025: Rp12,3 juta vs Rp21-22 juta di bulan sekitarnya).

**Baseline dan harga kopi (BQ3-BQ4)**
- Tanpa outlet baru dan tanpa kenaikan harga, kas proyeksi akhir Desember 2026 adalah **Rp458.371.022**, dengan rata-rata margin Rp18,85 juta per bulan.
- Kenaikan harga kopi 10% / 15% / 20% menurunkan rata-rata margin menjadi Rp17,75 / 17,19 / 16,64 juta per bulan (turun 5,9% / 8,8% / 11,7%), dan kas akhir Desember menjadi Rp445,1 / 438,5 / 431,8 juta. Dampaknya linear: tiap kenaikan 1 poin persen harga kopi menggerus sekitar Rp110 ribu margin per bulan, jadi tidak ada titik patah. Margin tetap positif di seluruh rentang 10-20% karena kopi biji hanya 55% dari bahan baku, dan bahan baku hanya sebagian dari total biaya.

**Outlet ketiga (BQ5)**

| Skenario | Kas akhir Des 2026 | Selisih vs tidak buka | Estimasi balik modal |
|---|---|---|---|
| Tidak buka outlet baru | Rp458.371.022 | - | - |
| Lokasi D, buka bulan 1 | Rp431.054.854 | -Rp27.316.168 | bulan ke-19 sejak buka (Juli 2027) |
| Lokasi D, buka bulan 4 | Rp406.708.585 | -Rp51.662.437 | bulan ke-19 sejak buka (Oktober 2027) |
| Lokasi C, buka bulan 1 | Rp404.500.973 | -Rp53.870.049 | bulan ke-33 sejak buka (September 2028) |
| Lokasi C, buka bulan 4 | Rp380.154.704 | -Rp78.216.318 | bulan ke-33 sejak buka (Desember 2028) |

- Tidak ada skenario yang balik modal di dalam 12 bulan proyeksi. Semua skenario outlet baru berakhir di bawah baseline karena capex dibayar di muka sementara omzet baru matang setelah 6-7 bulan.
- **Lokasi D lebih ringan untuk kas** (selisih Rp26,6 juta di akhir 2026 pada bulan buka yang sama) dan balik modal jauh lebih cepat (sekitar 19 bulan vs 33 bulan). Omzet matang dua lokasi diasumsikan sama (Rp20,8 juta per bulan), jadi pembedanya capex (Rp92 juta vs Rp134 juta) dan sewa tahun kedua (Rp3,8 juta vs Rp5,5 juta per bulan).
- **Buka lebih cepat lebih baik untuk kas akhir tahun.** Menunda dari bulan 1 ke bulan 4 menurunkan kas akhir 2026 sekitar Rp24,3 juta di kedua lokasi, karena bulan-bulan produktif outlet baru berkurang. Menunda tidak mengurangi risiko, hanya menggeser capex.
- Perkiraan balik modal memakai omzet matang yang datar di Rp20,8 juta dan sudah memasukkan sewa bulanan mulai tahun kedua.

**Gabungan harga kopi naik + outlet baru (BQ6)**
- Ambang kas cadangan minimum yang dipakai: **Rp86.263.974**, yaitu 4 bulan biaya non-bahan baku (Rp21,57 juta per bulan, rata-rata 2025) berdasarkan rule of thumb UMKM 3-6 bulan.
- Di skenario terberat yang realistis (Lokasi C dibuka bulan 1, harga kopi naik 20%), kas terendah sepanjang 2026 adalah **Rp110,9 juta**, masih Rp24,6 juta di atas ambang. Jadi kombinasi kenaikan harga dan outlet baru **aman** di seluruh rentang 10-20% dari supplier.
- Goal Seek pada skenario terbaik (Lokasi D, bulan 1) menunjukkan kas akhir 2026 baru menyentuh ambang kalau harga kopi naik **sekitar 260%**. Dengan ukuran yang lebih ketat (kas terendah di salah satu dari 12 bulan, bukan hanya Desember), angkanya sedikit turun ke 259%, karena kas sempat turun ke Rp85,5 juta di September sebelum pulih. Di skenario paling rentan (Lokasi C, bulan 4) toleransinya 185%. Kesimpulannya sama di semua skenario: ruang amannya sangat besar dibanding rentang 10-20% dari supplier.
- Karena skenario terberat realistis ternyata aman, opsi Goal Seek di brief (mencari omzet minimum outlet baru atau bulan buka paling awal yang aman) tidak diperlukan. Goal Seek dipakai untuk mencari toleransi harga.

## Keterbatasan & Asumsi
- Baseline 2026 mengekstrapolasi pertumbuhan 2025 apa adanya. Karena biaya (sebagian besar tetap) tumbuh lebih lambat dari omzet, rata-rata margin 2026 naik sekitar 49% dibanding 2025 (Rp18,85 juta vs Rp12,68 juta per bulan). Ini asumsi yang cukup optimis.
- Kenaikan harga kopi dihitung sebagai tambahan biaya penuh: tidak ada kenaikan harga jual dan tidak ada penurunan volume.
- Outlet baru dianggap tidak menggerus omzet outlet eksisting, dan omzet matangnya datar di rata-rata omzet Renjana Kedua enam bulan terakhir (Rp20,8 juta per bulan).
- Ambang kas minimum memakai definisi luas (semua biaya selain bahan baku). Kalau hanya Sewa + Gaji (Rp19,2 juta per bulan, ambang Rp76,8 juta), toleransi harga kopi di skenario Lokasi D bulan 1 naik ke sekitar 267%.
- Goal Seek dijalankan pada kas Desember, lalu dicek ulang terhadap kas terendah 12 bulan (lihat Findings).

## Cara Melihat
Download `model/Kedai-Renjana-Budget-Model.xlsx` dan buka dengan Microsoft Excel desktop (Scenario Manager, Data Table, dan Goal Seek tidak tampil sempurna di Google Sheets atau pratinjau GitHub). Excel akan menghitung ulang otomatis saat file dibuka.

Isi sheet: `Parameter_Asumsi`, `Referensi_Outlet` (input), `Penjualan_Harian` dan `Biaya_Bulanan` (data mentah + PivotTable), `Proyeksi` (histori, baseline 2026, Data Table), `Skenario_Outlet_Baru` (model outlet baru + ambang kas), `Scenario Summary` (hasil Scenario Manager).

Untuk mencoba sendiri:
- **Ganti skenario:** Data > What-If Analysis > Scenario Manager > pilih skenario > Show. Atau ubah `Skenario_Outlet_Baru!B1` ("Tidak Ada", "C", atau "D") dan `B2` (bulan buka 1-12).
- **Simulasi harga kopi:** ubah `Proyeksi!O27`. Kembalikan ke 0% untuk melihat baseline.
- **Ulangi Goal Seek:** Data > What-If Analysis > Goal Seek. Set cell `Skenario_Outlet_Baru!M17`, to value `86263974`, by changing cell `Proyeksi!O27` (dengan `B1` = D dan `B2` = 1). Kembalikan `O27` ke 0% setelahnya.

## Struktur Repo
```
model/    -> file model Excel
data/     -> data mentah sintetis (4 file) yang dipakai di model
images/   -> screenshot dan grafik untuk README ini
*.md      -> brief bisnis, business questions, data dictionary
```

## Catatan Data
Dataset ini adalah data simulasi, dibuat untuk keperluan portofolio, dirancang menyerupai pola bisnis kedai kopi kecil multi-outlet agar analisisnya realistis. Bukan data perusahaan asli. Kedai Renjana, Kirana, dan semua angka di dalamnya fiktif.
