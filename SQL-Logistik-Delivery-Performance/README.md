# Logistics Delivery Performance Analysis (SQL)

SQL analysis of last-mile delivery performance for a fictional courier startup. The focus is a 4-table normalized schema, deliberately dirty data, and an ambiguous business question with two valid but conflicting definitions of "late."

Dataset and business scenario are synthetic, generated for practice. No real company data is involved.

## Business context

Kirim.in is a fictional courier startup operating in four Indonesian cities (Jakarta, Surabaya, Bandung, Makassar), handling last-mile delivery for e-commerce merchants. The operations manager has been getting complaints about late deliveries and wants to know where the problem actually is: a specific city, specific drivers, or merchant SLAs that were never realistic to begin with.

Full scenario: [`Logistik-Delivery-Performance-Brief-Bisnis.md`](Logistik-Delivery-Performance-Brief-Bisnis.md)

## Dataset

Four tables, ~5,400 orders and ~5,800 delivery attempts over November 2025 - August 2026.

| Table | Rows | Purpose |
|---|---|---|
| `merchants` | 8 | Partner merchants, each with a contracted SLA (hours, pickup to delivered) |
| `drivers` | 40 | Driver roster, city, vehicle type |
| `orders` | 5,400 | One row per order, including the customer-facing promised delivery date |
| `deliveries` | ~5,800 | One row per delivery attempt (an order can have more than one if the first attempt fails) |

Column-level detail: [`Logistik-Delivery-Performance-Data-Dictionary.md`](Logistik-Delivery-Performance-Data-Dictionary.md)

Each data quality issue below was planted with a specific, traceable cause rather than scattered at random:

| Issue | Where | Cause |
|---|---|---|
| Exact duplicate rows | `deliveries`, 10-16 Mar 2026 | Barcode scanner glitch during that week |
| Missing `driver_id` | `deliveries`, before Jan 2026 | Driver assignment wasn't tracked digitally until Jan 2026 |
| Inconsistent city spelling | `orders.customer_city`, before Mar 2026 | No standardized dropdown until Mar 2026 |
| Missing `promised_delivery_date` | `orders`, merchant MCH0003 only | That merchant's API integration never captured it |
| Zero/negative `package_weight_kg` | `orders`, merchant MCH0002 only | Unit conversion bug in that merchant's legacy system |

## What this analysis does

1. Loads the CSVs into SQL Server and validates row counts and foreign keys.
2. Cleans each issue above, with a check query before the fix and a short rationale for why that specific fix was chosen (de-dup by full-row match, leave `driver_id` as NULL rather than guess it, fold city variants into 4 canonical names, backfill the missing promise date flagged with a provenance column, split zero vs. negative weights into two separate fixes).
3. Answers six business questions, listed in [`Logistik-Delivery-Performance-Business-Questions.md`](Logistik-Delivery-Performance-Business-Questions.md).
4. Catches and corrects a self-introduced measurement bug partway through (see 7.2 below) and runs a robustness check on one of its own cleaning decisions (see 7.5).

Full SQL, in order, with inline findings as comments: [`sql/schema.sql`](sql/schema.sql)

## Key findings

**Average delivery duration is uneven across cities.** Bandung averages 27.9 hours from pickup to delivery, about 50% longer than Jakarta, Surabaya, and Makassar, which all sit in the 18-19 hour range.

**SLA breach rate: 29.85%, not 81.33%.** The first version of this query measured the SLA clock from `order_date` instead of `pickup_time`. Since `sla_hours` is contractually scoped to pickup-to-delivered, that version was comparing the SLA against a longer duration than it was ever meant to cover, inflating the breach rate by 2.7x. Once fixed, Bandung is still the clear outlier at 59.25% vs. 21-25% for the other three cities, and the gap relative to the rest is actually larger under the correct measurement, not smaller.

**Failed/returned deliveries track package weight on motorcycles, not on vans.** Across weight buckets, motorcycle drivers go from a 4.56% failure rate on packages under 3kg to 21.05% on packages over 12kg. Van drivers stay flat at 5.3-5.9% regardless of weight. The pattern points to a vehicle-assignment problem, not individual driver performance.

**Merchant SLA strictness isn't what's driving breaches.** Once the same order_date-vs-pickup_time bug is fixed in the merchant-level breakdown, every merchant breaches 28-35% of its deliveries regardless of how tight its SLA is: the merchant with the tightest SLA (4 hours) is not the worst performer. What does hold constant across all eight merchants is a Bandung effect of roughly 1.8-2.6x the next-highest city, pointing to one shared operational bottleneck rather than eight separate merchant-level problems.

**Which definition of "late" you use changes the answer, except for one city.** Measuring lateness against the pickup-based SLA vs. the customer-facing promised date produces very different numbers (29.85% vs. 1.3% overall), and for one merchant the ranking of "most problematic" flips entirely depending on which definition is used. Bandung is the one result that holds under both definitions. A follow-up check also found that one merchant's apparent lead under the promised-date definition was an artifact of a backfill decision made during cleaning, not independent evidence; after excluding backfilled rows, the real leader under that definition is a different merchant, with a rate less than half as high.

**Bandung is the city that needs another driver.** It has the fewest drivers (5) of the four cities but the second-highest order volume, giving it 215 orders per driver vs. 104-134 for the other three. That capacity gap lines up with the longest average duration and the highest breach rate, measured three independent ways.

## Reproducing this

1. Create the database and load the CSVs: run `sql/schema.sql` sections 1-5 against SQL Server (adjust the `BULK INSERT` file paths to wherever `data/` ends up locally).
2. Run the cleaning steps: section 6.
3. Run the analysis queries: section 7.

Expected row counts after loading: 8 merchants, 40 drivers, 5,400 orders, 5,857 deliveries (pre-cleaning).

## Repository structure

```
.
├── README.md
├── Logistik-Delivery-Performance-Brief-Bisnis.md       # business scenario
├── Logistik-Delivery-Performance-Business-Questions.md # the 6 questions
├── Logistik-Delivery-Performance-Data-Dictionary.md    # column-level reference
├── Logistik-Delivery-Performance-Portfolio-Card.md     # one-page summary
├── data/
│   ├── merchants.csv
│   ├── drivers.csv
│   ├── orders.csv
│   └── deliveries.csv
└── sql/
    └── schema.sql   # DDL, data load, cleaning, and all 6 analysis queries
```
