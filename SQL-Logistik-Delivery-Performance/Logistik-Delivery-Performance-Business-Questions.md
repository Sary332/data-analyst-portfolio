# Business Questions — Logistik & Delivery Performance

Urutan dari yang paling gampang ke yang paling perlu penalaran. Nggak wajib dikerjakan berurutan, tapi biasanya lebih enak dari atas ke bawah karena pertanyaan belakangan sering butuh hasil dari pertanyaan sebelumnya.

1. Berapa rata-rata durasi pengiriman (dari pickup sampai delivered) per kota? Kota mana yang paling lambat?

2. Dari semua pengiriman yang berhasil (`Delivered`), berapa persen yang melewati SLA jam yang dijanjikan ke merchant? Break down per kota.

3. Driver mana (dengan volume order yang cukup, misal minimal 20) yang punya rasio gagal/retur (`Failed`/`Returned`) tertinggi? Ada pola yang berhubungan dengan jenis kendaraan dan berat paket?

4. Merchant mana yang paling banyak menyumbang keterlambatan (berdasarkan SLA)? Apakah itu karena SLA merchant tersebut memang ketat, atau lebih karena faktor lain (kota tujuan, dll)?

5. **(Butuh klarifikasi ke stakeholder dulu)** Bandingkan tingkat keterlambatan pakai dua definisi berbeda: (a) lewat SLA jam dari waktu pickup, (b) lewat tanggal `promised_delivery_date` yang dijanjikan ke pelanggan. Apakah kesimpulan "merchant/kota mana yang paling bermasalah" berubah tergantung definisi yang dipakai? Hati-hati juga sama data yang `promised_delivery_date`-nya kosong — pastikan itu tidak ikut kehitung sebagai "tepat waktu".

6. Kalau Kirim.in cuma bisa nambah driver di **satu kota** tahun ini, kota mana yang paling butuh? Dukung jawabanmu dengan angka (rasio order per driver, tingkat keterlambatan, dan durasi rata-rata).

## Catatan Data Quality

Sebelum jawab pertanyaan di atas, cek dulu dan bersihkan:
- `deliveries.csv` punya baris duplikat persis (glitch scanner sekitar pertengahan Maret 2026).
- `deliveries.driver_id` kosong untuk sebagian pengiriman sebelum Januari 2026 (belum ada sistem assignment digital).
- `orders.customer_city` penulisannya tidak konsisten untuk order sebelum Maret 2026 (misal "jakarta", "DKI Jakarta", "Jakarta Pusat" — semuanya Jakarta).
- `orders.promised_delivery_date` kosong untuk satu merchant tertentu (integrasi API-nya belum lengkap).
- `orders.package_weight_kg` ada yang 0 atau negatif untuk satu merchant tertentu (salah konversi satuan di sistem lama mereka).
