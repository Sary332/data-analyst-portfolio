# Business Brief - Kedai Renjana Budget & Cash Flow Planning

**Company (fictional):** Kedai Renjana
**Your role:** Freelance Data/Financial Analyst, asked to help build a planning model
**Stakeholder:** Kirana, the owner and also the person who keeps the books for Kedai Renjana
**Way of working:** ASAP (direct collaboration from the start)

---

## Background

Kedai Renjana is a small coffee shop that began operating in June 2022 in an office area (the first outlet, "Renjana Utama"). Because the response was good, in April 2024 Kirana opened a second outlet ("Renjana Kedua") near a university campus to reach the student segment.

Until now Kirana has kept the books herself in a simple way, recording income and expenses each month, and has never made a formal forward projection. Now she faces two big decisions at once.

## Business Problem

> "My regular coffee bean supplier says prices are going up, but not by how much yet, probably between 10-20%. At the same time there are two places that would suit a third outlet, but I don't know when it's safe to open, or which one makes more sense. I don't want a bank loan, so all the capital for the new outlet has to come from my own cash. I need some kind of model I can use to try out scenarios before I decide, not just a gut feeling."

There are a few things Kirana has deliberately not pinned down, so these need to be discussed and decided together before moving into the scenario calculations:

- **The cash reserve threshold considered "safe".** Kirana has no firm number. She has heard the rule of thumb "cash reserve = 3-6 months of fixed costs (Rent + Salary)" but has not decided which to use for Kedai Renjana.
- **The most sensible time to open the third outlet**, if it is opened at all, has not been decided (which month in the next 12-month projection).
- **The exact percentage of the coffee bean price increase** is also uncertain (the supplier's range is 10-20%), so it needs to be simulated at several points, not a single number.

## Available Data

- `Penjualan_Harian.csv` (daily sales) - daily revenue history for both outlets, January 2024 - December 2025 (24 months)
- `Biaya_Bulanan.xlsx` (monthly costs) - monthly cost history for both outlets by category (Bahan Baku/raw materials, Gaji/salary, Sewa/rent, Utilitas/utilities, Marketing, Maintenance, Lain-lain/other)
- `Parameter_Asumsi.xlsx` (assumption parameters) - a collection of assumptions and reference figures from Kirana for building the projection and scenarios (coffee price, capex for the 2 candidate new outlet locations, ramp-up curves, and so on)
- `Referensi_Outlet.xlsx` (outlet reference) - data on the existing outlets and the 2 candidate locations for the new outlet

## Constraints

- Capital for the new outlet must come 100% from internal cash, with no loan option.
- The projection must cover at least the next 12 months (January - December 2026).
- The model must be reusable by Kirana herself to change the assumptions (not just one static end result), so it needs Scenario Manager, Data Table, and/or Goal Seek, not just a one-off manual calculation.
- Kirana is not a finance person, so the summary sheet must be easy to read without understanding the formulas behind it.

## Data Disclosure Note

*This dataset is simulated and was created for portfolio purposes, designed to resemble the patterns of a small multi-outlet coffee shop business so the analysis stays realistic. It is not real company data.*
