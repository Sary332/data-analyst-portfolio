/*
    SaaS_Subscription_Churn_Analysis
    Create schema + import data from data folder (CSV files)

    Target : SQL Server (localhost\SQLEXPRESS)
    Source : D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\ (customers, plans, subscriptions, subscription_events, payments, support_tickets)

    Catatan:
    - BULK INSERT dijalankan oleh service SQL Server (butuh akses read ke folder data\ di atas dari service account, mis. NT SERVICE\MSSQL$SQLEXPRESS$INSTANCE).
      Kalau service tidak punya akses, akan muncul error "Access is denied" atau "Cannot obtain the required interface (IID_IColumnsInfo)...".
    - Opsi FORMAT='CSV' + FIELDQUOTE sempat gagal dengan error IID_IColumnsInfo di instance ini (SQL Server 2022 Express), jadi dipakai FIELDTERMINATOR/
      ROWTERMINATOR manual sebagai gantinya. Data sumber tidak ada field yang mengandung koma/tanda kutip, jadi aman dipakai delimiter biasa.
    - payments.csv punya 11 baris duplikat persis (payment_id + semua kolom sama). Di-load ke staging table dulu lalu di-dedupe dengan SELECT DISTINCT supaya
      tidak double-count revenue.

    Daftar isi:
    1. Database Setup
    2. Schema (Table Definitions)
    3. Import (BULK INSERT dari CSV)
    4. Verification
    5. Data Cleaning
    6. Analysis (Business Questions)
*/

-- ============================================================
-- 1. DATABASE SETUP
-- ============================================================

-- 1.1 Create database (idempotent)
USE master;
GO
IF DB_ID('SaaS_Subscription_Churn_Analysis') IS NULL
    CREATE DATABASE SaaS_Subscription_Churn_Analysis;
GO

USE SaaS_Subscription_Churn_Analysis;
GO

-- 1.2 Drop existing tables (reset ke skema bersih)
IF OBJECT_ID('dbo.subscription_events', 'U') IS NOT NULL DROP TABLE dbo.subscription_events;
IF OBJECT_ID('dbo.support_tickets', 'U') IS NOT NULL DROP TABLE dbo.support_tickets;
IF OBJECT_ID('dbo.payments', 'U') IS NOT NULL DROP TABLE dbo.payments;
IF OBJECT_ID('dbo.payments_staging', 'U') IS NOT NULL DROP TABLE dbo.payments_staging;
IF OBJECT_ID('dbo.subscriptions', 'U') IS NOT NULL DROP TABLE dbo.subscriptions;
IF OBJECT_ID('dbo.customers', 'U') IS NOT NULL DROP TABLE dbo.customers;
IF OBJECT_ID('dbo.plans', 'U') IS NOT NULL DROP TABLE dbo.plans;
GO

-- ============================================================
-- 2. SCHEMA (TABLE DEFINITIONS)
-- ============================================================

-- 2.1 customers
CREATE TABLE dbo.customers (
    customer_id          varchar(10)   NOT NULL PRIMARY KEY,
    company_name         nvarchar(150) NOT NULL,
    industry             nvarchar(100) NULL,
    country               nvarchar(100) NULL,
    acquisition_channel   nvarchar(100) NULL,
    signup_date           date          NOT NULL
);
GO

-- 2.2 plans
CREATE TABLE dbo.plans (
    plan_id       varchar(10)   NOT NULL PRIMARY KEY,
    plan_name     nvarchar(50)  NOT NULL,
    tier_rank     int           NOT NULL,
    monthly_price decimal(10,2) NOT NULL,
    annual_price  decimal(10,2) NOT NULL
);
GO

-- 2.3 subscriptions
CREATE TABLE dbo.subscriptions (
    subscription_id varchar(10)  NOT NULL PRIMARY KEY,
    customer_id     varchar(10)  NOT NULL REFERENCES dbo.customers(customer_id),
    plan_id         varchar(10)  NOT NULL REFERENCES dbo.plans(plan_id),
    billing_cycle   nvarchar(20) NOT NULL,
    start_date      date         NOT NULL,
    end_date        date         NULL,
    status          nvarchar(20) NOT NULL
);
GO

-- 2.4 subscription_events
CREATE TABLE dbo.subscription_events (
    event_id        varchar(10)  NOT NULL PRIMARY KEY,
    subscription_id varchar(10)  NOT NULL REFERENCES dbo.subscriptions(subscription_id),
    event_date      date         NOT NULL,
    event_type      nvarchar(30) NOT NULL,
    old_plan_id     varchar(10)  NULL REFERENCES dbo.plans(plan_id),
    new_plan_id     varchar(10)  NULL REFERENCES dbo.plans(plan_id)
);
GO

-- 2.5 payments
CREATE TABLE dbo.payments (
    payment_id      varchar(10)   NOT NULL PRIMARY KEY,
    subscription_id varchar(10)   NOT NULL REFERENCES dbo.subscriptions(subscription_id),
    payment_date    date          NOT NULL,
    amount          decimal(10,2) NOT NULL,
    status          nvarchar(20)  NOT NULL
);
GO

-- 2.6 support_tickets
CREATE TABLE dbo.support_tickets (
    ticket_id     varchar(10)  NOT NULL PRIMARY KEY,
    customer_id   varchar(10)  NOT NULL REFERENCES dbo.customers(customer_id),
    created_date  date         NOT NULL,
    resolved_date date         NULL,
    category      nvarchar(50) NOT NULL,
    priority      nvarchar(20) NOT NULL
);
GO

-- ============================================================
-- 3. IMPORT (BULK INSERT dari CSV)
-- ============================================================

-- 3.1 customers
BULK INSERT dbo.customers
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\customers.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

-- 3.2 plans
BULK INSERT dbo.plans
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\plans.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

-- 3.3 subscriptions
BULK INSERT dbo.subscriptions
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\subscriptions.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

-- 3.4 subscription_events
BULK INSERT dbo.subscription_events
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\subscription_events.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

-- 3.5 support_tickets
BULK INSERT dbo.support_tickets
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\support_tickets.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

-- 3.6 payments (staging table + dedupe insert, lihat catatan di atas)
CREATE TABLE dbo.payments_staging (
    payment_id      varchar(10)   NOT NULL,
    subscription_id varchar(10)   NOT NULL,
    payment_date    date          NOT NULL,
    amount          decimal(10,2) NOT NULL,
    status          nvarchar(20)  NOT NULL
);
GO

BULK INSERT dbo.payments_staging
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\payments.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

INSERT INTO dbo.payments (payment_id, subscription_id, payment_date, amount, status)
SELECT DISTINCT payment_id, subscription_id, payment_date, amount, status
FROM dbo.payments_staging;
GO

DROP TABLE dbo.payments_staging;
GO

-- ============================================================
-- 4. VERIFICATION
-- ============================================================

-- 4.1 Row count per table
SELECT 'customers' AS tbl, COUNT(*) AS rows FROM dbo.customers
UNION ALL SELECT 'plans', COUNT(*) FROM dbo.plans
UNION ALL SELECT 'subscriptions', COUNT(*) FROM dbo.subscriptions
UNION ALL SELECT 'subscription_events', COUNT(*) FROM dbo.subscription_events
UNION ALL SELECT 'payments', COUNT(*) FROM dbo.payments
UNION ALL SELECT 'support_tickets', COUNT(*) FROM dbo.support_tickets;
GO

-- ============================================================
-- 5. DATA CLEANING
-- ============================================================

-- 5.1 payments — baris duplikat persis
/*
    payments.csv punya 11 baris duplikat persis (semua kolom sama). Sudah ditangani di 3.6 (staging table + INSERT ... SELECT DISTINCT)
    supaya baris duplikat tidak double-count revenue.

    Verifikasi: seluruh 11 baris duplikat itu jatuh di payment_date Februari 2025 (03-27 Feb 2025), tidak ada di bulan lain. Query di
    bawah membaca ulang payments.csv mentah (sebelum dedupe) ke temp table untuk membuktikannya - dbo.payments di database sudah bersih.
*/
IF OBJECT_ID('tempdb..#payments_raw') IS NOT NULL DROP TABLE #payments_raw;
CREATE TABLE #payments_raw (
    payment_id      varchar(10)   NOT NULL,
    subscription_id varchar(10)   NOT NULL,
    payment_date    date          NOT NULL,
    amount          decimal(10,2) NOT NULL,
    status          nvarchar(20)  NOT NULL
);
GO

BULK INSERT #payments_raw
FROM 'D:\Claude Cowork\Outputs\Project-Brief-Generator\SaaS-Subscription-Churn-Analysis\data\payments.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);
GO

-- Baris duplikat persis (semua kolom sama), dikelompokkan per bulan
SELECT FORMAT(payment_date, 'yyyy-MM') AS bulan, COUNT(*) AS jumlah_baris_duplikat
FROM (
    SELECT payment_id, subscription_id, payment_date, amount, status
    FROM #payments_raw
    GROUP BY payment_id, subscription_id, payment_date, amount, status
    HAVING COUNT(*) > 1
) d
GROUP BY FORMAT(payment_date, 'yyyy-MM')
ORDER BY bulan;
GO

DROP TABLE #payments_raw;
GO

