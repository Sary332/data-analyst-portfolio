# Data Dictionary - Kedai Renjana Budget & Cash Flow Planning

## Penjualan_Harian.csv (1.374 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| tanggal | date | Tanggal transaksi |
| outlet | text | "Renjana Utama" atau "Renjana Kedua". Renjana Kedua baru mulai muncul sejak 1 April 2024 (belum beroperasi sebelumnya, bukan data hilang) |
| jumlah_transaksi | number | Jumlah transaksi hari itu. Kosong (NaN) untuk Renjana Utama tanggal 8-12 Juli 2024, lihat Catatan Data Quality di file Business Questions |
| omzet | integer | Total omzet hari itu (IDR). Bernilai 0 untuk Renjana Utama tanggal 12-17 Agustus 2024 (tutup renovasi, bukan data hilang) |

Catatan: 1-3 April 2024 (3 hari pertama Renjana Kedua beroperasi) muncul dua kali di file ini (baris terduplikasi), lihat Catatan Data Quality.

## Biaya_Bulanan.xlsx (315 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| bulan | text (YYYY-MM) | Bulan pencatatan biaya |
| outlet | text | "Renjana Utama" atau "Renjana Kedua" |
| kategori_biaya | text | Bahan Baku, Gaji, Sewa, Utilitas, Marketing, Maintenance, Lain-lain |
| jumlah | integer | Nominal biaya (IDR) untuk kategori dan bulan itu. Untuk Renjana Kedua bulan 2024-08 dan 2024-09, biaya Sewa tercatat masuk kategori "Lain-lain", lihat Catatan Data Quality |

## Parameter_Asumsi.xlsx (18 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| parameter | text | Nama asumsi/parameter |
| nilai | text | Nilai atau rentang nilai asumsi tersebut |
| keterangan | text | Konteks tambahan dari Kirana soal asumsi itu |

Berisi antara lain: kas awal per 1 Januari 2024, harga dan estimasi kenaikan kopi biji, capex dan sewa bulanan dua kandidat lokasi outlet baru, kurva ramp-up masing-masing lokasi, dan estimasi biaya operasional outlet baru saat matang. Beberapa baris sengaja berisi rentang atau "belum ditentukan" karena memang itu bagian yang perlu didiskusikan dulu, bukan angka final.

## Referensi_Outlet.xlsx (4 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| outlet_id | text | PK |
| nama | text | Nama outlet/lokasi |
| lokasi | text | Deskripsi lokasi |
| tipe | text | "Eksisting" (2 outlet yang sudah jalan) atau "Kandidat" (2 lokasi calon outlet ketiga) |
| tanggal_mulai_operasi | text | Tanggal mulai beroperasi untuk yang eksisting, "TBD" untuk kandidat |
| luas_m2 | number | Luas outlet |
| kapasitas_duduk | number | Jumlah kursi |
| catatan | text | Karakteristik lokasi yang relevan untuk mempertimbangkan potensi omzet |

## Relasi

```
Referensi_Outlet 1-N Penjualan_Harian    (lewat nama outlet, hanya untuk yang tipe Eksisting)
Referensi_Outlet 1-N Biaya_Bulanan       (lewat nama outlet, hanya untuk yang tipe Eksisting)
```

`Parameter_Asumsi.xlsx` tidak berelasi langsung lewat key, isinya dipakai sebagai input manual ke sheet proyeksi/model yang akan dibangun (bukan tabel transaksional). Data historis (`Penjualan_Harian`, `Biaya_Bulanan`) cuma mencakup 2 outlet eksisting, dua kandidat lokasi di `Referensi_Outlet` belum punya riwayat transaksi karena memang belum dibuka.
