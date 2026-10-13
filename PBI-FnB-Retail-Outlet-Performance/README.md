# FnB Retail Outlet Performance: Kudapan Nusantara

## Business Problem
Kudapan Nusantara (perusahaan fiktif) mulai dari satu toko kecil di Depok tahun 2023, jualan es krim, popsicle, keripik buah, dan cemilan ringan. Dalam 18 bulan terakhir mereka ekspansi jadi 10 outlet di area Jabodetabek, campuran toko berdiri sendiri dan kios kecil di dalam mall atau pasar.

Operations Lead perusahaan cuma punya laporan revenue bulanan per outlet lewat WhatsApp, belum ada dashboard terpusat. Dia perlu tahu outlet mana yang performanya benar-benar bagus untuk mengarahkan keputusan ekspansi atau perbaikan. Masalahnya, "performa bagus" itu sendiri ambigu: dari sisi revenue, atau margin bersih setelah dikurangi produk yang terbuang (waste)? Dashboard ini dibangun untuk menjawab itu.

## Screenshot / Demo
**Overview (Ringkasan Semua Outlet)**
![Overview bagian atas](images/Overview%20P.a.png)
![Overview bagian bawah](images/Overview%20P.b.png)

**Outlet Deep Dive**
![Outlet Deep Dive bagian atas](images/Outlet%20Deep%20Dive%20P.a.png)
![Outlet Deep Dive bagian bawah](images/Outlet%20Deep%20Dive%20P.b.png)

## Approach
- Star schema: `fact_sales` dan `fact_waste`, dengan dimensi `dim_outlet`, `dim_product`, `dim_calendar`
- Waste dihitung berdasarkan cost produk (bukan harga jual), supaya nilainya mencerminkan kerugian riil, bukan potensi revenue yang hilang
- Ranking dan rata-rata perusahaan (revenue, waste, net margin) dihitung lintas seluruh outlet, dipakai sebagai pembanding tiap outlet individual
- Conditional formatting berbasis DAX measure, bukan cuma warna statis: badge di dashboard berubah teks, warna, dan icon-nya sesuai kondisi data outlet yang sedang dilihat

## Key Findings & Business Impact
- Revenue tinggi bukan jaminan untung. Satu outlet contoh ada di rank 4 dari 10 di revenue, tapi nilai waste-nya justru paling besar se-perusahaan dan net margin-nya cuma 9,7% (vs rata-rata perusahaan 29,5%). Ranking revenue dan ranking margin bisa kasih jawaban yang berbeda.
- Akar masalah outlet itu bukan salah jual produk. Komposisi kategori produknya nyaris identik dengan rata-rata perusahaan, beda di bawah 2 poin persentase di semua kategori. Breakdown alasan waste-nya justru didominasi "Meleleh" (sekitar 50%), jauh di atas kadaluarsa atau kemasan rusak, yang mengarah ke masalah cold storage.
- Secara company wide, waste memakan **28,9%** dari gross margin perusahaan (sekitar Rp 27,7Jt dari Rp 95,7Jt). Net margin susut dari 45,6% (gross) jadi 32,4% (net), gap 13,2 poin murni akibat waste, bukan kenaikan cost produk.
- Revenue kategori perishable (Es Krim dan Popsicle) punya pola musiman jelas, naik signifikan di musim kemarau dengan puncak di Juli 2024 dan Mei 2025. Berguna untuk perencanaan stok musiman.

## Fitur Dashboard
- 2 halaman: **Ringkasan Semua Outlet** (overview semua outlet dan tabel komparasi revenue/margin) dan **Outlet Deep Dive** (drill down 1 outlet, dipilih lewat slicer)
- KPI card dengan conditional formatting dinamis: teks, warna, dan icon berubah sesuai ambang batas data, bukan warna tetap
- Judul dan legend chart di halaman Deep Dive menyesuaikan nama outlet yang dipilih di slicer
- Edit Interactions dikonfigurasi manual di halaman Ringkasan supaya panel rekomendasi tidak ikut berubah saat slicer diklik, tetap jadi rekomendasi umum

## Struktur Repo
```
report/   → file .pbix
data/     → data mentah (fact_sales.csv, fact_waste.csv, dim_outlet.csv, dim_product.csv, dim_calendar.csv)
images/   → screenshot dashboard
```

## Cara Membuka
Download file dari folder `/report`, buka pakai Power BI Desktop versi terbaru (gratis, tidak butuh fitur Premium).

---

**Catatan:** Dataset ini adalah data simulasi, dibuat untuk keperluan portofolio, dirancang menyerupai pola bisnis retail F&B multi-outlet agar analisisnya realistis. Bukan data perusahaan asli.
