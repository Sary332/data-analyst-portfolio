# Logistik & Delivery Performance: Kirim.in

**Category:** Operations / Logistics Analytics
**Tools:** SQL

## Headline
Bukan SLA yang Longgar atau Driver yang Malas: Satu Kota yang Bikin Seluruh Sistem Pengiriman Kelihatan Bermasalah

## Pertanyaan
Kenapa merchant mulai komplain soal keterlambatan pengiriman, dan apakah masalahnya ada di kota, driver, atau SLA yang tidak realistis?

## Yang Aku Lakukan
- Bersihin data: dedup baris ganda, normalisasi nama kota, backfill tanggal janji ke pelanggan yang kosong (dengan flag transparan biar bisa dilacak balik), perbaiki data berat paket yang salah input
- Nemuin dan benerin bug definisi SLA sendiri: awalnya diukur dari waktu order dibuat, bukan dari waktu pickup, jadi breach rate keukur 81% padahal harusnya sekitar 30%
- Bandingin dua definisi "telat" (SLA kontrak ke merchant vs tanggal janji ke pelanggan) buat tes seberapa kuat kesimpulannya
- Jalanin robustness check buat mastiin satu temuan bukan sekadar hasil dari asumsi cleaning sendiri
- Analisis silang driver x jenis kendaraan x berat paket buat nemuin pola di balik pengiriman gagal/retur

## KPI (3 angka)
1. Rasio order per driver di Bandung: 215, hampir 2x rata-rata kota lain (~122)
2. SLA breach rate Bandung 59% vs 21-25% di tiga kota lain
3. Fail/retur rate driver Motor dengan paket >12kg: 21% vs Van yang stabil di ~5% berapa pun beratnya

## Sparkline (opsional)
Tidak dipakai untuk project ini.

---

## Versi Archive (ringkas)
| Nama | Kategori | Tools | Ringkasan satu baris |
|---|---|---|---|
| Logistik & Delivery Performance | Operations / Logistics Analytics | SQL | Keterlambatan pengiriman Kirim.in didominasi kekurangan driver di satu kota (Bandung), bukan SLA merchant yang tidak realistis atau performa driver individual. |