-- 5.2 customers.acquisition_channel — normalisasi variasi penulisan channel
/*
    REVISI: versi awal section ini (pakai LOWER(acquisition_channel) IN (...) dan guard "acquisition_channel <> 'Paid Ads'", WHERE signup_date 
    < '2025-01-01') ternyata PUNYA BUG dan tidak lengkap membersihkan datanya -- ketahuan pas mengerjakan 6.5, di mana muncul baris "paid ads" (huruf
    kecil) dan "REFERRAL" (huruf besar semua) yang seharusnya sudah bersih. Root cause (dua hal sekaligus):
     
      1) Setiap query "inventarisasi varian" yang dipakai buat nemuin daftar nilai acquisition_channel selama ini pakai GROUP BY biasa -- dan
         collation default kolom ini CASE-INSENSITIVE, jadi varian huruf besar/kecil ("Organic Search" vs "organic search") DIGABUNG jadi
         satu baris tanpa kelihatan campurannya. Variasi case jadi tidak pernah masuk daftar temuan sejak awal.
      
      2) Guard "acquisition_channel <> 'Paid Ads'" di versi awal JUGA kena collation case-insensitive yang sama -- 'paid ads' <> 'Paid Ads'
         dievaluasi FALSE (dianggap SAMA), jadi baris 'paid ads' malah ke-SKIP oleh guard yang harusnya cuma mencegah update sia-sia.
    
    Dikonfirmasi lewat GROUP BY acquisition_channel COLLATE Latin1_General_CS_AS (memaksa case-sensitive): ketemu 22 baris case-variant (semuanya
    signup_date < 2025-01-01): content/social(1), organic search(6), paid ads(7), referral(3), REFERRAL(5).

    Perbaikan: satu UPDATE, satu definisi "stripped" (lowercase + buang spasi/underscore/slash) dipakai konsisten untuk SEMUA grup (termasuk
    Referral yang sebelumnya tidak pernah masuk pengecekan sama sekali), dan guard "sudah berubah atau belum" dipaksa COLLATE ...CS_AS supaya
    tidak kena bug yang sama lagi. WHERE signup_date dihapus (tidak dibatasi ke pre-2025 lagi) karena terbukti asumsi "data >=2025-01-01
    sudah bersih" itu sendiri cuma hasil GROUP BY case-insensitive yang menyesatkan -- lebih aman cek seluruh tabel.
*/
;WITH mapped AS (
    SELECT customer_id, acquisition_channel AS original,
           LOWER(REPLACE(REPLACE(REPLACE(acquisition_channel, ' ', ''), '_', ''), '/', '')) AS stripped
    FROM dbo.customers
),
canonical AS (
    SELECT customer_id, original,
        CASE stripped
            WHEN 'paidads'          THEN 'Paid Ads'
            WHEN 'organic'          THEN 'Organic Search'
            WHEN 'organicsearch'    THEN 'Organic Search'
            WHEN 'partner'          THEN 'Partner/Reseller'
            WHEN 'partnerreseller'  THEN 'Partner/Reseller'
            WHEN 'content'          THEN 'Content/Social'
            WHEN 'contentsocial'    THEN 'Content/Social'
            WHEN 'social'           THEN 'Content/Social'
            WHEN 'referral'         THEN 'Referral'
        END AS canonical_value
    FROM mapped
)
UPDATE c
SET acquisition_channel = ca.canonical_value
FROM dbo.customers c
JOIN canonical ca ON ca.customer_id = c.customer_id
WHERE ca.canonical_value IS NOT NULL
  AND ca.canonical_value COLLATE Latin1_General_CS_AS <> ca.original COLLATE Latin1_General_CS_AS;
GO

-- Verifikasi: paksa case-sensitive collation, harus cuma tersisa 5 nilai baku
SELECT acquisition_channel COLLATE Latin1_General_CS_AS AS literal_value, COUNT(*) AS cnt
FROM dbo.customers
GROUP BY acquisition_channel COLLATE Latin1_General_CS_AS
ORDER BY literal_value;
GO

-- 5.3 payments.amount — nilai negatif (refund) & status yang tidak konsisten
/*
    amount BISA negatif: itu representasi refund. Mayoritas refund sudah diberi status='refunded' dengan benar, TAPI ada refund lama (payment_date
    sebelum Maret 2025) yang statusnya masih 'success' bukan 'refunded' - kemungkinan karena kolom status belum diupdate saat proses refund lama
    dilakukan secara manual/di luar sistem.

    Implikasi untuk MRR/revenue: JANGAN filter refund pakai status='refunded' saja, karena baris lama itu akan lolos sebagai 'success'. Pilih salah satu
    pendekatan sesuai pertanyaan yang mau dijawab:
      a) Net revenue/MRR (revenue setelah refund)   -> SUM(amount) apa adanya,
         tanpa exclude apapun - nilai negatif otomatis mengurangi total,
         tidak peduli status-nya 'success' atau 'refunded'.
      b) Gross revenue/bookings (sebelum refund)     -> filter WHERE amount > 0,
         JANGAN pakai status='success' karena akan ikut memasukkan baris
         refund lama yang masih berlabel 'success'.
      c) Laporan/daftar refund tersendiri            -> filter WHERE amount < 0,
         JANGAN pakai status='refunded' karena akan melewatkan 8 baris refund
         lama yang masih berlabel 'success'.

    Kolom status TIDAK diubah di sini (butuh konfirmasi apakah baris lama itu refund asli atau data entry error) - lihat hasil query verifikasi di bawah.
*/
SELECT status, COUNT(*) AS jumlah_baris,
       SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END) AS jumlah_negatif,
       MIN(amount) AS amount_min, MAX(amount) AS amount_max
FROM dbo.payments
GROUP BY status
ORDER BY status;
GO

-- Baris "aneh": status masih 'success' padahal amount negatif (refund lama)
SELECT payment_id, subscription_id, payment_date, amount, status
FROM dbo.payments
WHERE amount < 0 AND status = 'success'
ORDER BY payment_date;
GO

-- 5.4 subscriptions.end_date — kosong untuk sebagian subscription cancelled lama
/*
    Benar: end_date NULL hanya terjadi pada subscription yang cancel sebelum Januari 2025 (6 dari 460 subscription cancelled), dan status-nya tetap
    'cancelled' - jangan dianggap aktif hanya karena end_date NULL.

    TAPI ada koreksi: tanggal cancel-nya SEBENARNYA tidak sepenuhnya "tidak diketahui" - subscription_events (event_type='cancel') menyimpan
    event_date untuk keenam subscription ini. Yang hilang cuma end_date di tabel subscriptions, bukan datanya secara keseluruhan. Untuk analisis
    yang butuh tanggal berakhir (mis. tenure, cohort retention), pakai COALESCE(s.end_date, cancel_event.event_date) lewat JOIN ke
    subscription_events, jangan treat sebagai benar-benar unknown.

*/
SELECT s.subscription_id, s.customer_id, s.plan_id, s.start_date, s.end_date,
       s.status, e.event_date AS cancel_event_date
FROM dbo.subscriptions s
LEFT JOIN dbo.subscription_events e
       ON e.subscription_id = s.subscription_id AND e.event_type = 'cancel'
WHERE s.status = 'cancelled' AND s.end_date IS NULL
ORDER BY s.subscription_id;
GO

-- 5.5 subscription_events.old_plan_id — kosong untuk event sebelum Januari 2025
/*
    Benar: old_plan_id NULL untuk SEMUA 15 event dengan event_date sebelum 2025-01-01 (13 cancel + 2 upgrade), dan TERISI untuk semua 565 event
    dari 2025-01-01 ke atas - potongan bersih di tanggal itu, bukan random. Kemungkinan sistem sumber baru mulai mencatat old_plan_id per Januari
    2025. Tidak ada event 'downgrade' sebelum 2025 sama sekali.

    Catatan: new_plan_id NULL untuk semua event 'cancel' (di periode manapun) itu wajar secara semantik - cancel tidak pindah ke plan baru - bukan
    data quality issue.
*/
SELECT
    CASE WHEN event_date < '2025-01-01' THEN 'before_2025' ELSE 'from_2025' END AS periode,
    COUNT(*) AS jumlah_event,
    SUM(CASE WHEN old_plan_id IS NULL THEN 1 ELSE 0 END) AS old_plan_id_null,
    SUM(CASE WHEN new_plan_id IS NULL THEN 1 ELSE 0 END) AS new_plan_id_null
FROM dbo.subscription_events
GROUP BY CASE WHEN event_date < '2025-01-01' THEN 'before_2025' ELSE 'from_2025' END
ORDER BY periode;
GO

-- Rincian per event_type supaya kelihatan pola per jenis event
SELECT
    event_type,
    CASE WHEN event_date < '2025-01-01' THEN 'before_2025' ELSE 'from_2025' END AS periode,
    COUNT(*) AS jumlah_event,
    SUM(CASE WHEN old_plan_id IS NULL THEN 1 ELSE 0 END) AS old_plan_id_null
FROM dbo.subscription_events
GROUP BY event_type, CASE WHEN event_date < '2025-01-01' THEN 'before_2025' ELSE 'from_2025' END
ORDER BY event_type, periode;
GO

