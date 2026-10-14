# Business Questions - Kedai Renjana Budget & Cash Flow Planning

Ordered from the easiest to the one needing the most reasoning. Later questions need results from earlier ones, so it works best to go in order. Because the way of working is ASAP, we discuss and work through them together starting from number 1, rather than answering on your own first and checking afterwards.

1. From `Penjualan_Harian.csv`, once the data is cleaned, what is the monthly revenue pattern of both outlets over the last 24 months? Identify the growth trend and the seasonal pattern (weekly and monthly) at each outlet.

2. From `Biaya_Bulanan.xlsx` (after correct reclassification, see the Data Quality Notes), what is the average monthly margin (revenue minus total costs) of each outlet? With starting cash of Rp 12,000,000 on 1 January 2024 (see `Parameter_Asumsi.xlsx`), what is the estimated cash reserve of Kedai Renjana at the end of December 2025, as the starting point for the projection?

3. Build a 12-month baseline cash flow projection (January - December 2026), with no change in raw material prices and no new outlet, based on the trend and seasonal pattern from question #1. What is the projected cash at the end of December 2026 if everything runs as usual?

4. **(Use a one-variable Data Table)** Simulate the effect of a coffee bean price increase of 10%, 15%, and 20% (remember, only 55% of total Bahan Baku comes from coffee beans, see `Parameter_Asumsi.xlsx`) on monthly margin and projected cash at the end of December 2026. At what percentage increase, if any, does the monthly margin start to feel heavy?

5. **(Use Scenario Manager)** Compare 3 scenarios for opening the third outlet: (a) not opening a new outlet at all, (b) opening Location C (near the Train Station), (c) opening Location D (near the Residential Area), using each one's capex and ramp-up curve from `Parameter_Asumsi.xlsx`. For scenarios (b) and (c), also compare opening the new outlet in projection month 1 vs. projection month 4. How does each combination affect the cash reserve over the 12 months, and roughly how long until the investment pays back (payback period)?

6. **(Synthesis, use Goal Seek)** Now combine the heaviest scenario: the coffee bean price increase happens AT THE SAME TIME as opening the new outlet. Does the cash reserve stay above the safe threshold you discussed and agreed with Kirana (see the note in `Parameter_Asumsi.xlsx` about this threshold) throughout the 12-month projection? If not, use Goal Seek to find one of two things: (a) the minimum monthly revenue target the new outlet must reach for cash to stay safe, or (b) the earliest month it is safe to open the new outlet.

## Data Quality Notes

Before answering the questions above, check and clean the following first:

- `Penjualan_Harian.csv`, outlet Renjana Utama: for 5 days from 8-12 July 2024 the `jumlah_transaksi` (transaction count) column is blank (the digital cash register broke for a while, and the cashier could only record total revenue manually). The revenue is still valid to use; do not fill in the transaction count for those days arbitrarily.
- `Penjualan_Harian.csv`, outlet Renjana Utama: on 12-17 August 2024 revenue and transaction count are recorded as 0 because the outlet was fully closed for renovation (new floor and AC). This is not missing data, there was simply no operation, and it needs to be treated differently from ordinary days when calculating daily averages.
- `Penjualan_Harian.csv`, outlet Renjana Kedua: the first 3 days after opening (1-3 April 2024) appear twice (duplicated rows) because the old and new POS systems briefly ran side by side during the transition. Besides the duplicates, the figures on those 3 days are also far above normal because of the grand opening promo, so they are not representative as a basis for the growth trend or ramp-up curve.
- `Biaya_Bulanan.xlsx`, outlet Renjana Kedua: in August and September 2024, "Sewa" (rent) costs were wrongly recorded under the "Lain-lain" (other) category (the new bookkeeping staff at the time had not memorized the cost categorization). They need to be reclassified before calculating fixed costs correctly, which matters because Rent is one of the main inputs of the projection model.
