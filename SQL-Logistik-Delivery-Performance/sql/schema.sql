-- ============================================================
-- LogisticDeliveryPerformance — setup & import
-- Instance: localhost\SQLEXPRESS
-- Source CSVs: C:\Users\Admin\LogisticDeliveryPerformance\data\
-- ============================================================

-- 1. Create database (skip if it already exists)
IF DB_ID('LogisticDeliveryPerformance') IS NULL
    CREATE DATABASE LogisticDeliveryPerformance;
GO

USE LogisticDeliveryPerformance;
GO

-- ============================================================
-- 2. Tables
-- ============================================================
IF OBJECT_ID('dbo.deliveries', 'U') IS NOT NULL DROP TABLE dbo.deliveries;
IF OBJECT_ID('dbo.orders', 'U') IS NOT NULL DROP TABLE dbo.orders;
IF OBJECT_ID('dbo.drivers', 'U') IS NOT NULL DROP TABLE dbo.drivers;
IF OBJECT_ID('dbo.merchants', 'U') IS NOT NULL DROP TABLE dbo.merchants;
GO

CREATE TABLE dbo.merchants (
    merchant_id     VARCHAR(10)   NOT NULL PRIMARY KEY,
    merchant_name   VARCHAR(100)  NOT NULL,
    category        VARCHAR(50)   NOT NULL,
    sla_hours       INT           NOT NULL,
    partner_since   DATE          NOT NULL
);
GO

CREATE TABLE dbo.drivers (
    driver_id       VARCHAR(10)   NOT NULL PRIMARY KEY,
    driver_name     VARCHAR(50)   NOT NULL,
    city            VARCHAR(50)   NOT NULL,
    vehicle_type    VARCHAR(20)   NOT NULL,
    join_date       DATE          NOT NULL
);
GO

CREATE TABLE dbo.orders (
    order_id                VARCHAR(10)   NOT NULL PRIMARY KEY,
    merchant_id             VARCHAR(10)   NOT NULL,
    customer_city           VARCHAR(50)   NOT NULL,
    order_date              DATE          NOT NULL,
    package_weight_kg       DECIMAL(7,2)  NULL,
    promised_delivery_date  DATE          NULL,
    CONSTRAINT FK_orders_merchant FOREIGN KEY (merchant_id) REFERENCES dbo.merchants(merchant_id)
);
GO

/* No surrogate/primary key on delivery_id: the raw CSV contains exact duplicate rows (same delivery_id repeated), and an IDENTITY
   column also breaks BULK INSERT's default ordinal column mapping. */
CREATE TABLE dbo.deliveries (
    delivery_id       VARCHAR(10)   NOT NULL,
    order_id          VARCHAR(10)   NOT NULL,
    driver_id         VARCHAR(10)   NULL,
    attempt_number    INT           NOT NULL,
    pickup_time       DATETIME2     NOT NULL,
    delivery_time     DATETIME2     NULL,
    delivery_status   VARCHAR(20)   NOT NULL,
    CONSTRAINT FK_deliveries_order  FOREIGN KEY (order_id)  REFERENCES dbo.orders(order_id),
    CONSTRAINT FK_deliveries_driver FOREIGN KEY (driver_id) REFERENCES dbo.drivers(driver_id)
);
GO

CREATE INDEX IX_deliveries_delivery_id ON dbo.deliveries(delivery_id);
CREATE INDEX IX_deliveries_order_id    ON dbo.deliveries(order_id);
CREATE INDEX IX_deliveries_driver_id   ON dbo.deliveries(driver_id);
CREATE INDEX IX_orders_merchant_id     ON dbo.orders(merchant_id);
GO

-- ============================================================
-- 3. Import CSV -> tables
-- Load order matters: merchants & drivers first (parents),
-- then orders, then deliveries (children).
-- ============================================================

/* Notes:
   - FIRSTROW = 2 skips the CSV header row.
   - ROWTERMINATOR = '0x0a' (hex for LF) is used instead of the literal string '\n', because T-SQL does not interpret backslash
     escape sequences — '\n' would be treated as the two literal characters \ and n and match nothing in the file.
   - Blank fields for non-character columns (dates, driver_id which is CHAR/VARCHAR is the exception) are automatically loaded
     as NULL by BULK INSERT when the column is nullable.
*/

BULK INSERT dbo.merchants
FROM 'C:\Users\Admin\LogisticDeliveryPerformance\data\merchants.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO

BULK INSERT dbo.drivers
FROM 'C:\Users\Admin\LogisticDeliveryPerformance\data\drivers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO

BULK INSERT dbo.orders
FROM 'C:\Users\Admin\LogisticDeliveryPerformance\data\orders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO

BULK INSERT dbo.deliveries
FROM 'C:\Users\Admin\LogisticDeliveryPerformance\data\deliveries.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO

-- ============================================================
-- 4. Validate foreign keys
-- BULK INSERT skips constraint checking by default, so re-check
-- everything explicitly now that all tables are loaded.
-- ============================================================
ALTER TABLE dbo.orders     WITH CHECK CHECK CONSTRAINT FK_orders_merchant;
ALTER TABLE dbo.deliveries WITH CHECK CHECK CONSTRAINT FK_deliveries_order;
ALTER TABLE dbo.deliveries WITH CHECK CHECK CONSTRAINT FK_deliveries_driver;
GO

