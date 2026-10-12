# Business Questions - Kedai Renjana Budget & Cash Flow Planning

Urutan dari yang paling gampang ke yang paling perlu penalaran. Pertanyaan belakangan butuh hasil dari pertanyaan sebelumnya, jadi lebih enak dikerjakan berurutan. Karena cara kerjanya ASAP, kita bahas dan kerjakan bareng dari nomor 1, bukan dijawab sendiri dulu baru dicocokkan belakangan.

1. Dari `Penjualan_Harian.csv`, setelah data dibersihkan, bagaimana pola omzet bulanan kedua outlet selama 24 bulan terakhir? Identifikasi tren pertumbuhan dan pola musiman (mingguan maupun bulanan) di masing-masing outlet.

2. Dari `Biaya_Bulanan.xlsx` (setelah direklasifikasi dengan benar, lihat Catatan Data Quality), berapa rata-rata margin bulanan (omzet dikurangi total biaya) tiap outlet? Dengan kas awal Rp 12.000.000 per 1 Januari 2024 (lihat `Parameter_Asumsi.xlsx`), berapa estimasi kas cadangan Kedai Renjana per akhir Desember 2025, sebagai titik awal proyeksi?

3. Bangun proyeksi baseline cash flow 12 bulan ke depan (Januari - Desember 2026), tanpa ada perubahan harga bahan baku maupun outlet baru, berdasarkan tren dan pola musiman dari pertanyaan #1. Berapa proyeksi kas di akhir Desember 2026 kalau semuanya berjalan seperti biasa?

4. **(Pakai Data Table satu variabel)** Simulasikan dampak kenaikan harga kopi biji sebesar 10%, 15%, dan 20% (ingat, cuma 55% dari total Bahan Baku yang berasal dari kopi biji, lihat `Parameter_Asumsi.xlsx`) terhadap margin bulanan dan proyeksi kas akhir Desember 2026. Di titik kenaikan berapa persen, kalau ada, margin bulanan mulai terasa berat?

5. **(Pakai Scenario Manager)** Bandingkan 3 skenario buka outlet ketiga: (a) tidak buka outlet baru sama sekali, (b) buka Lokasi C (dekat Stasiun), (c) buka Lokasi D (dekat Perumahan) - pakai capex dan kurva ramp-up masing-masing dari `Parameter_Asumsi.xlsx`. Untuk skenario (b) dan (c), coba juga bandingkan kalau outlet baru dibuka di bulan ke-1 proyeksi vs bulan ke-4 proyeksi. Bagaimana dampak tiap kombinasi terhadap kas cadangan sepanjang 12 bulan, dan berapa lama kira-kira modalnya balik (payback period)?

6. **(Sintesis, pakai Goal Seek)** Sekarang gabungkan skenario terberat: kenaikan harga kopi biji terjadi BERSAMAAN dengan pembukaan outlet baru. Apakah kas cadangan tetap di atas ambang aman yang sudah kamu diskusikan dan sepakati dengan Kirana (lihat catatan di `Parameter_Asumsi.xlsx` soal ambang ini) sepanjang 12 bulan proyeksi? Kalau ternyata tidak, pakai Goal Seek untuk mencari salah satu dari dua hal: (a) berapa target omzet bulanan minimum yang harus dicapai outlet baru supaya kas tetap aman, atau (b) bulan paling awal yang aman untuk membuka outlet baru.

## Catatan Data Quality

Sebelum menjawab pertanyaan di atas, cek dan bersihkan dulu:

- `Penjualan_Harian.csv`, outlet Renjana Utama: 5 hari di 8-12 Juli 2024 kolom `jumlah_transaksi` kosong (mesin kasir digital sempat rusak, kasir cuma sempat rekap omzet total secara manual). Omzet tetap valid dipakai, jumlah_transaksi di hari-hari itu jangan diisi asal.
- `Penjualan_Harian.csv`, outlet Renjana Utama: 12-17 Agustus 2024 omzet dan jumlah_transaksi tercatat 0 karena outlet tutup total untuk renovasi (ganti lantai & AC). Ini bukan data hilang, tapi memang tidak ada operasional - perlu diperlakukan beda dari hari biasa saat menghitung rata-rata harian.
- `Penjualan_Harian.csv`, outlet Renjana Kedua: 3 hari pertama sejak buka (1-3 April 2024) muncul dua kali (baris terduplikasi) karena masa transisi sistem POS lama dan baru sempat jalan berbarengan. Selain duplikat, angka di 3 hari itu juga jauh di atas normal karena promo grand opening - tidak representatif untuk dipakai sebagai basis tren pertumbuhan atau kurva ramp-up.
- `Biaya_Bulanan.xlsx`, outlet Renjana Kedua: bulan Agustus dan September 2024, biaya "Sewa" salah tercatat masuk kategori "Lain-lain" (staff pembukuan baru waktu itu belum hafal kategorisasi biaya). Perlu direklasifikasi sebelum menghitung biaya tetap (fixed cost) dengan benar - ini penting karena Sewa jadi salah satu input utama model proyeksi.
