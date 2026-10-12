# Digital Product Sales Consolidation (Kanti Studio)

## Business Problem

Kanti Studio (nama bisnis fiktif) menjual produk digital (ebook & template) lewat 3 kanal sekaligus: toko sendiri (KantiStore), marketplace pihak ketiga (KaryaMarket), dan program afiliasi. Masalahnya, data penjualan dari ketiga kanal ini formatnya beda-beda dan belum pernah digabung, jadi pemilik bisnis tidak bisa menjawab pertanyaan sederhana seperti "kanal mana yang sebenarnya paling menguntungkan?" tanpa menyatukan dan membersihkan datanya dulu.

Project ini mengonsolidasikan data mentah dari 3 sumber tersebut menjadi satu model data di Excel, lalu menjawab 6 pertanyaan bisnis kunci soal omzet, margin, dan tren pertumbuhan per kanal.

*Catatan: seluruh data di project ini adalah data simulasi (sintetis), dibuat menyerupai pola bisnis nyata, bukan data perusahaan asli.*

## Screenshot

<!-- Sisipkan di sini:
1. Power Pivot Diagram View, relasi antar tabel (Fact_Penjualan, Dim_Produk, Calendar)
2. PivotTable Omzet dan Margin per Channel (jawaban Business Question #1 dan #3)
3. PivotTable Tren Order Bulanan per Channel (jawaban Business Question #5)
-->

## Pendekatan

1. **Power Query.** 3 sumber data mentah (KantiStore, KaryaMarket, Afiliator) masing-masing dibersihkan lewat query terpisah: hapus duplikat, filter transaksi yang statusnya bukan "Completed" (refund/chargeback), samakan format tanggal, dan mapping nama produk yang berantakan (huruf besar/kecil, ada yang tanpa spasi) ke kode produk yang konsisten pakai tabel mapping.
2. Ketiga query hasil bersih (`Fact_KantiStore`, `Fact_KaryaMarket`, `Fact_Afiliator`) digabung jadi satu tabel `Fact_Penjualan` lewat Append Queries, dengan skema kolom yang disamakan dulu di ketiganya (tanggal, kode_produk, qty, omzet, fee, channel) supaya bisa digabung dengan aman.
3. **Power Pivot.** `Fact_Penjualan` dihubungkan ke `Dim_Produk` (harga dan biaya produksi) dan tabel Calendar lewat relationship, sehingga semua kanal bisa dianalisis dalam satu model.
4. **PivotTable dan DAX measures** dipakai untuk menjawab 6 pertanyaan bisnis: kontribusi omzet per kanal, dampak data belum dibersihkan terhadap ranking kanal, margin bersih per kanal, dampak salah baca format komisi afiliator, tren pertumbuhan bulanan, dan rekomendasi kanal mana yang paling worth digenjot.

## Formula/Fitur Kunci

- `Margin := SUM(Fact_Penjualan[omzet]) - SUMX(Fact_Penjualan, RELATED(Dim_Produk[biaya_produksi])) - SUM(Fact_Penjualan[fee]))`. DAX measure untuk margin bersih per kanal, menghitung baris per baris karena biaya produksi beda-beda tiap produk.
- `Total Order := COUNTROWS(Fact_Penjualan)`. Dipakai bareng tabel Calendar untuk lihat tren jumlah order per bulan per kanal.
- Custom column Power Query, dua versi untuk perbandingan: `if [komisi_tercatat] > 30 then 30 else [komisi_tercatat]` (versi salah, dipaksa persen semua) versus `if [komisi_tercatat] <= 30 then [nilai_penjualan] * [komisi_tercatat] / 100 else [komisi_tercatat]` (versi benar). Dipakai untuk membuktikan dampak kalau format komisi afiliator (persen vs nominal rupiah) salah dibaca.
- Group By (Advanced mode, tanpa kolom grouping). Dipakai sebagai cara aman untuk hitung total agregat tanpa mengubah tabel aslinya.

## Findings

Setelah data dari 3 kanal dibersihkan dan dikonsolidasikan, total omzet Rp469.258.000 dengan kontribusi KantiStore 42,4% (Rp199.015.000), KaryaMarket 39,3% (Rp184.306.000), dan Afiliator 18,3% (Rp85.937.000).

Temuan paling penting: kalau omzet KaryaMarket dijumlah langsung dari data mentah tanpa filter status transaksi, hasilnya Rp204.858.000, lebih besar dari KantiStore, sehingga KaryaMarket kelihatan sebagai kanal terbesar. Begitu transaksi Refunded dan Chargeback (9,6% dari total transaksi) dikeluarkan, omzetnya turun ke Rp184.306.000 dan rankingnya berbalik menjadi di bawah KantiStore. Ini bukti nyata kenapa data harus dibersihkan dulu sebelum diambil kesimpulan bisnis.

Dari sisi margin, gapnya lebih jelas lagi. KantiStore punya margin ratio 85,1% sementara KaryaMarket cuma 58,2%, padahal omzet keduanya mirip. Fee KaryaMarket yang besar (sekitar 30%) plus refund rate yang tinggi membuatnya jauh kurang menguntungkan dari yang terlihat di angka omzet kotor.

Untuk kanal Afiliator, cara membaca format komisi juga berdampak signifikan. Komisi yang dihitung benar (mengikuti format asli tiap baris, persen atau nominal rupiah) sebesar Rp15.529.500, sementara kalau semua baris dipaksa dihitung sebagai persentase, hasilnya Rp19.097.100, selisih 23% lebih besar dari yang seharusnya.

Dari sisi tren, KantiStore juga tumbuh paling kencang. Rata-rata order bulanan naik dari sekitar 116 ke sekitar 229 (naik 97%) dari 3 bulan pertama ke 3 bulan terakhir, jauh di atas KaryaMarket (naik 36%) dan Afiliator (naik 27%).

Kesimpulannya, tiga sudut pandang berbeda (omzet bersih, margin, dan tren pertumbuhan) sama-sama mengarah ke KantiStore sebagai kanal paling worth digenjot tahun depan, bukan KaryaMarket yang omzet mentahnya terlihat paling besar.

## Cara Melihat

File Excel final ada di folder `data/` beserta 4 file data mentah yang jadi sumbernya. Download file `.xlsx`-nya lalu buka di Excel (perlu Power Pivot add-in aktif untuk melihat data model dan measure-nya). Cara aktifkan: File > Options > Add-ins > COM Add-ins, lalu centang "Microsoft Power Pivot for Excel".