-- ============================================================
-- 5. Sanity check row counts
-- Expected: merchants 8, drivers 40, orders 5400, deliveries 5857
-- ============================================================
SELECT 'merchants'  AS table_name, COUNT(*) AS row_count FROM dbo.merchants
UNION ALL SELECT 'drivers',    COUNT(*) FROM dbo.drivers
UNION ALL SELECT 'orders',     COUNT(*) FROM dbo.orders
UNION ALL SELECT 'deliveries', COUNT(*) FROM dbo.deliveries;
GO

-- ============================================================================= --

-- ============================================================
-- 6. Data cleaning
/* Fix known data quality issues in the raw import (inconsistent city name casing/variants, invalid package weights, etc.)
   before this data is used for analysis.
*/
-- ============================================================

-- 6.1 Find duplicates in dbo.deliveries
/* The raw CSV contains exact duplicate rows (same delivery_id repeated with identical data on every column). */

-- (a) Duplicate delivery_id values, with how many times each repeats
SELECT
    delivery_id,
    COUNT(*) AS occurrences
FROM dbo.deliveries
GROUP BY delivery_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, delivery_id;

/* (b) Full-row duplicates (every column identical) — confirms the duplication is a straight copy, not just a reused delivery_id */
SELECT
    delivery_id, order_id, driver_id, attempt_number,
    pickup_time, delivery_time, delivery_status,
    COUNT(*) AS occurrences
FROM dbo.deliveries
GROUP BY
    delivery_id, order_id, driver_id, attempt_number,
    pickup_time, delivery_time, delivery_status
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, delivery_id;

/* (c) List every individual duplicate row (not just the grouped summary) so you can inspect them or feed them into a DELETE */
SELECT d.*
FROM dbo.deliveries d
WHERE d.delivery_id IN (
    SELECT delivery_id
    FROM dbo.deliveries
    GROUP BY delivery_id
    HAVING COUNT(*) > 1
)
ORDER BY d.delivery_id;

/* CLEAN: remove the duplicate rows, keeping exactly one copy of each. ROW_NUMBER() over every column ranks identical rows, so
   rn > 1 marks the extra copies to delete. */
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY delivery_id, order_id, driver_id, attempt_number,
                         pickup_time, delivery_time, delivery_status
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dbo.deliveries
)
DELETE FROM ranked WHERE rn > 1;

-- 6.2 Check: is driver_id NULL only for deliveries before Jan 2026?
/* Confirmed: 490/1225 (40%) of deliveries before 2026-01-01 have a NULL driver_id, vs 0/4632 (0%) on/after 2026-01-01 — driver
   assignment tracking looks like it only became consistent starting January 2026. */