-- ============================================================
-- 6. ANALYSIS (BUSINESS QUESTIONS)
-- ============================================================
/*
    Urutan & isi pertanyaan mengikuti SaaS-Subscription-Churn-Analysis-Business-Questions.md.
    6.1 Total active customers & MRR per Agustus 2026 + tren 6 bulan
    6.2 Logo churn rate per bulan
    6.3 Revenue churn rate per bulan (vs logo churn rate)
    6.4 Pola downgrade (plan asal -> plan tujuan, tren waktu)
    6.5 Early churn (90 hari) per acquisition_channel x tier plan (uji teori Ayu)
    6.6 Involuntary churn: payment gagal -> cancel dalam 30 hari (uji teori Hendra)
    6.7 Waktu resolusi support ticket: churn vs bertahan (uji teori Rangga)
    6.8 Sintesis tiga teori (butuh klarifikasi ke stakeholder)
*/

-- 6.1 Total active customers & MRR per Agustus 2026 + tren 6 bulan
/*
    "Aktif" ditentukan dari tanggal (start_date/end_date), BUKAN cuma kolom status, supaya angka tiap bulan di masa lalu akurat (status cuma simpan
    keadaan TERAKHIR/sekarang, bukan riwayat per bulan). Untuk 6 subscription yang end_date-nya NULL padahal status='cancelled' (lihat 5.4), effective
    end date diambil dari subscription_events (event_type='cancel').

    MRR per subscription aktif = monthly_price (billing_cycle='Monthly') atau annual_price/12.0 (billing_cycle='Annual'), pakai plan_id TERKINI
    di tabel subscriptions. Simplifikasi: kalau subscription pernah upgrade/downgrade DI DALAM salah satu dari 6 bulan ini, angka bulan-bulan
    sebelum perubahan plan bisa sedikit meleset (pakai plan terkini, bukan plan yang berlaku saat itu) -- histori plan per bulan ditangani terpisah
    di 6.4 (pola downgrade), bukan di sini.

    Snapshot bulanan pakai akhir bulan (mis. 2026-03-31) sebagai titik "aktif per tanggal itu": start_date <= akhir_bulan AND (effective_end_date
    IS NULL OR effective_end_date > akhir_bulan).

    "Customer aktif" dihitung DISTINCT customer_id (bukan jumlah baris subscription) karena satu customer bisa punya lebih dari satu
    subscription_id (lihat data dictionary).
*/
;WITH cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events
    WHERE event_type = 'cancel'
    GROUP BY subscription_id
),
sub_effective AS (
    SELECT
        s.subscription_id, s.customer_id, s.plan_id, s.billing_cycle, s.start_date,
        COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
months(month_end) AS (
    SELECT CAST('2026-03-31' AS date)
    UNION ALL SELECT CAST('2026-04-30' AS date)
    UNION ALL SELECT CAST('2026-05-31' AS date)
    UNION ALL SELECT CAST('2026-06-30' AS date)
    UNION ALL SELECT CAST('2026-07-31' AS date)
    UNION ALL SELECT CAST('2026-08-31' AS date)
),
monthly AS (
    SELECT
        m.month_end,
        COUNT(DISTINCT se.customer_id) AS active_customers,
        SUM(CASE WHEN se.billing_cycle = 'Monthly' THEN p.monthly_price
                 ELSE CAST(p.annual_price / 12.0 AS decimal(10,2)) END) AS mrr
    FROM months m
    JOIN sub_effective se
         ON se.start_date <= m.month_end
        AND (se.effective_end_date IS NULL OR se.effective_end_date > m.month_end)
    JOIN dbo.plans p ON p.plan_id = se.plan_id
    GROUP BY m.month_end
)
SELECT
    month_end,
    active_customers,
    mrr,
    active_customers - LAG(active_customers) OVER (ORDER BY month_end) AS delta_customers,
    mrr - LAG(mrr) OVER (ORDER BY month_end) AS delta_mrr
FROM monthly
ORDER BY month_end;
GO

/*
    TEMUAN 6.1:
    - Per Agustus 2026: 634 active customers, MRR $21,060.00.
    - Tren 6 bulan (Mar-Agu 2026): active customers naik terus tiap bulan (566 -> 585 -> 596 -> 614 -> 617 -> 634), MRR juga naik di 5 dari 6
      bulan. Dua metrik ini pada umumnya BERGERAK SEARAH.
    - Pengecualian: Mei 2026 -- active customers naik (+11) tapi MRR justru turun tipis (-45.00). Artinya di bulan itu ada downgrade dan/atau
      churn dari customer tier lebih tinggi yang nilainya menutupi pertumbuhan dari customer baru/tier rendah. Perlu ditelusuri lebih
      lanjut di 6.4 (pola downgrade) dan 6.3 (revenue churn rate).
*/

-- 6.0 Helper: vw_month_calendar
/*
    View kecil buat generate kalender akhir bulan dari September 2024 (bulan pertama di data) sampai Agustus 2026 (bulan terakhir/"sekarang").
    Dipindah ke sini karena 6.2 dan 6.3 tadinya nulis ulang CTE rekursif yang identik persis -- daripada copy-paste terus di tiap query bulanan
    berikutnya, dijadikan satu VIEW yang di-reference semua.
*/
IF OBJECT_ID('dbo.vw_month_calendar', 'V') IS NOT NULL DROP VIEW dbo.vw_month_calendar;
GO
CREATE VIEW dbo.vw_month_calendar AS
WITH month_calendar AS (
    SELECT CAST('2024-09-01' AS date) AS month_start
    UNION ALL
    SELECT DATEADD(MONTH, 1, month_start) FROM month_calendar WHERE month_start < '2026-08-01'
)
SELECT EOMONTH(month_start) AS month_end FROM month_calendar;
GO

-- 6.2 Logo churn rate per bulan
/*
    logo_churn_rate(bulan M) = jumlah customer yang aktif di akhir bulan M-1 TAPI tidak lagi aktif di akhir bulan M / jumlah customer aktif di akhir
    bulan M-1. Dihitung di level CUSTOMER (bukan subscription) supaya customer dengan >1 subscription yang salah satunya cancel tapi
    subscription lain masih aktif TIDAK ikut terhitung churn -- konsisten dengan cara active_customers dihitung di 6.1 (pakai effective_end_date
    yang sama dari 5.4).

    Bulan pertama dalam data (September 2024) tidak punya bulan sebelumnya untuk jadi pembanding, jadi dilewati (churn rate mulai dihitung dari
    Oktober 2024). Kolom "catatan" menandai bulan dengan basis customer kecil (<100) di awal periode -- sesuai peringatan di business question,
    persentase di bulan-bulan ini gampang menyesatkan (mis. Oktober 2024: cuma 30 customer, 4 churn = 13.33%, padahal itu cuma 4 orang).
*/
;WITH months AS (
    SELECT month_end FROM dbo.vw_month_calendar
),
cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events
    WHERE event_type = 'cancel'
    GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id, s.customer_id, s.start_date,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
monthly_active_customers AS (
    SELECT DISTINCT m.month_end, se.customer_id
    FROM months m
    JOIN sub_effective se
        ON se.start_date <= m.month_end
       AND (se.effective_end_date IS NULL OR se.effective_end_date > m.month_end)
),
months_ordered AS (
    SELECT month_end, LAG(month_end) OVER (ORDER BY month_end) AS prev_month_end
    FROM months
),
churn_calc AS (
    SELECT
        mo.month_end,
        (SELECT COUNT(*) FROM monthly_active_customers a WHERE a.month_end = mo.prev_month_end) AS active_start,
        (SELECT COUNT(*)
           FROM monthly_active_customers a
          WHERE a.month_end = mo.prev_month_end
            AND NOT EXISTS (
                SELECT 1 FROM monthly_active_customers b
                 WHERE b.month_end = mo.month_end AND b.customer_id = a.customer_id
            )
        ) AS churned_customers
    FROM months_ordered mo
    WHERE mo.prev_month_end IS NOT NULL
)
SELECT
    month_end, active_start, churned_customers,
    CAST(churned_customers * 100.0 / NULLIF(active_start, 0) AS decimal(5,2)) AS logo_churn_rate_pct,
    CASE WHEN active_start < 100 THEN 'basis kecil (<100 customer)' END AS catatan
FROM churn_calc
ORDER BY month_end;
GO

/*
    TEMUAN 6.2:
    - Churn rate TERTINGGI secara angka mentah ada di Oktober 2024 (13.33%), TAPI ini basis kecil (cuma 30 customer, 4 churn) -- sesuai peringatan
      di business question, angka ini menyesatkan dan tidak reliable.
    - Kalau bulan basis-kecil (Okt-Des 2024, <100 customer) diabaikan, churn rate tertinggi yang RELIABLE ada di Juli 2026 (7.65%, dari 614 customer
      basis, 47 churn) -- bulan yang sama yang mengembalikan MRR gap dari 6.1 area sekitarnya (Mei-Jun 2026 turun MRR, lanjut Jul 2026 churn
      tinggi).
    - Pola lebih penting: ada TREN NAIK yang cukup jelas sepanjang 2026 -- dari ~5% (Jan 2026) ke 5.89% (Feb) turun sedikit ke 5.5-5.7% (Mar-Apr),
      naik ke 6.67% (Mei), turun ke 5.54% (Jun), lalu melonjak ke 7.65% (Jul) sebelum turun lagi ke 6.16% (Agu). Churn rate 2026 secara umum
      jauh lebih tinggi dibanding 2025 (yang mayoritas di bawah 5%, kadang di bawah 2%). Ini sinyal churn makin memburuk seiring waktu,
      bukan cuma fluktuasi bulanan biasa -- perlu jadi concern utama saat sintesis di 6.8.
*/

-- 6.3 Revenue churn rate per bulan (vs logo churn rate)
/*
    revenue_churn_rate(bulan M) = (MRR hilang dari cancellation di bulan M + MRR hilang dari downgrade di bulan M) / MRR di akhir bulan M-1.

    Balik ke simplifikasi "plan_id terkini" yang dicatat di 6.1 (sesuai reminder sebelumnya) -- di 6.3 ini TIDAK jadi masalah untuk bagian
    NUMERATOR:
      - MRR hilang dari CANCEL pakai subscriptions.plan_id + billing_cycle milik subscription yang cancel -- ini justru AKURAT karena
        plan_id di tabel subscriptions memang berarti "plan terakhir", dan untuk subscription yang sudah cancel, plan terakhir itu PAS
        plan yang berlaku waktu mereka berhenti bayar. Tidak ada distorsi.

      - MRR hilang dari DOWNGRADE pakai old_plan_id/new_plan_id LANGSUNG dari subscription_events (bukan plan_id di subscriptions sama
        sekali) -- jadi ini juga akurat per kejadian, bukan pendekatan.

    TAPI simplifikasi itu MASIH berlaku untuk DENOMINATOR (mrr_start, MRR di akhir bulan M-1): dihitung dari plan_id TERKINI tiap subscription
    yang aktif saat itu, bukan plan yang benar-benar berlaku di bulan M-1 kalau subscription itu baru upgrade/downgrade SETELAH bulan M-1.
    PENTING: ini bukan cuma masalah denominator di query 6.3 ini -- monthly_mrr yang kena efek ini adalah CTE yang sama polanya dengan yang
    dipakai di 6.1 (snapshot MRR 6 bulan terakhir), jadi 6.1 juga ikut kena simplifikasi ini, bukan cuma 6.3.

    Seberapa besar distorsinya: total MRR yang "berpindah" akibat semua downgrade sepanjang data (Mar 2025 - Agu 2026) = $3,300.00/bulan
    (jumlah kolom mrr_lost_downgrade di semua baris hasil query ini). Dibandingkan MRR terkini ~$21,060 (Agu 2026), itu batas ATAS teoritis
    ~15.7% -- dan itu SKENARIO TERBURUK (semua downgrade itu punya subscription yang masih aktif sekarang DAN semuanya numpuk di bulan paling
    awal, yang mana tidak terjadi di data ini karena downgrade tersebar dari Maret 2025 sampai Agustus 2026). Distorsi nyata di tiap bulan
    spesifik jauh lebih kecil dari 15.7% itu, dan mengecil terus mendekati bulan-bulan terbaru (bulan Agustus 2026 sendiri TIDAK kena distorsi
    sama sekali karena tidak ada downgrade "di masa depan"-nya untuk dibandingkan). Rekonstruksi penuh (plan yang benar-benar berlaku di tiap
    titik waktu, direkonstruksi dari urutan subscription_events pakai window function) akan menghilangkan distorsi ini sepenuhnya, tapi untuk
    besaran yang terbukti kecil ini (maks ~15.7%, biasanya jauh di bawah itu), effort tambahan itu belum sepadan untuk konteks project ini --
    disclosure kuantitatif ini dianggap cukup, bukan rekonstruksi penuh.

    Sama seperti 6.2, bulan pertama (September 2024) dilewati karena tidak ada bulan sebelumnya sebagai pembanding.
*/
;WITH months AS (
    SELECT month_end FROM dbo.vw_month_calendar
),
cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id, s.customer_id, s.plan_id, s.billing_cycle, s.start_date,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
sub_mrr AS (
    SELECT se.*,
           CASE WHEN se.billing_cycle = 'Monthly' THEN p.monthly_price
                ELSE CAST(p.annual_price / 12.0 AS decimal(10,2)) END AS mrr_value
    FROM sub_effective se
    JOIN dbo.plans p ON p.plan_id = se.plan_id
),
monthly_mrr AS (
    SELECT m.month_end, SUM(sm.mrr_value) AS mrr
    FROM months m
    JOIN sub_mrr sm
        ON sm.start_date <= m.month_end
       AND (sm.effective_end_date IS NULL OR sm.effective_end_date > m.month_end)
    GROUP BY m.month_end
),
mrr_lost_cancel AS (
    SELECT EOMONTH(sm.effective_end_date) AS month_end, SUM(sm.mrr_value) AS mrr_lost_cancel
    FROM sub_mrr sm
    WHERE sm.effective_end_date IS NOT NULL
    GROUP BY EOMONTH(sm.effective_end_date)
),
mrr_lost_downgrade AS (
    SELECT EOMONTH(e.event_date) AS month_end,
           SUM(
               (CASE WHEN s.billing_cycle = 'Monthly' THEN p_old.monthly_price ELSE CAST(p_old.annual_price / 12.0 AS decimal(10,2)) END)
             - (CASE WHEN s.billing_cycle = 'Monthly' THEN p_new.monthly_price ELSE CAST(p_new.annual_price / 12.0 AS decimal(10,2)) END)
           ) AS mrr_lost_downgrade
    FROM dbo.subscription_events e
    JOIN dbo.subscriptions s ON s.subscription_id = e.subscription_id
    JOIN dbo.plans p_old ON p_old.plan_id = e.old_plan_id
    JOIN dbo.plans p_new ON p_new.plan_id = e.new_plan_id
    WHERE e.event_type = 'downgrade'
    GROUP BY EOMONTH(e.event_date)
),
months_ordered AS (
    SELECT month_end, LAG(month_end) OVER (ORDER BY month_end) AS prev_month_end
    FROM months
)
SELECT
    mo.month_end,
    mm_prev.mrr AS mrr_start,
    ISNULL(lc.mrr_lost_cancel, 0) AS mrr_lost_cancel,
    ISNULL(ld.mrr_lost_downgrade, 0) AS mrr_lost_downgrade,
    CAST((ISNULL(lc.mrr_lost_cancel, 0) + ISNULL(ld.mrr_lost_downgrade, 0)) * 100.0 / NULLIF(mm_prev.mrr, 0) AS decimal(5,2)) AS revenue_churn_rate_pct
FROM months_ordered mo
LEFT JOIN monthly_mrr mm_prev ON mm_prev.month_end = mo.prev_month_end
LEFT JOIN mrr_lost_cancel lc ON lc.month_end = mo.month_end
LEFT JOIN mrr_lost_downgrade ld ON ld.month_end = mo.month_end
WHERE mo.prev_month_end IS NOT NULL
ORDER BY mo.month_end;
GO

/*
    TEMUAN 6.3:
    - Sampai sekitar Juli 2025, logo churn rate (6.2) dan revenue churn rate saling berdekatan / kadang revenue lebih rendah -- dua definisi churn
      ini cerita HAMPIR SAMA di periode ini (dengan satu outlier: Desember 2024, 1.08% logo vs 10.33% revenue -- tapi ini bulan basis kecil juga,
      jadi kemungkinan cuma 1 customer tier tinggi/annual yang cancel).

    - MULAI Agustus 2025, revenue churn rate KONSISTEN lebih tinggi dari logo churn rate, dan gap-nya melebar -- Agu 2025 (2.47% vs 4.76%),
      Sep 2025 (3.31% vs 5.98%), Nov 2025 (3.45% vs 7.38%), berlanjut sampai Apr 2026 (5.65% vs 8.79%). Artinya sejak pertengahan 2025, customer
      yang churn (atau downgrade) CENDERUNG bernilai lebih tinggi (tier lebih mahal / annual) dibanding rata-rata customer aktif -- kerugian
      revenue lebih parah daripada yang terlihat dari sekadar jumlah customer yang hilang.
    
    - Dua definisi churn TIDAK selalu cerita yang sama sejak ~Agustus 2025 -- revenue churn rate adalah sinyal yang lebih mengkhawatirkan untuk
      periode itu ke depan, dan seharusnya jadi metrik utama, bukan cuma logo churn rate.
*/

-- 6.4 Pola downgrade (plan asal -> plan tujuan, tren waktu)
/*
    Tiga query:
    a) Transisi downgrade: dari plan mana ke plan mana, dan berapa kali.
    b) Tren jumlah downgrade per bulan (pakai vw_month_calendar dari 6.0).
    c) Gabungan: jumlah downgrade per bulan vs gap (revenue_churn_pct -
       logo_churn_pct) dari 6.2/6.3, buat jawab "apakah downgrade yang
       menjelaskan gap di 6.3?" pakai bukti angka, bukan cuma dugaan.
*/

-- 6.4a Transisi downgrade
SELECT op.plan_name AS dari_plan, np.plan_name AS ke_plan, COUNT(*) AS jumlah_downgrade
FROM dbo.subscription_events e
JOIN dbo.plans op ON op.plan_id = e.old_plan_id
JOIN dbo.plans np ON np.plan_id = e.new_plan_id
WHERE e.event_type = 'downgrade'
GROUP BY op.plan_name, np.plan_name
ORDER BY jumlah_downgrade DESC;
GO

-- 6.4b Tren jumlah downgrade per bulan
SELECT mc.month_end, COUNT(e.event_id) AS jumlah_downgrade
FROM dbo.vw_month_calendar mc
LEFT JOIN dbo.subscription_events e
    ON EOMONTH(e.event_date) = mc.month_end AND e.event_type = 'downgrade'
GROUP BY mc.month_end
ORDER BY mc.month_end;
GO

-- 6.4c Downgrade vs gap logo/revenue churn (menjawab "apakah ini menjelaskan gap di 6.3?")
;WITH months AS (
    SELECT month_end FROM dbo.vw_month_calendar
),
cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id, s.customer_id, s.plan_id, s.billing_cycle, s.start_date,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
sub_mrr AS (
    SELECT se.*,
           CASE WHEN se.billing_cycle = 'Monthly' THEN p.monthly_price
                ELSE CAST(p.annual_price / 12.0 AS decimal(10,2)) END AS mrr_value
    FROM sub_effective se
    JOIN dbo.plans p ON p.plan_id = se.plan_id
),
monthly_active_customers AS (
    SELECT DISTINCT m.month_end, se.customer_id
    FROM months m
    JOIN sub_effective se
        ON se.start_date <= m.month_end
       AND (se.effective_end_date IS NULL OR se.effective_end_date > m.month_end)
),
monthly_mrr AS (
    SELECT m.month_end, SUM(sm.mrr_value) AS mrr
    FROM months m
    JOIN sub_mrr sm
        ON sm.start_date <= m.month_end
       AND (sm.effective_end_date IS NULL OR sm.effective_end_date > m.month_end)
    GROUP BY m.month_end
),
mrr_lost_cancel AS (
    SELECT EOMONTH(sm.effective_end_date) AS month_end, SUM(sm.mrr_value) AS mrr_lost_cancel
    FROM sub_mrr sm
    WHERE sm.effective_end_date IS NOT NULL
    GROUP BY EOMONTH(sm.effective_end_date)
),
mrr_lost_downgrade AS (
    SELECT EOMONTH(e.event_date) AS month_end,
           COUNT(*) AS jumlah_downgrade,
           SUM(
               (CASE WHEN s.billing_cycle = 'Monthly' THEN p_old.monthly_price ELSE CAST(p_old.annual_price / 12.0 AS decimal(10,2)) END)
             - (CASE WHEN s.billing_cycle = 'Monthly' THEN p_new.monthly_price ELSE CAST(p_new.annual_price / 12.0 AS decimal(10,2)) END)
           ) AS mrr_lost_downgrade
    FROM dbo.subscription_events e
    JOIN dbo.subscriptions s ON s.subscription_id = e.subscription_id
    JOIN dbo.plans p_old ON p_old.plan_id = e.old_plan_id
    JOIN dbo.plans p_new ON p_new.plan_id = e.new_plan_id
    WHERE e.event_type = 'downgrade'
    GROUP BY EOMONTH(e.event_date)
),
months_ordered AS (
    SELECT month_end, LAG(month_end) OVER (ORDER BY month_end) AS prev_month_end
    FROM months
),
logo_churn AS (
    SELECT
        mo.month_end,
        (SELECT COUNT(*) FROM monthly_active_customers a WHERE a.month_end = mo.prev_month_end) AS active_start,
        (SELECT COUNT(*)
           FROM monthly_active_customers a
          WHERE a.month_end = mo.prev_month_end
            AND NOT EXISTS (SELECT 1 FROM monthly_active_customers b WHERE b.month_end = mo.month_end AND b.customer_id = a.customer_id)
        ) AS churned_customers
    FROM months_ordered mo
    WHERE mo.prev_month_end IS NOT NULL
)
SELECT
    mo.month_end,
    ISNULL(ld.jumlah_downgrade, 0) AS jumlah_downgrade,
    CAST(lg.churned_customers * 100.0 / NULLIF(lg.active_start, 0) AS decimal(5,2)) AS logo_churn_pct,
    CAST((ISNULL(lc.mrr_lost_cancel, 0) + ISNULL(ld.mrr_lost_downgrade, 0)) * 100.0 / NULLIF(mm.mrr, 0) AS decimal(5,2)) AS revenue_churn_pct,
    CAST((ISNULL(lc.mrr_lost_cancel, 0) + ISNULL(ld.mrr_lost_downgrade, 0)) * 100.0 / NULLIF(mm.mrr, 0)
       - lg.churned_customers * 100.0 / NULLIF(lg.active_start, 0) AS decimal(5,2)) AS gap_pct
FROM months_ordered mo
JOIN logo_churn lg ON lg.month_end = mo.month_end
LEFT JOIN monthly_mrr mm ON mm.month_end = mo.prev_month_end
LEFT JOIN mrr_lost_cancel lc ON lc.month_end = mo.month_end
LEFT JOIN mrr_lost_downgrade ld ON ld.month_end = mo.month_end
WHERE mo.prev_month_end IS NOT NULL
ORDER BY mo.month_end;
GO

/*
    TEMUAN 6.4:
    - Transisi downgrade SANGAT terkonsentrasi: 68 dari 86 (79%) adalah Growth -> Starter, sisanya 18 (21%) Scale -> Growth. Tidak ada yang
      loncat 2 tier langsung (Scale -> Starter) -- downgrade selalu satu tingkat ke bawah.
    - Downgrade praktis TIDAK ADA sebelum Agustus 2025 (cuma 2 total dari Maret-Juli 2025), lalu naik tajam dan MENETAP di level tinggi sejak
      Agustus 2025 (2, 5, 5, 10, 10 di Agu-Des 2025, lanjut 4-12/bulan sepanjang 2026). Titik baliknya sangat jelas dan persis berbarengan
      dengan titik divergensi logo vs revenue churn rate di 6.3.

    - Query 6.4c mengonfirmasi ini BUKAN cuma kebetulan waktu: gap_pct (revenue churn - logo churn) NEGATIF atau mendekati nol di hampir
      semua bulan SEBELUM Agustus 2025 (kecuali Des 2024 dan Apr 2025, yang keduanya punya 0 downgrade bulan itu -- jadi gap di dua bulan itu
      MURNI dari cancel customer tier tinggi, bukan downgrade). Sejak Agustus 2025, gap_pct KONSISTEN positif (rata-rata ~1-4%) berbarengan
      dengan downgrade yang juga konsisten muncul tiap bulan.

    - JAWABAN ke business question: downgrade YANG MENINGKAT SEJAK AGUSTUS 2025 IKUT MENJELASKAN kenapa gap di 6.3 berubah dari "episodik" jadi
      "persisten" -- downgrade menciptakan kanal kerugian revenue yang sama sekali tidak kelihatan di logo churn (customer-nya tetap terhitung
      aktif, cuma bayar lebih murah). TAPI ini bukan satu-satunya penjelas: korelasinya tidak sempurna (mis. Feb 2026 downgrade lebih banyak dari
      Jan 2026 tapi gap-nya malah lebih kecil), dan cancellation customer tier tinggi tetap jadi kontributor dollar terbesar di hampir semua
      bulan (bandingkan mrr_lost_cancel vs mrr_lost_downgrade di 6.3). Kesimpulan: downgrade adalah PENAMBAH yang baru muncul sejak Agustus
      2025, bukan penyebab tunggal gap-nya.
*/

-- 6.5 Early churn (90 hari) per acquisition_channel x tier plan (uji teori Ayu)
/*
    "Early churn": subscription yang cancel dalam 90 hari sejak start_date-nya. Dihitung di level SUBSCRIPTION (bukan customer) karena yang diukur adalah
    "90 hari pertama subscription itu", dan tier plan awal-nya ikut subscription itu juga.

    initial_plan (plan AWAL, bukan plan sekarang): kalau subscription itu pernah upgrade/downgrade, ambil old_plan_id dari event PERTAMA (paling
    awal) -- itu plan sebelum perubahan pertama terjadi. Kalau tidak pernah berubah plan, plan sekarang (subscriptions.plan_id) = plan awal.
    Catatan kecil: 2 event upgrade sebelum Januari 2025 (lihat 5.5) punya old_plan_id NULL, jadi utk subscription itu (kalau memang tidak ada
    event lain) fallback ke plan_id sekarang -- berpotensi salah tier utk 2 subscription itu doang, dampaknya diabaikan.

    Sensor waktu (WAJIB, supaya adil): subscription yang start_date-nya KURANG dari 90 hari sebelum akhir data (2026-08-31) DIBUANG dari
    perhitungan -- kalau tidak, subscription yang baru mulai belum sempat "kesempatan" churn dalam 90 hari akan salah terhitung sebagai
    "tidak churn" padahal cuma belum genap waktunya diamati.

    Kolom se/ci95_low/ci95_high: interval kepercayaan 95% pakai pendekatan normal (Wald), se = sqrt(p*(1-p)/n). Ini pendekatan kasar (kurang
    akurat utk n kecil/p ekstrem dibanding interval Wilson), tapi cukup buat tujuan business question ini: kalau confidence interval dua
    channel TIDAK overlap, itu sinyal kuat bedanya bukan kebetulan; kalau overlap lebar (atau CI tembus ke negatif -- tanda n kekecilan buat
    pendekatan normal ini valid), jangan disimpulkan channel itu "beneran beda". Kolom "catatan" menandai n < 30 sebagai peringatan sampel kecil.
*/
;WITH cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id, s.customer_id, s.plan_id, s.start_date,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
first_change AS (
    SELECT subscription_id, old_plan_id, event_date,
           ROW_NUMBER() OVER (PARTITION BY subscription_id ORDER BY event_date) AS rn
    FROM dbo.subscription_events
    WHERE event_type IN ('upgrade', 'downgrade') AND old_plan_id IS NOT NULL
),
initial_plan AS (
    SELECT se.subscription_id, se.customer_id, se.start_date, se.effective_end_date,
           COALESCE(fc.old_plan_id, se.plan_id) AS initial_plan_id
    FROM sub_effective se
    LEFT JOIN first_change fc ON fc.subscription_id = se.subscription_id AND fc.rn = 1
),
cohort AS (
    SELECT
        ip.subscription_id,
        c.acquisition_channel,
        p.plan_name AS initial_plan,
        p.tier_rank,
        CASE WHEN ip.effective_end_date IS NOT NULL
                  AND ip.effective_end_date <= DATEADD(DAY, 90, ip.start_date)
             THEN 1 ELSE 0 END AS churned_90d
    FROM initial_plan ip
    JOIN dbo.customers c ON c.customer_id = ip.customer_id
    JOIN dbo.plans p ON p.plan_id = ip.initial_plan_id
    WHERE DATEADD(DAY, 90, ip.start_date) <= '2026-08-31'
)
SELECT
    acquisition_channel,
    initial_plan,
    tier_rank,
    COUNT(*) AS n,
    SUM(churned_90d) AS churned_90d,
    CAST(AVG(churned_90d * 1.0) AS decimal(5,4)) AS churn_rate,
    CAST(AVG(churned_90d * 1.0) - 1.96 * SQRT(AVG(churned_90d * 1.0) * (1 - AVG(churned_90d * 1.0)) / COUNT(*)) AS decimal(5,4)) AS ci95_low,
    CAST(AVG(churned_90d * 1.0) + 1.96 * SQRT(AVG(churned_90d * 1.0) * (1 - AVG(churned_90d * 1.0)) / COUNT(*)) AS decimal(5,4)) AS ci95_high,
    CASE WHEN COUNT(*) < 30 THEN 'sampel kecil (<30)' END AS catatan
FROM cohort
GROUP BY acquisition_channel, initial_plan, tier_rank
ORDER BY tier_rank, acquisition_channel;
GO

/*
    TEMUAN 6.5:
    - Tier Starter: Paid Ads churn rate 34.23% (n=111, CI95 [25.4%, 43.1%]) -- JAUH lebih tinggi dari channel lain di tier ini (Referral 17.71%,
      Organic Search 16.77%, Content/Social 14.29%, Partner/Reseller 4.82%). CI Paid Ads nyaris tidak overlap dengan channel manapun di
      tier ini (batas atas Referral 25.34% vs batas bawah Paid Ads 25.41%) -- dengan n yang cukup besar (semua channel n>=42), ini BUKAN
      kebetulan sampel kecil. Teori Ayu TERBUKTI KUAT di tier Starter.

    - Tier Growth: Paid Ads 20.24% (n=84) memang tertinggi, tapi CI-nya [11.7%, 28.8%] TUMPANG TINDIH LEBAR dengan Referral 19.35% (n=62,
      CI [9.5%,29.2%]) dan bahkan Content/Social 15.56%. Bedanya TIDAK cukup meyakinkan buat disimpulkan Paid Ads "beneran beda" di tier
      ini -- masih dalam rentang wajar variasi sampel.

    - Tier Scale: pola JUSTRU KEBALIK -- Paid Ads (8.70%, n=23) malah salah satu yang PALING RENDAH, sementara Organic Search (24.00%,
      n=25) paling tinggi. TAPI n di tier ini kecil semua (12-25) dan semua CI lebar/tumpang tindih (beberapa bahkan tembus negatif,
      tanda pendekatan normal sudah kurang valid di sini) -- pola "kebalikan" ini TIDAK BOLEH disimpulkan sebagai bukti kontra teori,
      cuma noise dari sampel kecil.

    - JAWABAN ke business question: teori Ayu ("Paid Ads churn lebih cepat") TERBUKTI, tapi SPESIFIK ke tier Starter saja -- bukan pola
      yang konsisten di semua tier. Ini insight yang lebih actionable daripada "Paid Ads jelek secara umum": masalahnya ada di kombinasi
      Paid Ads + Starter, kemungkinan customer entry-level yang direkrut lewat iklan berbayar kurang match/kurang di-onboard dengan baik,
      bukan masalah channel Paid Ads itu sendiri di semua segmen.
*/

-- 6.6 Involuntary churn: payment gagal -> cancel dalam 30 hari (uji teori Hendra)
/*
    Dua sudut pandang buat jawab dua bagian business question:
    a) FORWARD (per payment): dari SETIAP payment (failed atau success), apakah subscription-nya cancel dalam 30 hari setelah payment itu?
       Jawab "apakah polanya nyata" -- kalau rate 'failed' jauh lebih tinggi dari 'success', itu bukti involuntary churn nyata.
    
    b) BACKWARD (per subscription yang cancel): dari SEMUA subscription yang cancel, berapa persen yang punya failed payment dalam 30 hari
       SEBELUM cancel-nya? Jawab "seberapa besar kontribusinya ke total cancellation".

    Sensor waktu (6.6a): payment yang payment_date + 30 hari > akhir data (2026-08-31) dibuang -- sama seperti 6.5, supaya payment yang terlalu
    baru tidak salah terhitung "tidak menyebabkan cancel" padahal cuma belum genap waktunya diamati.

    Catatan metodologi (6.6a): dihitung per BARIS PAYMENT, bukan per subscription -- kalau satu subscription punya beberapa failed payment
    berturut-turut sebelum akhirnya cancel, tiap failed payment itu masing-masing dihitung sebagai 1 "percobaan". Ini bisa sedikit
    membesar-besarkan rate-nya dibanding kalau dihitung sekali per subscription, tapi given rate failed (61%) vs success (1.6%) beda
    ~38x lipat, efek double-counting ini jauh lebih kecil dari besarnya sinyal itu sendiri -- tidak mengubah kesimpulan.

    Catatan metodologi (6.6b) -- celah definisi "preceded by failure": EXISTS failed payment dalam 30 hari sebelum cancel TIDAK OTOMATIS
    berarti kegagalan itu yang menyebabkan cancel-nya -- bisa saja retry berikutnya SUKSES (payment pulih), tapi subscription tetap cancel
    belakangan karena alasan lain (voluntary). Dua definisi mungkin:

      - LONGGAR: ada failed payment dalam window, titik (tidak peduli apakah pulih sesudahnya atau tidak).
      - KETAT (dipakai di bawah): ada failed payment dalam window, DAN tidak ada payment success sesudahnya sebelum cancel -- jadi
        kegagalan itu memang tidak pernah pulih sampai subscription-nya berhenti.
    
    Dicoba dua-duanya: hasilnya cuma beda 1 subscription dari 460 (longgar 56.09% vs ketat 55.87%) -- jadi secara empiris nyaris tidak
    masalah, tapi definisi KETAT dipakai karena secara konsep lebih tepat mewakili "involuntary churn" (kegagalan yang tidak pernah
    terselesaikan), dan di data ini "lebih tepat" itu praktis tanpa ongkos (beda cuma 0.22 poin persentase).

    Edge case boundary (ps.payment_date <= cs.effective_end_date di NOT EXISTS bawah): payment sukses yang jatuh PERSIS di hari cancel
    dianggap "recovery" oleh boundary <=. Awalnya diduga jarang terjadi, TAPI dicek dan ternyata ada 158 subscription cancel yang punya
    success payment persis di effective_end_date (34% dari 460) -- jumlah yang tidak kecil, jadi worth divalidasi dampaknya, bukan
    diasumsikan aman begitu saja. Setelah dites ganti <= jadi < (payment sukses harus STRICTLY sebelum cancel baru dianggap recovery):
    hasilnya cuma naik dari 257 jadi 258 (1 subscription pindah dari "recovered" ke "involuntary"). Artinya dari 158 kasus success-payment-
    di-hari-cancel itu, 157 di antaranya memang wajar (pembayaran terakhir siklus billing yang jatuh di tanggal akhir subscription, tidak
    ada hubungannya dengan gagal-bayar), dan cuma 1 yang benar-benar jadi kandidat recovery di window relevan. Boundary <= vs < TIDAK
    signifikan terhadap kesimpulan 6.6b -- dipertahankan sebagai <=.
*/

-- 6.6a Forward: rate cancel dalam 30 hari, failed vs success payment
;WITH cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
payment_outcome AS (
    SELECT p.payment_id, p.subscription_id, p.payment_date, p.status,
           CASE WHEN se.effective_end_date IS NOT NULL
                     AND se.effective_end_date > p.payment_date
                     AND se.effective_end_date <= DATEADD(DAY, 30, p.payment_date)
                THEN 1 ELSE 0 END AS cancel_within_30d
    FROM dbo.payments p
    JOIN sub_effective se ON se.subscription_id = p.subscription_id
    WHERE p.status IN ('failed', 'success')
      AND DATEADD(DAY, 30, p.payment_date) <= '2026-08-31'
)
SELECT
    status,
    COUNT(*) AS n,
    SUM(cancel_within_30d) AS cancel_30d,
    CAST(AVG(cancel_within_30d * 1.0) AS decimal(5,4)) AS rate,
    CAST(AVG(cancel_within_30d * 1.0) - 1.96 * SQRT(AVG(cancel_within_30d * 1.0) * (1 - AVG(cancel_within_30d * 1.0)) / COUNT(*)) AS decimal(5,4)) AS ci95_low,
    CAST(AVG(cancel_within_30d * 1.0) + 1.96 * SQRT(AVG(cancel_within_30d * 1.0) * (1 - AVG(cancel_within_30d * 1.0)) / COUNT(*)) AS decimal(5,4)) AS ci95_high
FROM payment_outcome
GROUP BY status;
GO

-- 6.6b Backward: kontribusi failed payment ke total cancellation
;WITH cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
cancelled_subs AS (
    SELECT subscription_id, effective_end_date FROM sub_effective WHERE effective_end_date IS NOT NULL
),
preceded_by_failure AS (
    SELECT cs.subscription_id, cs.effective_end_date,
           CASE WHEN EXISTS (
               SELECT 1 FROM dbo.payments pf
               WHERE pf.subscription_id = cs.subscription_id
                 AND pf.status = 'failed'
                 AND pf.payment_date <= cs.effective_end_date
                 AND pf.payment_date >= DATEADD(DAY, -30, cs.effective_end_date)
                 AND NOT EXISTS (
                     -- definisi KETAT: kegagalan itu TIDAK PERNAH pulih (retry sukses)
                     -- sebelum akhirnya cancel -- lihat catatan metodologi di atas
                     SELECT 1 FROM dbo.payments ps
                     WHERE ps.subscription_id = cs.subscription_id
                       AND ps.status = 'success'
                       AND ps.payment_date > pf.payment_date
                       AND ps.payment_date <= cs.effective_end_date
                 )
           ) THEN 1 ELSE 0 END AS didahului_failed_payment
    FROM cancelled_subs cs
)
SELECT
    COUNT(*) AS total_cancelled,
    SUM(didahului_failed_payment) AS didahului_failed_payment,
    CAST(AVG(didahului_failed_payment * 1.0) AS decimal(5,4)) AS pct_kontribusi
FROM preceded_by_failure;
GO


/*
    TEMUAN 6.6:
    - 6.6a (apakah polanya nyata): rate cancel dalam 30 hari setelah FAILED payment = 61.44% (n=376, CI95 [56.5%, 66.4%]), dibanding
      cuma 1.60% setelah SUCCESS payment (n=6255, CI95 [1.3%, 1.9%]). Bedanya ~38x lipat dan CI dua kelompok ini SANGAT jauh dari
      overlap -- ini BUKAN kebetulan sampel, involuntary churn adalah pola yang SANGAT NYATA di data ini.

    - 6.6b (kontribusi ke total cancellation, definisi KETAT -- kegagalan yang tidak pernah pulih): dari 460 subscription yang cancel,
      257 (55.87%) di antaranya punya failed payment dalam 30 hari sebelum cancel-nya YANG TIDAK PERNAH diikuti payment sukses sebelum
      cancel itu terjadi. Artinya LEBIH DARI SETENGAH total cancellation historis Flowdesk kemungkinan besar involuntary churn (gagal
      bayar yang tidak pernah terselesaikan), bukan voluntary churn (customer sengaja berhenti). Definisi longgar (tidak peduli
      recovery) kasih angka nyaris sama, 258/460 = 56.09% -- cuma beda 1 subscription yang gagal-lalu-pulih-lalu-tetap-cancel, jadi
      pilihan definisi ini nyaris tidak mengubah kesimpulan di data ini.

    - JAWABAN ke business question: teori Pak Hendra TERBUKTI SANGAT KUAT -- involuntary churn bukan cuma pola yang nyata, tapi
      kemungkinan jadi KONTRIBUTOR TERBESAR dari total churn Flowdesk (>50%). Ini juga insight paling actionable dari semua teori yang
      diuji sejauh ini (6.5-6.6): kalau Flowdesk punya sistem retry pembayaran otomatis atau dunning yang lebih baik (notifikasi kartu
      gagal, retry beberapa hari, dsb), ini berpotensi menyelamatkan sebagian besar dari 56% cancellation itu -- jauh lebih actionable
      dibanding memperbaiki channel acquisition (6.5) yang efeknya lebih sempit (cuma tier Starter).
*/

-- 6.7 Waktu resolusi support ticket: churn vs bertahan (uji teori Rangga)
/*
    "Customer churn" di sini didefinisikan di level CUSTOMER (bukan subscription): customer dianggap 'churned' kalau TIDAK PUNYA satu pun
    subscription yang masih aktif per akhir data (2026-08-31), 'retained' kalau masih punya minimal satu subscription aktif -- konsisten dengan
    cara "aktif" dihitung di 6.1/6.2 (effective_end_date dari 5.4).

    Ticket yang resolved_date-nya NULL DIBUANG dari perhitungan rata-rata (bukan dianggap resolution_days=0 atau semacamnya) -- soalnya NULL di
    sini bisa berarti dua hal berbeda (lihat data dictionary): tiket yang memang masih terbuka, ATAU tiket Februari 2025 yang pencatatan
    penyelesaiannya tidak lengkap akibat lonjakan tiket. Kita tidak bisa membedakan dua kasus itu dari data yang ada, jadi paling aman
    dikeluarkan semua daripada menebak. Efek sampingnya: rata-rata yang dilaporkan sedikit bias ke tiket yang TERCATAT selesai -- tapi ini
    berlaku sama untuk grup churned maupun retained, jadi tidak seharusnya memihak salah satu sisi perbandingan.

    Simplifikasi: SEMUA tiket customer itu dipakai (tidak dibatasi ke tiket yang terjadi SEBELUM subscription-nya cancel) -- pertanyaannya
    memang minta perbandingan level customer, bukan urutan waktu spesifik ticket-vs-cancel.

    Catatan metodologi (paralel dengan isu per-payment-row di 6.6a): rata-rata di 6.7a/6.7b dihitung per BARIS TIKET, bukan per customer
    dulu baru dirata-ratakan antar customer. Artinya customer yang buka banyak tiket otomatis punya bobot lebih besar ke angka rata-rata
    dibanding customer yang cuma buka 1 tiket. Ini bukan salah -- pertanyaannya wajar dibaca sebagai "bandingkan waktu resolusi TIKET",
    bukan "bandingkan rata-rata PER CUSTOMER" -- tapi ini pilihan pembobotan yang perlu disadari, sama seperti di 6.6a.
*/

-- 6.7a Ringkasan keseluruhan (dengan CI95 buat selisihnya)
;WITH cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id, s.customer_id,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
customer_status AS (
    SELECT c.customer_id,
        CASE WHEN EXISTS (
            SELECT 1 FROM sub_effective se
             WHERE se.customer_id = c.customer_id
               AND (se.effective_end_date IS NULL OR se.effective_end_date > '2026-08-31')
        ) THEN 'retained' ELSE 'churned' END AS customer_status
    FROM dbo.customers c
),
tickets AS (
    SELECT t.ticket_id, t.customer_id,
           DATEDIFF(DAY, t.created_date, t.resolved_date) AS resolution_days
    FROM dbo.support_tickets t
    WHERE t.resolved_date IS NOT NULL
),
summary AS (
    SELECT cs.customer_status, COUNT(*) AS n,
           AVG(t.resolution_days * 1.0) AS avg_days,
           STDEV(t.resolution_days * 1.0) AS sd_days
    FROM tickets t
    JOIN customer_status cs ON cs.customer_id = t.customer_id
    GROUP BY cs.customer_status
)
SELECT
    MAX(CASE WHEN customer_status = 'churned' THEN n END) AS n_churned,
    CAST(MAX(CASE WHEN customer_status = 'churned' THEN avg_days END) AS decimal(6,2)) AS avg_days_churned,
    MAX(CASE WHEN customer_status = 'retained' THEN n END) AS n_retained,
    CAST(MAX(CASE WHEN customer_status = 'retained' THEN avg_days END) AS decimal(6,2)) AS avg_days_retained,
    CAST(MAX(CASE WHEN customer_status = 'churned' THEN avg_days END)
       - MAX(CASE WHEN customer_status = 'retained' THEN avg_days END) AS decimal(6,2)) AS selisih_hari,
    CAST(
        (MAX(CASE WHEN customer_status = 'churned' THEN avg_days END) - MAX(CASE WHEN customer_status = 'retained' THEN avg_days END))
        - 1.96 * SQRT(
            POWER(MAX(CASE WHEN customer_status = 'churned' THEN sd_days END), 2) / MAX(CASE WHEN customer_status = 'churned' THEN n END)
          + POWER(MAX(CASE WHEN customer_status = 'retained' THEN sd_days END), 2) / MAX(CASE WHEN customer_status = 'retained' THEN n END)
        ) AS decimal(6,2)) AS ci95_low,
    CAST(
        (MAX(CASE WHEN customer_status = 'churned' THEN avg_days END) - MAX(CASE WHEN customer_status = 'retained' THEN avg_days END))
        + 1.96 * SQRT(
            POWER(MAX(CASE WHEN customer_status = 'churned' THEN sd_days END), 2) / MAX(CASE WHEN customer_status = 'churned' THEN n END)
          + POWER(MAX(CASE WHEN customer_status = 'retained' THEN sd_days END), 2) / MAX(CASE WHEN customer_status = 'retained' THEN n END)
        ) AS decimal(6,2)) AS ci95_high
FROM summary;
GO

-- 6.7b Rincian per kategori x prioritas tiket
;WITH cancel_dates AS (
    SELECT subscription_id, MAX(event_date) AS cancel_event_date
    FROM dbo.subscription_events WHERE event_type = 'cancel' GROUP BY subscription_id
),
sub_effective AS (
    SELECT s.subscription_id, s.customer_id,
           COALESCE(s.end_date, cd.cancel_event_date) AS effective_end_date
    FROM dbo.subscriptions s
    LEFT JOIN cancel_dates cd ON cd.subscription_id = s.subscription_id
),
customer_status AS (
    SELECT c.customer_id,
        CASE WHEN EXISTS (
            SELECT 1 FROM sub_effective se
             WHERE se.customer_id = c.customer_id
               AND (se.effective_end_date IS NULL OR se.effective_end_date > '2026-08-31')
        ) THEN 'retained' ELSE 'churned' END AS customer_status
    FROM dbo.customers c
),
tickets AS (
    SELECT t.ticket_id, t.customer_id, t.category, t.priority,
           DATEDIFF(DAY, t.created_date, t.resolved_date) AS resolution_days
    FROM dbo.support_tickets t
    WHERE t.resolved_date IS NOT NULL
)
SELECT
    t.category, t.priority, cs.customer_status,
    COUNT(*) AS n_tickets,
    CAST(AVG(t.resolution_days * 1.0) AS decimal(6,2)) AS avg_resolution_days
FROM tickets t
JOIN customer_status cs ON cs.customer_id = t.customer_id
GROUP BY t.category, t.priority, cs.customer_status
ORDER BY t.category, t.priority, cs.customer_status;
GO

/*
    TEMUAN 6.7:

    - 6.7a (level customer keseluruhan): rata-rata waktu resolusi tiket customer yang RETAINED = 2.29 hari (n=1061), customer yang CHURNED
      = 2.27 hari (n=621) -- selisihnya cuma 0.02 hari (churned malah SEDIKIT lebih cepat, bukan lebih lambat), dan CI95 selisihnya
      [-0.20, 0.25] hari -- TEMBUS NOL LEBAR SEKALI. Dengan sampel sebesar ini (n gabungan >1600), kalau efeknya beneran ada dan
      cukup besar untuk jadi perhatian bisnis, seharusnya sudah kelihatan di CI ini. Tidak kelihatan sama sekali.

    - 6.7b (per kategori x prioritas): polanya CAMPUR ACAK -- beberapa kombinasi churned lebih lambat (mis. Billing/Low: churned 2.52 vs
      retained 2.25; Bug/Medium: churned 2.62 vs retained 2.27), tapi hampir SEMUA kombinasi priority=High justru menunjukkan churned
      LEBIH CEPAT diresolusi (Billing/High: 1.44 vs 2.00; Onboarding/High: 1.38 vs 2.11; Feature Request/High: 1.69 vs 2.24; Other/High: 1.17
      vs 1.68) -- arah yang BERLAWANAN dari teori. n per kombinasi cukup kecil (13-139), jadi variasi ini kemungkinan besar cuma noise, tapi
      poin pentingnya: tidak ada pola KONSISTEN yang mendukung "churned selalu lebih lambat" di kategori/prioritas manapun.

    - JAWABAN ke business question: data TIDAK MENDUKUNG teori Rangga. Ini NULL RESULT yang cukup meyakinkan (sampel besar, CI sempit
      relatif ke ukuran efeknya, dan tidak ada arah konsisten di breakdown kategori/prioritas) -- bukan sekadar "belum ketemu buktinya", tapi
      "kemungkinan besar memang tidak ada efeknya" di data ini. Dari tiga teori yang diuji (6.5 Ayu, 6.6 Hendra, 6.7 Rangga), teori Rangga
      adalah yang PALING LEMAH buktinya -- jauh di bawah teori Hendra (involuntary churn, 6.6) yang buktinya sangat kuat.
*/

-- 6.8 Sintesis tiga teori (butuh klarifikasi ke stakeholder)
/*
    Section ini TIDAK ADA query baru -- business question sendiri menandai ini sebagai "sintesis, butuh klarifikasi ke stakeholder", jadi isinya
    murni rangkuman argumen berbasis angka dari 6.1-6.7, plus rekomendasi dan hal yang perlu dikonfirmasi sebelum eksekusi -- bukan keputusan
    final yang bisa diambil sendiri dari data doang.

    RANKING KEKUATAN BUKTI (dari yang paling kuat):

    1) HENDRA -- involuntary churn (payment gagal), TERKUAT (6.6):
       - Rate cancel dalam 30 hari: 61.44% setelah failed payment vs 1.60% setelah success payment (~38x lipat, CI95 kedua grup
         SANGAT jauh dari overlap -- [56.5%,66.4%] vs [1.3%,1.9%]).

       - 55.87% dari SEMUA 460 cancellation historis didahului failed payment yang tidak pernah pulih sebelum cancel.
       
       - Efek besar DAN menjelaskan porsi TERBESAR dari total churn.

    2) AYU -- acquisition channel x tier, SEDANG/BERSYARAT (6.5):
       - Benar KUAT tapi CUMA di kombinasi Paid Ads + tier Starter: 34.23% (n=111, CI95 [25.4%,43.1%]) vs 4.82%-17.71% channel lain
         di tier yang sama, CI nyaris tidak overlap.

       - TIDAK terbukti di tier Growth (CI Paid Ads tumpang tindih lebar dengan Referral).
      
       - Di tier Scale malah kebalik, tapi n kecil (12-25) jadi tidak reliable jadi bukti kontra.
       
       - Kesimpulan: efek nyata tapi SEMPIT cakupannya (satu kombinasi channel x tier), bukan masalah channel Paid Ads secara umum.

    3) RANGGA -- waktu resolusi support ticket, PALING LEMAH (6.7):
       - Selisih rata-rata cuma -0.02 hari (churned malah SEDIKIT lebih cepat), CI95 selisih [-0.25,0.20] hari -- tembus nol lebar,
         dengan n gabungan >1600. Null result yang meyakinkan, bukan "belum ketemu".

    REKOMENDASI (kalau Flowdesk cuma bisa fokus SATU area tahun ini):

    -> INVOLUNTARY CHURN (perbaikan payment retry/dunning system), karena:

       a) Skala dampak TERBESAR: >50% dari total cancellation historis berpotensi involuntary -- jauh lebih besar dari early-churn
          Paid Ads+Starter (6.5 cuma porsi n=111 dari 1082 customer, atau sekitar 10% dari total basis customer, DAN cuma 34% dari
          mereka yang churn di 90 hari pertama -- irisannya jauh lebih kecil dari 50%+ yang ditemukan di 6.6).
       
       b) Lebih ACTIONABLE: retry pembayaran otomatis + notifikasi kartu gagal adalah pola solusi yang sudah matang/umum di industri
          SaaS -- effort implementasi relatif jelas dan ROI-nya mudah diukur langsung (bandingkan involuntary churn rate sebelum vs
          sesudah retry system jalan).

       c) Berpotensi juga membantu tren revenue churn yang naik sejak Agustus 2025 (6.3/6.4) -- kalau sebagian cancel di periode itu
          juga gagal-bayar (belum dicek irisannya secara eksplisit, tapi worth dicek sebagai langkah investigasi lanjutan).

    YANG PERLU DIKONFIRMASI KE STAKEHOLDER SEBELUM EKSEKUSI:

       - Data ini menunjukkan BAHWA failed payment sangat berkorelasi dengan churn, tapi TIDAK menjelaskan KENAPA payment-nya gagal
         (kartu expired, saldo tidak cukup, masalah gateway regional, dll). Desain solusi (retry otomatis vs dunning email vs update
         payment method proaktif) tergantung root cause ini -- perlu data tambahan dari payment gateway/provider yang tidak ada di
         dataset ini.
       
       - Apakah "fokus satu area" berarti MENGABAIKAN early-churn di Paid Ads+Starter (6.5) sepenuhnya, atau ada ruang untuk inisiatif
         kecil kedua (mis. perbaikan onboarding tier Starter) berjalan paralel dengan effort utama.
       
       - Definisi "involuntary churn" yang dipakai di 6.6 (failed payment yang tidak pernah pulih sebelum cancel) perlu dikonfirmasi cocok
         dengan definisi yang dipakai Finance/Product kalau angka ini mau dipakai di laporan resmi atau target OKR.
       
       - Simplifikasi & pendekatan yang sudah didokumentasikan di 6.1/6.3 (plan_id terkini utk MRR historis, distorsi maks ~15.7%) perlu
         disetujui sebagai "cukup akurat untuk keputusan ini" oleh pihak yang berwenang, sebelum angka-angka ini dipakai untuk business
         case investasi resmi.
*/

