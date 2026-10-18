# FnB Retail Outlet Performance: Kudapan Nusantara

## Business Problem
Kudapan Nusantara (a fictional company) started as one small shop in Depok in 2023, selling ice cream, popsicles, fruit chips, and light snacks. Over the last 18 months it expanded to 10 outlets across Greater Jakarta (Jabodetabek), a mix of standalone shops (*Toko*) and small kiosks (*Kios*) inside malls or markets.

The company's Operations Lead only had a monthly revenue report per outlet, sent over WhatsApp, and no central dashboard. They needed to know which outlets were genuinely performing well in order to guide expansion or improvement decisions. The catch is that "performing well" is ambiguous: is it revenue, or net margin after subtracting products lost to waste? This dashboard was built to answer that.

## Screenshots
**Overview (all outlets)**
![Overview, top: KPI cards and revenue vs. net margin per outlet](images/Overview%20P.a.png)
![Overview, middle: waste share, recommendations, and seasonal pattern](images/Overview%20P.b.png)
![Overview, bottom: all-outlets summary table](images/Overview%20P.c.png)

**Outlet Deep Dive**
![Outlet Deep Dive, top half](images/Outlet%20Deep%20Dive%20P.a.png)
![Outlet Deep Dive, bottom half](images/Outlet%20Deep%20Dive%20P.b.png)

## Approach
- Star schema: `fact_sales` and `fact_waste`, with `dim_outlet`, `dim_product`, and `dim_calendar` as dimensions
- Waste is valued at product cost (not selling price), so the number reflects the real loss rather than potential lost revenue
- Rankings and company averages (revenue, waste, net margin) are calculated across all outlets and used as the benchmark for each individual outlet
- Conditional formatting is driven by DAX measures, not static colors: the badges on the dashboard change text, color, and icon depending on the data of the outlet being viewed

## Key Findings & Business Impact
- High revenue does not guarantee profit. One example outlet ranks 4th of 10 on revenue, yet its waste value is the largest in the company and its net margin is only 9.7% (vs. a company average of 29.5%). Revenue rank and margin rank can tell very different stories.
- That outlet's problem is not selling the wrong products. Its category mix is almost identical to the company average, within 2 percentage points in every category. Its waste reasons are instead dominated by "Meleleh" (melted, around 50%), far ahead of expiry or damaged packaging, which points to a cold storage problem.
- Company-wide, waste eats **28.9%** of gross margin (about Rp 27.7M out of Rp 95.7M). Net margin shrinks from 45.6% (gross) to 32.4% (net), a 13.2-point gap caused purely by waste, not by higher product costs.
- Revenue for perishable categories (Ice Cream and Popsicles) follows a clear seasonal pattern, rising significantly in the dry season with peaks in July 2024 and May 2025. Useful for seasonal stock planning.

## Dashboard Features
- 2 pages: **Overview** (all outlets, with a revenue/margin comparison table) and **Outlet Deep Dive** (drill down into one outlet, chosen with a slicer)
- KPI cards with dynamic conditional formatting: text, color, and icon change with data thresholds instead of staying fixed
- Chart titles and legends on the Deep Dive page adapt to the outlet selected in the slicer
- Edit Interactions are configured manually on the Overview page so the recommendation panel does not change when a slicer is clicked and stays a general recommendation

## Repository Structure
```
report/   → .pbix file
data/     → raw data (fact_sales.csv, fact_waste.csv, dim_outlet.csv, dim_product.csv, dim_calendar.csv)
images/   → dashboard screenshots
```

## How to Open
Download the file from the `/report` folder and open it with the latest version of Power BI Desktop (free, no Premium features needed).

---

**Note:** This dataset is simulated and was created for portfolio purposes, designed to resemble the patterns of a multi-outlet F&B retail business so the analysis stays realistic. It is not real company data.