SELECT
    CASE WHEN pickup_time < '2026-01-01' THEN 'before 2026-01-01' ELSE 'on/after 2026-01-01' END AS period,
    COUNT(*) AS total_deliveries,
    SUM(CASE WHEN driver_id IS NULL THEN 1 ELSE 0 END) AS null_driver_id,
    CAST(100.0 * SUM(CASE WHEN driver_id IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_null
FROM dbo.deliveries
GROUP BY CASE WHEN pickup_time < '2026-01-01' THEN 'before 2026-01-01' ELSE 'on/after 2026-01-01' END;

/* CLEAN: deliberately NO update here. NULL driver_id before Jan 2026 means "which driver handled this was never recorded" — it
   is genuinely unknown, not a formatting/typo problem like the other four issues. Fabricating a driver_id would misrepresent
   who delivered the package, so it's left as NULL (already the correct representation of "unknown"). */

-- 6.3 Check: is customer_city naming inconsistent only before Mar 2026?
/* Confirmed: 742/2230 (33%) of orders before 2026-03-01 use a non-standard city spelling (casing variants like 'jakarta'/
   'SURABAYA', or aliases like 'DKI Jakarta'/'Kota Makassar'/'Bandung Kota'/'Jakarta Pusat'), vs 0/3170 (0%) on/after
   2026-03-01, where only the 4 canonical names appear. Note: default collation is case-insensitive, so COLLATE ... BIN is
   required to actually see the casing differences. */
SELECT
    CASE WHEN order_date < '2026-03-01' THEN 'before 2026-03-01' ELSE 'on/after 2026-03-01' END AS period,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN customer_city COLLATE Latin1_General_BIN NOT IN ('Jakarta','Bandung','Surabaya','Makassar') THEN 1 ELSE 0 END) AS inconsistent_city,
    CAST(100.0 * SUM(CASE WHEN customer_city COLLATE Latin1_General_BIN NOT IN ('Jakarta','Bandung','Surabaya','Makassar') THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_inconsistent
FROM dbo.orders
GROUP BY CASE WHEN order_date < '2026-03-01' THEN 'before 2026-03-01' ELSE 'on/after 2026-03-01' END;

/* CLEAN: fold every casing variant / alias into the 4 canonical city names. Default collation is case-insensitive, so matching
   'Jakarta' also catches 'jakarta'/'JAKARTA' etc. — only the true aliases ('DKI Jakarta', 'Jakarta Pusat', 'Bandung Kota',
   'Kota Makassar') need to be listed explicitly. */
UPDATE dbo.orders
SET customer_city = CASE
    WHEN customer_city IN ('Jakarta', 'DKI Jakarta', 'Jakarta Pusat') THEN 'Jakarta'
    WHEN customer_city IN ('Bandung', 'Bandung Kota')                THEN 'Bandung'
    WHEN customer_city IN ('Surabaya')                                THEN 'Surabaya'
    WHEN customer_city IN ('Makassar', 'Kota Makassar')              THEN 'Makassar'
    ELSE customer_city
END
WHERE customer_city COLLATE Latin1_General_BIN NOT IN ('Jakarta', 'Bandung', 'Surabaya', 'Makassar');

-- 6.4 Check: is promised_delivery_date NULL for one specific merchant?
/* Confirmed: ALL 538 orders from MCH0003 (TokoBaru Fashion) have a NULL promised_delivery_date (100%), vs 0% for every other
   merchant. Side note: MCH0003.partner_since is 2026-06-01 in dbo.merchants, yet its orders start 2025-11-01 — that date also
   looks wrong. */
SELECT
    o.merchant_id,
    m.merchant_name,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.promised_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_promised,
    CAST(100.0 * SUM(CASE WHEN o.promised_delivery_date IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_null
FROM dbo.orders o
JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
GROUP BY o.merchant_id, m.merchant_name
ORDER BY pct_null DESC;

/* CLEAN: backfill the missing promise date using each merchant's own SLA (order_date + sla_hours). This only ever touches
   MCH0003's rows in practice, since it's the only merchant with NULLs, but it's written generically off IS NULL so it stays
   correct if another merchant ever has a gap too.

   IMPORTANT — provenance flag must be set BEFORE the backfill runs, not after: sla_hours (contract promise to the merchant)
   and promised_delivery_date (promise to the customer) are two different concepts, and section 7.5 explicitly compares
   analyses built on each of them. Deriving one from the other means definition (b) is no longer independent of definition
   (a) for these specific rows — it's just a reflection of the same sla_hours value, not real customer-facing data. Rather
   than leave it NULL (which would silently drop these rows from every promised_delivery_date-based analysis, the same
   trade-off as the 6.2 driver_id decision), we keep the backfill but tag which rows are assumption vs original data via
   is_promised_date_backfilled, so later analysis (7.5) can check how much this assumption actually swings the conclusion.

   The flag UPDATE below MUST run first, while promised_delivery_date IS NULL is still true for the affected rows — once
   the backfill UPDATE after it fills those values in, IS NULL can no longer find them. */
ALTER TABLE dbo.orders ADD is_promised_date_backfilled BIT NOT NULL DEFAULT 0;

UPDATE dbo.orders
SET is_promised_date_backfilled = 1
WHERE promised_delivery_date IS NULL;

UPDATE o
SET o.promised_delivery_date = CAST(DATEADD(HOUR, m.sla_hours, CAST(o.order_date AS DATETIME)) AS DATE)
FROM dbo.orders o
JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
WHERE o.promised_delivery_date IS NULL;

-- 6.5 Check: is package_weight_kg <= 0 concentrated in one merchant?
/* Confirmed: ALL 114 orders with a zero/negative package_weight_kg belong to MCH0002 (ElektroHome) — 114/763 (14.94%) of its
   orders, vs 0% for every other merchant. */
SELECT
    o.merchant_id,
    m.merchant_name,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.package_weight_kg <= 0 THEN 1 ELSE 0 END) AS zero_or_negative,
    CAST(100.0 * SUM(CASE WHEN o.package_weight_kg <= 0 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_bad
FROM dbo.orders o
JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
GROUP BY o.merchant_id, m.merchant_name
ORDER BY pct_bad DESC;

/* CLEAN: two different problems hide behind "<= 0", so they get two different fixes.
   - Negative values (-1.2 x19, -0.5 x32) are sign errors: the magnitude (1.2kg, 0.5kg) is well within MCH0002's normal weight
     range (0.32–15.62kg), so flip the sign back.
   - Exact zero (x63) is not a plausible weight for a physical package — it's an unmeasured/missing value, not "0kg", so it's
     set to NULL rather than guessing a number. */
UPDATE dbo.orders
SET package_weight_kg = ABS(package_weight_kg)
WHERE package_weight_kg < 0;

UPDATE dbo.orders
SET package_weight_kg = NULL
WHERE package_weight_kg = 0;

-- ============================================================================= --

-- ============================================================
-- 7. Analysis
-- Query the cleaned data to answer delivery performance
-- questions (SLA compliance, delay patterns, driver/merchant
-- performance, etc.).
-- ============================================================

-- 7.1 Average delivery duration (pickup -> delivered) per city, which city is the slowest?

/* delivery_status = 'Delivered' is used as a filter because this is the only status that has a delivery_time filled in (Failed and
   Returned are always NULL) — so it automatically only counts deliveries that actually arrived.
*/
SELECT
    o.customer_city,
    COUNT(*) AS delivered_count,
    CAST(AVG(CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT)) / 60.0 AS DECIMAL(6,2)) AS avg_duration_hours,
    CAST(MIN(CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT)) / 60.0 AS DECIMAL(6,2)) AS min_duration_hours,
    CAST(MAX(CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT)) / 60.0 AS DECIMAL(6,2)) AS max_duration_hours
FROM dbo.deliveries d
JOIN dbo.orders o ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY o.customer_city
ORDER BY avg_duration_hours DESC;

/*
    FINDINGS:
    Bandung is the slowest city with an average of 27.92 hours per delivery — about 50% longer than the other three cities,
    which all range closely between 18.28-18.75 hours (Makassar 18.75, Jakarta 18.50, Surabaya 18.28). The fastest (min) time is exactly the same
    across all cities (0.40 hours / 24 minutes), but the longest (max) time in Bandung is much higher: 167.27 hours (~7 days) vs. 103-130 hours
    (~4-5 days) in the other cities. This suggests the problem isn't the fastest/normal delivery, but rather Bandung's much longer distribution tail — 
    there's a significant proportion of deliveries delayed significantly, pushing the average up. It's worth further investigation:
    whether this is related to specific drivers, routes/distances, or order volume in Bandung.
*/

-- 7.2 Of all successful deliveries, what percentage exceeded the merchant's SLA hours? Break down by city.

/* CORRECTED (was previously measured from order_date — see note below): sla_hours is defined in the data dictionary/brief
   as the contract SLA measured "from pickup to delivered", not from order_date. The original version of this query used
   order_date as the start clock, which folds two different phases together:
     - order_date -> pickup_time: Kirim.in's internal processing gap (order received until a driver picks it up)
     - pickup_time -> delivery_time: the actual transit duration that sla_hours is scoped to cover
   Measuring from order_date therefore compared sla_hours against a duration that includes time the SLA was never meant
   to cover, inflating the breach rate. This is now measured from pickup_time, consistent with 7.1 and 7.5's definition
   (a) — both of which already used pickup_time correctly. */
WITH delivered AS (
    SELECT
        o.customer_city,
        m.sla_hours,
        CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT) / 60.0 AS actual_hours
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    customer_city,
    COUNT(*) AS delivered_count,
    SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END) AS sla_breach_count,
    CAST(100.0 * SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_sla_breach
FROM delivered
GROUP BY customer_city
ORDER BY pct_sla_breach DESC;

WITH delivered AS (
    SELECT
        m.sla_hours,
        CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT) / 60.0 AS actual_hours
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    'ALL CITIES' AS customer_city,
    COUNT(*) AS delivered_count,
    SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END) AS sla_breach_count,
    CAST(100.0 * SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_sla_breach
FROM delivered;

/*  FINDINGS (corrected, pickup_time-based):

    Overall, 29.85% (1,594 out of 5,340) of successful deliveries EXCEEDED the merchant's SLA — far lower than the
    81.33% originally reported when the start clock was order_date. That earlier figure was inflated by folding in the
    order->pickup processing gap, which sla_hours was never scoped to cover.

    Bandung is still clearly the worst city at 59.25%, consistent with 7.1's finding that it has the longest delivery
    duration — this part of the conclusion does NOT change. The other three cities, however, now sit much lower and
    still close together: Makassar 25.32%, Surabaya 22.50%, Jakarta 21.02% (vs. the old ~79% for all three). The gap
    between Bandung and the rest is proportionally even larger under the corrected definition (roughly 2.4x the next
    city, vs. ~1.14x under the old order_date-based figures).

    These numbers are identical to definition (a) in 7.5, which already used pickup_time — this query and 7.5(a) are
    now the same calculation, kept here as its own numbered finding since 7.2 asks the question directly. The
    "unrealistic SLA" merchant-level story (MCH0001 etc.) from the original FINDINGS here has moved to 7.4, which has
    the same order_date-vs-pickup_time issue and needs the same fix — flagged separately, not corrected in this pass.
*/

-- 7.3 Which driver (min. 20 orders) has the highest Failed/Returned ratio? Is there a pattern with vehicle type and package weight?

/*  Calculated per delivery attempt row (not per order), because each attempt has its own driver_id and delivery_status —
    A single order can have multiple attempts with different drivers. Total_attempts >= 20 is used as a minimum volume requirement
    to prevent drivers with a small sample size (e.g., 2 out of 3 failed = 67%) from dominating the ranking. */

-- (a) Top 10 drivers with the highest Failed/Returned ratio (min. 20 attempts)
-- NOTE: JOIN dbo.drivers is an INNER JOIN, so it assumes every driver has at least 1 delivery attempt — a driver with
-- zero deliveries would silently vanish from this ranking rather than show up as 0%. Re-check this assumption before
-- reusing the query on data where that might not hold (e.g. newly onboarded drivers with no deliveries yet).
WITH driver_stats AS (
    SELECT
        dr.driver_id, dr.driver_name, dr.vehicle_type, dr.city,
        COUNT(*) AS total_attempts,
        SUM(CASE WHEN d.delivery_status IN ('Failed','Returned') THEN 1 ELSE 0 END) AS failed_returned_count
    FROM dbo.deliveries d
    JOIN dbo.drivers dr ON dr.driver_id = d.driver_id
    GROUP BY dr.driver_id, dr.driver_name, dr.vehicle_type, dr.city
)
SELECT TOP 10
    driver_id, driver_name, vehicle_type, city, total_attempts, failed_returned_count,
    CAST(100.0 * failed_returned_count / total_attempts AS DECIMAL(5,2)) AS pct_failed_returned
FROM driver_stats
WHERE total_attempts >= 20
ORDER BY pct_failed_returned DESC;

-- (b) Failed/Returned Ratio per vehicle type (all drivers)
SELECT
    dr.vehicle_type,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN d.delivery_status IN ('Failed','Returned') THEN 1 ELSE 0 END) AS failed_returned_count,
    CAST(100.0*SUM(CASE WHEN d.delivery_status IN ('Failed','Returned') THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_failed_returned
FROM dbo.deliveries d
JOIN dbo.drivers dr ON dr.driver_id = d.driver_id
GROUP BY dr.vehicle_type
ORDER BY pct_failed_returned DESC;

-- (c) Average package weight per delivery status
SELECT
    d.delivery_status,
    COUNT(*) AS cnt,
    CAST(AVG(o.package_weight_kg) AS DECIMAL(6,2)) AS avg_weight_kg
FROM dbo.deliveries d
JOIN dbo.orders o ON o.order_id = d.order_id
WHERE d.driver_id IS NOT NULL
GROUP BY d.delivery_status;

-- (d) Failed/Returned Ratio per combination of vehicle type and package weight group
SELECT
    dr.vehicle_type,
    CASE WHEN o.package_weight_kg IS NULL THEN 'Unknown'
         WHEN o.package_weight_kg <= 3 THEN '0-3kg'
         WHEN o.package_weight_kg <= 7 THEN '3-7kg'
         WHEN o.package_weight_kg <= 12 THEN '7-12kg'
         ELSE '12kg+' END AS weight_bucket,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN d.delivery_status IN ('Failed','Returned') THEN 1 ELSE 0 END) AS failed_returned_count,
    CAST(100.0*SUM(CASE WHEN d.delivery_status IN ('Failed','Returned') THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_failed_returned
FROM dbo.deliveries d
JOIN dbo.drivers dr ON dr.driver_id = d.driver_id
JOIN dbo.orders o ON o.order_id = d.order_id
GROUP BY dr.vehicle_type,
    CASE WHEN o.package_weight_kg IS NULL THEN 'Unknown'
         WHEN o.package_weight_kg <= 3 THEN '0-3kg'
         WHEN o.package_weight_kg <= 7 THEN '3-7kg'
         WHEN o.package_weight_kg <= 12 THEN '7-12kg'
         ELSE '12kg+' END
ORDER BY vehicle_type, weight_bucket;

/* FINDINGS:
   Driver with the highest Failed/Returned ratio (min. 20 attempts) is DRV00032 (Motor, Makassar): 19 out of 113 attempts
   (16.81%) failed/returned. 9 out of 10 top drivers are all Motor — only one vehicle type dominates this list.

   Vehicle type pattern: Motor has a failed/returned ratio of 9.17% (292/3185), almost twice that of Van which is only 5.40% (114/2113).

   Package weight pattern: average package weight in Failed (5.11kg) and Returned (4.68kg) deliveries is higher than in Delivered (3.83kg) — heavier packages 
   tend to fail/return more often.

   The combination of both factors is the clearest finding: for Motor vehicles, the failure/return rate increases sharply with package weight —
   0-3kg 4.56% -> 3-7kg 10.76% -> 7-12kg 20.17% -> 12kg+ 21.05%. Conversely, for Van vehicles, the rate remains nearly flat across all
   weight groups (5.27%-5.93%, with 12kg+ showing 0% despite a small sample size of only 20 attempts). This strongly indicates that the root
   cause is the physical burden of heavy packages on motorized drivers, rather than individual driver performance. Recommendation: limit/halt assignment of 
   packages >7kg to Motor drivers, redirecting them to Vans.
*/

-- 7.4 Which merchants contribute the most delays (based on SLA)? Is it due to their strict SLAs, or other factors (destination city, etc.)?

/* CORRECTED (was previously measured from order_date — same bug as the original 7.2, see that section's note): sla_hours
   is scoped to pickup->delivered, not order_date->delivered. The queries below now use pickup_time as the start clock,
   consistent with 7.1/7.2/7.5(a). This changes the conclusion substantially — see FINDINGS below; the original
   "two overlapping causes" narrative does not survive the correction.

   Two perspectives are given: (a) overall ranking per merchant (breach_count = absolute contribution to total issues,
   pct_breach = severity relative to the merchant's own volume), and (b) a breakdown by merchant x city to see whether
   breaches are evenly distributed across all cities (indicating a problematic SLA) or concentrated in specific cities
   (indicating city factors). */

-- (a) SLA breaches per merchant, sorted by largest absolute contributor
-- NOTE: JOIN dbo.merchants is an INNER JOIN, so it assumes every merchant has at least 1 delivered order — a merchant
-- with none would silently vanish from this ranking rather than show up as 0%. Re-check this assumption if reused.
WITH delivered AS (
    SELECT
        o.merchant_id, m.merchant_name, m.sla_hours,
        CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT) / 60.0 AS actual_hours
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    merchant_id, merchant_name, sla_hours,
    COUNT(*) AS delivered_count,
    SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END) AS breach_count,
    CAST(100.0*SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_breach,
    CAST(AVG(actual_hours) AS DECIMAL(6,2)) AS avg_actual_hours
FROM delivered
GROUP BY merchant_id, merchant_name, sla_hours
ORDER BY breach_count DESC;

-- (b) SLA breach per merchant x destination city — check whether it is evenly distributed (regarding SLA) or uneven across cities (regarding location)
WITH delivered AS (
    SELECT
        o.merchant_id, m.merchant_name, m.sla_hours, o.customer_city,
        CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT) / 60.0 AS actual_hours
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    merchant_id, merchant_name, customer_city,
    COUNT(*) AS delivered_count,
    SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END) AS breach_count,
    CAST(100.0*SUM(CASE WHEN actual_hours > sla_hours THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_breach,
    CAST(AVG(actual_hours) AS DECIMAL(6,2)) AS avg_actual_hours
FROM delivered
GROUP BY merchant_id, merchant_name, customer_city
ORDER BY merchant_id, pct_breach DESC;

/* FINDINGS (corrected, pickup_time-based — supersedes the original order_date-based version):

    The "two overlapping causes" conclusion from the original version of this analysis does NOT hold once the start
    clock is fixed. Under the order_date-based measurement, MCH0001 and MCH0005 appeared to have "unrealistic SLAs
    breached almost universally regardless of city" (100% and 98.10%, flat across all 4 cities) — but that flatness
    was a ceiling effect: breach rates that are already pinned at ~100% cannot show city-to-city variation even if
    the underlying variation is there. With the order->pickup gap removed, MCH0001's overall breach rate drops to
    27.85% and MCH0005's to 28.39% — both now squarely in the same 27.85%-34.84% range as every other merchant
    (MCH0003 highest at 34.84%, MCH0001 now actually the LOWEST at 27.85%). There is no longer a subset of merchants
    whose SLA is so tight it breaches "almost universally" — every merchant breaches roughly a third of its
    deliveries, tight-SLA or not.

    More importantly, MCH0001 and MCH0005 turn out to have the SAME city pattern as every other merchant once
    measured correctly — the "flat across cities" story was an artifact, not a real difference from the other 6
    merchants:
      MCH0001: Bandung 54.12% vs. next-highest Makassar 26.94% (~2.0x)
      MCH0005: Bandung 58.18% vs. next-highest Makassar 28.57% (~2.0x)
    ...and this Bandung effect is consistently present for ALL 8 merchants, at a strikingly similar magnitude every
    time (Bandung is always the highest city, at roughly 1.8x-2.6x whichever city is second):
      MCH0002 2.3x, MCH0003 1.8x, MCH0004 2.5x, MCH0006 2.6x, MCH0007 2.0x, MCH0008 2.1x.

    Revised conclusion: there is really only ONE dominant, universal cause, not two overlapping ones — Bandung. It
    affects every merchant by roughly the same multiple regardless of that merchant's SLA tightness, category, or
    package profile, which points to a shared operational bottleneck specific to Bandung (route/distance/congestion/
    driver capacity — see 7.1 and 7.6, which already identified Bandung as understaffed relative to its order volume)
    rather than anything about individual merchants' SLA policies. Merchant-level differences in pct_breach (27.85%-
    34.84%) are comparatively minor and plausibly reflect real differences in delivery difficulty by category (e.g.
    MCH0008 Kirana Furniture's avg_actual_hours of 57.29 vs. MCH0001 QuickMart Express's 3.28 — furniture is
    inherently slower to move than groceries) rather than SLA policy being unrealistic.
*/

-- 7.5 Compare delays using 2 definitions: (a) SLA hours from pickup, (b) promised_delivery_date to the customer. Does the conclusion about which one is "the most problematic" change?

/* Definition (a) here is the pickup-based SLA breach — clock starts at pickup_time (not order_date), so this purely
   measures the courier's transit duration, without penalizing the merchant for the order->pickup delay. 7.2 and 7.4
   were originally measured from order_date and have since been corrected to this same pickup_time-based definition,
   so (a) below is now numerically identical to 7.2/7.4(a) — kept here so the comparison against definition (b) is
   self-contained in one place.

   Breach = (delivery_time - pickup_time) in hours > merchant's sla_hours.

   Definition (b): breach = delivery_time is later than promised_delivery_date.

   IMPORTANT regarding NULL promised_delivery_date: rows with promised_delivery_date NULL MUST be excluded from the
   calculation for definition (b) — both from the numerator (breach_b_count) and the denominator (known_promised_count) —
   so they are not incorrectly counted as "on time" simply because the data is missing. To do this, explicitly apply
   `promised_delivery_date IS NOT NULL` as a filter on both sides of SUM(), not only on breach_b_count.

   In this database, the values are already 0 (cleaned in 6.4), but this filter is still written explicitly as a safeguard
   in case the query is reused on data that has not been cleaned yet. */

/* (a) Per merchant: breach % under the pickup-SLA definition vs. promised_delivery_date */
WITH delivered AS (
    SELECT
        o.merchant_id, m.merchant_name, m.sla_hours,
        o.promised_delivery_date, d.pickup_time, d.delivery_time
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    merchant_id, merchant_name,
    COUNT(*) AS delivered_count,
    SUM(CASE WHEN CAST(DATEDIFF(MINUTE, pickup_time, delivery_time) AS FLOAT)/60.0 > sla_hours THEN 1 ELSE 0 END) AS breach_a_count,
    CAST(100.0*SUM(CASE WHEN CAST(DATEDIFF(MINUTE, pickup_time, delivery_time) AS FLOAT)/60.0 > sla_hours THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_breach_a,
    SUM(CASE WHEN promised_delivery_date IS NOT NULL THEN 1 ELSE 0 END) AS known_promised_count,
    SUM(CASE WHEN promised_delivery_date IS NOT NULL AND CAST(delivery_time AS DATE) > promised_delivery_date THEN 1 ELSE 0 END) AS breach_b_count,
    CAST(100.0*SUM(CASE WHEN promised_delivery_date IS NOT NULL AND CAST(delivery_time AS DATE) > promised_delivery_date THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN promised_delivery_date IS NOT NULL THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS pct_breach_b
FROM delivered
GROUP BY merchant_id, merchant_name
ORDER BY pct_breach_a DESC;

-- (b) Per city: breach % under the pickup-SLA definition vs. promised_delivery_date

WITH delivered AS (
    SELECT
        o.customer_city, m.sla_hours,
        o.promised_delivery_date, d.pickup_time, d.delivery_time
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    customer_city,
    COUNT(*) AS delivered_count,
    SUM(CASE WHEN CAST(DATEDIFF(MINUTE, pickup_time, delivery_time) AS FLOAT)/60.0 > sla_hours THEN 1 ELSE 0 END) AS breach_a_count,
    CAST(100.0*SUM(CASE WHEN CAST(DATEDIFF(MINUTE, pickup_time, delivery_time) AS FLOAT)/60.0 > sla_hours THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_breach_a,
    SUM(CASE WHEN promised_delivery_date IS NOT NULL THEN 1 ELSE 0 END) AS known_promised_count,
    SUM(CASE WHEN promised_delivery_date IS NOT NULL AND CAST(delivery_time AS DATE) > promised_delivery_date THEN 1 ELSE 0 END) AS breach_b_count,
    CAST(100.0*SUM(CASE WHEN promised_delivery_date IS NOT NULL AND CAST(delivery_time AS DATE) > promised_delivery_date THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN promised_delivery_date IS NOT NULL THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS pct_breach_b
FROM delivered
GROUP BY customer_city
ORDER BY pct_breach_a DESC;

/* FINDINGS:
   For CITY, the conclusion does NOT change across definitions: Bandung remains the most problematic under both definitions —
   59.25% (def. a, pickup) and 7.85% (def. b, promised_delivery_date), far above the other 3 cities (def. a: 21-25%,
   def. b: 1.7-2.7%). Therefore, "Bandung is problematic" is a robust finding that does not depend on how it is measured.

   For MERCHANT, the conclusion CHANGES DRAMATICALLY across definitions:
   - Definition (a) pickup-SLA: all merchants are clustered closely between 27.85%-34.84%, with TokoBaru Fashion (MCH0003)
     having the highest rate (34.84%) while QuickMart Express (MCH0001) is actually the LOWEST (27.85%).
   - Definition (b) promised_delivery_date: the range is much wider, 0.00%-19.59%. QuickMart Express (MCH0001), which in 7.4
     (order_date+SLA definition) was the WORST merchant (100% breach), now has 0% breach — meaning the conclusion about the
     "most problematic merchant" can actually be completely reversed depending on the definition used.
   - TokoBaru Fashion (MCH0003) is consistently the highest under both definitions (a) and (b) in this analysis, BUT this needs
     to be treated with caution: its pct_breach_b of 19.59% (far above other merchants at only 0-6.6%) is likely an ARTIFACT
     of our own cleaning decision in 6.4 — its promised_delivery_date was backfilled using order_date + sla_hours
     (48 hours = 2 days), which is much stricter than the original promised_delivery_date values for other merchants,
     which typically had a buffer of several days. This is NOT independent evidence that TokoBaru Fashion is actually
     problematic — rather, it is a side effect of how we filled the missing data.

   Final conclusion: the question "which city is the most problematic" has a stable answer (Bandung), but
   "which merchant is the most problematic" CANNOT be answered with a single number — the answer depends on the
   SLA definition used, and specifically for MCH0003, it also depends on the data-cleaning decision we made.
*/

/* (c) Robustness check: how much does the definition-(b) conclusion for MCH0003 actually depend on the 6.4
   backfill assumption? Recomputes pct_breach_b twice per merchant — once over ALL delivered rows (same as (a)
   above), and once EXCLUDING rows flagged is_promised_date_backfilled = 1 — so both sit side by side and the
   size of the swing is visible directly, instead of silently picking one version. */
WITH delivered AS (
    SELECT
        o.merchant_id, m.merchant_name,
        o.promised_delivery_date, o.is_promised_date_backfilled, d.delivery_time
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT
    merchant_id, merchant_name,
    COUNT(*) AS delivered_all,
    CAST(100.0*SUM(CASE WHEN CAST(delivery_time AS DATE) > promised_delivery_date THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_breach_incl_backfilled,
    SUM(CASE WHEN is_promised_date_backfilled = 0 THEN 1 ELSE 0 END) AS delivered_excl_backfilled,
    CAST(100.0*SUM(CASE WHEN is_promised_date_backfilled = 0 AND CAST(delivery_time AS DATE) > promised_delivery_date THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN is_promised_date_backfilled = 0 THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS pct_breach_excl_backfilled
FROM delivered
GROUP BY merchant_id, merchant_name
ORDER BY pct_breach_incl_backfilled DESC;

/* FINDINGS (robustness check):
   With backfilled rows excluded, MCH0003 has ZERO remaining delivered rows to compute pct_breach_b from (delivered_excl_
   backfilled = 0, pct = NULL) — because 100% of its rows were backfilled in 6.4, there is no original promised_delivery_date
   data for this merchant at all. Its 19.59% "highest breach rate" from the earlier FINDINGS block is therefore not a real,
   independently-observed result — it is entirely a product of the order_date + sla_hours assumption. With MCH0003 removed
   from contention, the actual highest definition-(b) breach rate among merchants with real promised_delivery_date data is
   MCH0008 Kirana Furniture at 6.59% — over 10 points lower than MCH0003's assumed figure, and a much less dramatic finding.
   Every other merchant's pct_breach_b is completely unchanged (they have no backfilled rows to exclude), which is exactly
   what should happen if the flag is scoped correctly.

   Updated conclusion for definition (b): "MCH0003 is the most problematic merchant" should NOT be reported as a finding —
   it has no supporting data, only an assumption. The honest statement is "MCH0003 cannot be evaluated under definition (b)
   with the current data; among merchants that can be evaluated, MCH0008 has the highest breach rate (6.59%), still far
   below any merchant's rate under definition (a)."
*/

-- 7.6 If Kirim.in could only add drivers in one city this year, which city needs them the most? (order/driver ratio, delay rate, average duration)

/* Assumption: drivers serve orders in the city where they are registered (dbo.drivers.city). This was verified first: 96-98% of deliveries
   handled by a driver are indeed destined for the driver's own city (the remaining cases are only a small amount of cross-city "leakage"),
   so it is valid to compare the driver_count per city with the order_count in the same city as a workload ratio.
   The delay rate and average duration use the pickup-based definition (as in 7.1 & 7.5 def. a), because this is the most
   relevant definition for courier/driver capacity — rather than merchant SLA policy (see 7.4/7.5 for why the order_date/
   promised_delivery_date definitions can be misleading for operational-level questions like this). */

-- NOTE: city_drivers/city_orders/city_perf are combined with INNER JOINs below, so this assumes every city has at
-- least 1 driver AND at least 1 order — a city with drivers but zero orders (or vice versa) would silently vanish
-- from the final result instead of showing up with a 0. Re-check this assumption if reused on other regions/periods.
WITH city_drivers AS (
    SELECT city, COUNT(*) AS driver_count FROM dbo.drivers GROUP BY city
),
city_orders AS (
    SELECT customer_city AS city, COUNT(*) AS total_orders FROM dbo.orders GROUP BY customer_city
),
city_perf AS (
    SELECT
        o.customer_city AS city,
        COUNT(*) AS delivered_count,
        CAST(AVG(CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT))/60.0 AS DECIMAL(6,2)) AS avg_duration_hours,
        CAST(100.0*SUM(CASE WHEN CAST(DATEDIFF(MINUTE, d.pickup_time, d.delivery_time) AS FLOAT)/60.0 > m.sla_hours THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,2)) AS pct_sla_breach
    FROM dbo.deliveries d
    JOIN dbo.orders o ON o.order_id = d.order_id
    JOIN dbo.merchants m ON m.merchant_id = o.merchant_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY o.customer_city
)
SELECT
    co.city,
    cd.driver_count,
    co.total_orders,
    CAST(CAST(co.total_orders AS FLOAT) / cd.driver_count AS DECIMAL(6,2)) AS orders_per_driver,
    cp.avg_duration_hours,
    cp.pct_sla_breach
FROM city_orders co
JOIN city_drivers cd ON cd.city = co.city
JOIN city_perf cp ON cp.city = co.city
ORDER BY orders_per_driver DESC;

/* 
   FINDING:

   Bandung is the answer, and it is supported by ALL THREE metrics simultaneously — there is no trade-off, all are consistent
   pointing to the same city:

   City      | Driver | Total Order | Order/Driver | Average Duration | % SLA Breach (pickup)
   Bandung   |   5    |    1,076    |   215.20     |  27.92 hours  |   59.25%
   Jakarta   |  15    |    2,009    |   133.93     |  18.50 hours  |   21.02%
   Surabaya  |  10    |    1,278    |   127.80     |  18.28 hours  |   22.50%
   Makassar  |  10    |    1,037    |   103.70     |  18.75 hours  |   25.32%

   Bandung has only 5 drivers (the fewest among the 4 cities) but has to handle 1,076 orders — a workload of
   215.20 orders per driver, about 1.6x that of Jakarta and 2.1x that of Makassar. This excessive workload aligns exactly with the
   slowest average delivery duration (27.92 hours, ~50% longer than the other 3 cities, which are all in the 18-19 hour range) and
   the significantly higher SLA breach rate (59.25% vs. 21-25% in the other cities).

   Since all three requested metrics (order/driver ratio, delay rate, and duration) consistently point to Bandung
   as the city with the greatest capacity shortage, and this pattern is also consistent with all previous findings (7.1, 7.2, 7.4,
   7.5), which have consistently identified Bandung as the problematic city, the recommendation is clear: if Kirim.in can only
   add drivers in ONE city this year, Bandung is the choice most strongly supported by the data.

*/
