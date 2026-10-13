# SaaS Subscription & Churn Analysis (Flowdesk)

## Business Problem
Flowdesk (perusahaan SaaS fiktif, task management tool untuk tim SMB di Asia Tenggara) mengalami churn yang naik, tapi tiga tim menyalahkan tiga hal berbeda: tim CS bilang resolusi tiket support terlalu lambat, tim Growth bilang kualitas channel akuisisi (terutama Paid Ads) buruk, dan CFO bilang banyak pembayaran gagal yang tidak pernah ditindaklanjuti. Leadership butuh tahu teori mana yang benar-benar didukung data, supaya investasi tahun ini diarahkan ke area yang tepat, bukan ke tiga arah sekaligus.

Project ini menggabungkan 6 tabel data subscription, payment, dan support ticket, lalu menguji ketiga teori itu satu per satu dengan metodologi statistik yang sesuai.

*Catatan: seluruh data di project ini adalah data simulasi (sintetis), dibuat menyerupai pola bisnis SaaS nyata, bukan data perusahaan asli.*

## Pendekatan
1. **Import & cleaning.** Load 6 tabel CSV ke SQL Server lewat `BULK INSERT`, dedupe baris payment yang duplikat persis lewat staging table, standardisasi kategori `acquisition_channel` yang penulisannya tidak konsisten (beda kapitalisasi/spasi/underscore, ketauan cuma kalau collation dipaksa case-sensitive), dan rekonstruksi tanggal cancel yang hilang di `subscriptions.end_date` lewat `subscription_events`.
2. **Analisis tren dasar.** Bangun logika "aktif per tanggal" (bukan cuma kolom status) supaya angka customer aktif dan MRR akurat secara historis per bulan, lalu hitung logo churn rate vs revenue churn rate dan temukan titik di mana dua definisi churn ini mulai bercerita beda.
3. **Investigasi penyebab.** Telusuri penyebab divergensi itu ke pola downgrade plan, pakai CTE rekursif buat generate kalender bulanan dan self-join ke tabel plan lama vs plan baru.
4. **Uji hipotesis.** Uji tiga teori stakeholder secara terpisah: right-censoring buat cohort yang belum genap diamati (early churn 90 hari, involuntary churn 30 hari), confidence interval 95% (Wald) buat tiap perbandingan proporsi, dan sensitivity test buat definisi boundary yang ambigu.
5. **Sintesis.** Ranking tiga teori berdasarkan kekuatan bukti, rekomendasi prioritas, dan daftar hal yang masih perlu dikonfirmasi ke stakeholder sebelum eksekusi.

## Teknik SQL Kunci
- CTE bertingkat, termasuk CTE rekursif buat generate kalender akhir bulan (`vw_month_calendar`)
- Window function: `ROW_NUMBER`, `LAG` (buat bandingkan bulan berjalan vs bulan sebelumnya)
- Self-join ke tabel `plans` (alias `p_old`/`p_new`) buat hitung selisih harga saat downgrade
- Correlated subquery dengan `EXISTS`/`NOT EXISTS`: anti-join buat logo churn, dan cek "apakah payment gagal pernah pulih sebelum cancel" buat involuntary churn
- Right-censoring: exclude subscription/payment yang belum genap waktu observasinya (30 atau 90 hari) dari akhir data, supaya tidak salah dihitung "belum churn" padahal cuma belum sempat teramati
- Interval kepercayaan 95% (Wald) buat tiap perbandingan proporsi antar grup
- Staging table + `SELECT DISTINCT` buat dedupe data mentah sebelum load ke tabel final

## Key Findings & Business Impact
- **Involuntary churn (pembayaran gagal) adalah kontributor terbesar**: ~56% dari seluruh subscription yang cancel didahului payment gagal yang tidak pernah pulih dalam 30 hari, lebih besar dari dua teori lain digabung.
- Subscription dengan payment gagal **38x lebih mungkin cancel dalam 30 hari** dibanding yang pembayarannya sukses (61,4% vs 1,6%), dengan confidence interval 95% dua kelompok yang jauh dari overlap.
- **Revenue churn rate mulai menyimpang dari logo churn rate sejak Agustus 2025**, gap-nya melebar sampai ~+24%. Dipicu downgrade plan yang naik tajam sejak bulan yang sama, sesuatu yang sama sekali tidak kelihatan kalau cuma pantau jumlah customer yang berhenti.
- **Teori channel akuisisi cuma benar untuk kombinasi spesifik**: Paid Ads + tier Starter early-churn 34,2% (jauh di atas channel lain di tier sama, 4,8%-17,7%), tapi efeknya nyaris hilang di tier Growth/Scale, bukan masalah channel secara umum.
- **Teori kecepatan resolusi support tidak terbukti**: selisih rata-rata waktu resolusi tiket antara customer churn vs bertahan cuma -0,02 hari, dengan confidence interval yang jauh melewati nol (null result yang meyakinkan, bukan sekadar "belum ketemu buktinya").
- **Rekomendasi**: prioritaskan perbaikan sistem retry/dunning pembayaran (dampak terbesar dan paling actionable), bukan channel akuisisi atau kecepatan support.

## Struktur Repo
```
sql/    → import, cleaning, dan seluruh query analisis (01_create_and_import.sql)
data/   → data mentah (customers.csv, plans.csv, subscriptions.csv, subscription_events.csv, payments.csv, support_tickets.csv)
```

## Cara Membuka
Buat database baru di SQL Server, lalu jalankan `sql/01_create_and_import.sql` dari atas ke bawah (sesuaikan path folder `data/` di bagian `BULK INSERT` dengan lokasi file di komputer kamu). File sudah urut: setup schema → import → verification → cleaning → seluruh query analisis (6.1-6.8).

---

**Catatan:** Dataset ini adalah data simulasi, dibuat untuk keperluan portofolio, dirancang menyerupai pola bisnis SaaS subscription agar analisisnya realistis. Bukan data perusahaan asli.
