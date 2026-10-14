# Data Dictionary - Kedai Renjana Budget & Cash Flow Planning

## Penjualan_Harian.csv (daily sales, 1,374 rows)
| Column | Type | Description |
|---|---|---|
| tanggal | date | Transaction date |
| outlet | text | "Renjana Utama" or "Renjana Kedua". Renjana Kedua only appears from 1 April 2024 (it had not opened before, this is not missing data) |
| jumlah_transaksi | number | Number of transactions that day. Blank (NaN) for Renjana Utama on 8-12 July 2024, see the Data Quality Notes in the Business Questions file |
| omzet | integer | Total revenue that day (IDR). 0 for Renjana Utama on 12-17 August 2024 (closed for renovation, not missing data) |

Note: 1-3 April 2024 (the first 3 days Renjana Kedua operated) appear twice in this file (duplicated rows), see the Data Quality Notes.

## Biaya_Bulanan.xlsx (monthly costs, 315 rows)
| Column | Type | Description |
|---|---|---|
| bulan | text (YYYY-MM) | Month the cost was recorded |
| outlet | text | "Renjana Utama" or "Renjana Kedua" |
| kategori_biaya | text | Bahan Baku (raw materials), Gaji (salary), Sewa (rent), Utilitas (utilities), Marketing, Maintenance, Lain-lain (other) |
| jumlah | integer | Cost amount (IDR) for that category and month. For Renjana Kedua in 2024-08 and 2024-09, Sewa (rent) was recorded under "Lain-lain", see the Data Quality Notes |

## Parameter_Asumsi.xlsx (assumption parameters, 18 rows)
| Column | Type | Description |
|---|---|---|
| parameter | text | Name of the assumption/parameter |
| nilai | text | The value or range of values for that assumption |
| keterangan | text | Additional context from Kirana about that assumption |

Contains, among other things: starting cash on 1 January 2024, the coffee bean price and estimated increase, capex and monthly rent for the two candidate locations of the new outlet, the ramp-up curve for each location, and estimated operating costs of the new outlet once mature. Some rows deliberately contain a range or "not yet decided" because that is exactly what needs to be discussed first, not a final number.

## Referensi_Outlet.xlsx (outlet reference, 4 rows)
| Column | Type | Description |
|---|---|---|
| outlet_id | text | PK |
| nama | text | Outlet/location name |
| lokasi | text | Location description |
| tipe | text | "Eksisting" (the 2 outlets already running) or "Kandidat" (the 2 candidate locations for the third outlet) |
| tanggal_mulai_operasi | text | Start of operation date for existing outlets, "TBD" for candidates |
| luas_m2 | number | Outlet area (m2) |
| kapasitas_duduk | number | Number of seats |
| catatan | text | Location characteristics relevant to weighing revenue potential |

## Relationships

```
Referensi_Outlet 1-N Penjualan_Harian    (via outlet name, only for type Eksisting)
Referensi_Outlet 1-N Biaya_Bulanan       (via outlet name, only for type Eksisting)
```

`Parameter_Asumsi.xlsx` has no direct key relationship; its contents are used as manual inputs to the projection/model sheet that will be built (it is not a transactional table). The historical data (`Penjualan_Harian`, `Biaya_Bulanan`) only covers the 2 existing outlets; the two candidate locations in `Referensi_Outlet` have no transaction history because they have not opened yet.
