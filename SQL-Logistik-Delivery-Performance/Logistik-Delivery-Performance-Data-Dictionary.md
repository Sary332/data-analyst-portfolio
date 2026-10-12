# Data Dictionary — Logistik & Delivery Performance

## merchants.csv (8 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| merchant_id | text | PK |
| merchant_name | text | Nama merchant partner |
| category | text | Kategori bisnis (Grocery, Electronics, Fashion, F&B, Beauty, Furniture) |
| sla_hours | integer | SLA kontrak, jam dari pickup sampai delivered |
| partner_since | date | Tanggal mulai kerja sama |

## drivers.csv (40 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| driver_id | text | PK |
| driver_name | text | Nama driver |
| city | text | Kota penempatan (sudah standar, tidak kotor) |
| vehicle_type | text | Motor / Van |
| join_date | date | Tanggal mulai kerja |

## orders.csv (5.400 baris)
| Kolom | Tipe | Keterangan |
|---|---|---|
| order_id | text | PK |
| merchant_id | text | FK ke merchants |
| customer_city | text | Kota tujuan pelanggan — **tidak konsisten** untuk order sebelum Maret 2026 |
| order_date | date | Tanggal order dibuat |
| package_weight_kg | float | Berat paket — ada nilai 0/negatif untuk merchant ElektroHome |
| promised_delivery_date | date | Tanggal yang dijanjikan ke pelanggan — **kosong** untuk merchant TokoBaru Fashion |

## deliveries.csv (~5.857 baris sebelum dedup)
| Kolom | Tipe | Keterangan |
|---|---|---|
| delivery_id | text | PK (ada duplikat persis di rentang 10–16 Maret 2026) |
| order_id | text | FK ke orders |
| driver_id | text | FK ke drivers — **kosong** untuk sebagian delivery sebelum Januari 2026 |
| attempt_number | integer | 1 = percobaan pertama, 2 = percobaan ulang setelah gagal |
| pickup_time | datetime | Waktu paket diambil driver |
| delivery_time | datetime | Waktu delivered (kosong kalau status Failed/Returned) |
| delivery_status | text | Delivered / Failed / Returned |

## Relasi
`merchants` 1—N `orders` 1—N `deliveries` N—1 `drivers`

Satu `order_id` bisa punya lebih dari satu baris di `deliveries` kalau percobaan pertama gagal (attempt_number 1 = Failed, attempt_number 2 = percobaan ulang).
