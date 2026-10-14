# SaaS Subscription & Churn Analysis (Flowdesk)

## Business Problem
Flowdesk (a fictional SaaS company, a task management tool for SMB teams in Southeast Asia) is seeing rising churn, but three teams blame three different things: Customer Support says ticket resolution is too slow, Growth says the quality of acquisition channels (especially Paid Ads) is poor, and the CFO says many failed payments are never followed up. Leadership needs to know which theory the data actually supports, so this year's investment goes to the right area instead of three directions at once.

This project combines 6 tables of subscription, payment, and support ticket data, then tests each of the three theories separately using the appropriate statistical methods.

*Note: all data in this project is simulated (synthetic), designed to resemble real SaaS business patterns. It is not real company data.*

## Approach
1. **Import & cleaning.** Load the 6 CSV tables into SQL Server with `BULK INSERT`, dedupe exact-duplicate payment rows through a staging table, standardize the inconsistently written `acquisition_channel` categories (differences in capitalization, spacing, and underscores, only visible when the collation is forced to be case-sensitive), and reconstruct missing cancel dates in `subscriptions.end_date` from `subscription_events`.
2. **Baseline trend analysis.** Build "active as of date" logic (not just the status column) so active customer counts and MRR are historically accurate month by month, then calculate logo churn rate vs. revenue churn rate and find the point where the two churn definitions start telling different stories.
3. **Root cause investigation.** Trace that divergence to plan downgrade patterns, using a recursive CTE to generate a monthly calendar and a self-join on old vs. new plans.
4. **Hypothesis testing.** Test the three stakeholder theories separately: right-censoring for cohorts that have not been observed long enough (90-day early churn, 30-day involuntary churn), 95% confidence intervals (Wald) for every proportion comparison, and a sensitivity test for ambiguous boundary definitions.
5. **Synthesis.** Rank the three theories by strength of evidence, give a prioritized recommendation, and list what still needs to be confirmed with stakeholders before execution.

## Key SQL Techniques
- Layered CTEs, including a recursive CTE to generate a month-end calendar (`vw_month_calendar`)
- Window functions: `ROW_NUMBER`, `LAG` (to compare the current month with the previous month)
- Self-join on the `plans` table (aliases `p_old`/`p_new`) to calculate the price difference on a downgrade
- Correlated subqueries with `EXISTS`/`NOT EXISTS`: an anti-join for logo churn, and a check on "did the failed payment ever recover before cancellation" for involuntary churn
- Right-censoring: exclude subscriptions/payments whose observation window (30 or 90 days) was not complete at the end of the data, so they are not wrongly counted as "not churned" when they simply could not be observed yet
- Staging table + `SELECT DISTINCT` to dedupe raw data before loading into the final table

## Key Findings & Business Impact
- **Involuntary churn (failed payments) is the largest contributor**: ~56% of all subscriptions that cancel were preceded by a failed payment that never recovered within 30 days, larger than the other two theories combined.
- Subscriptions with a failed payment are **38x more likely to cancel within 30 days** than those with successful payments (61.4% vs. 1.6%), with 95% confidence intervals for the two groups that are nowhere near overlapping.
- **Revenue churn rate starts diverging from logo churn rate in August 2025**, with the gap widening to about +24%. It is driven by plan downgrades that rise sharply from the same month, something you would never see if you only tracked the number of customers who leave.
- **The acquisition channel theory is only true for a specific combination**: Paid Ads + the Starter tier has 34.2% early churn (far above other channels in the same tier, 4.8%-17.7%), but the effect nearly disappears in the Growth/Scale tiers. It is not a channel problem in general.
- **The support resolution speed theory is not supported**: the difference in average ticket resolution time between churned and retained customers is only -0.02 days, with a confidence interval that extends well past zero (a convincing null result, not just "no evidence found yet").
- **Recommendation**: prioritize fixing the payment retry/dunning system (largest impact and most actionable), not acquisition channels or support speed.

## Repository Structure
```
sql/    → import, cleaning, and all analysis queries (01_create_and_import.sql)
data/   → raw data (customers.csv, plans.csv, subscriptions.csv, subscription_events.csv, payments.csv, support_tickets.csv)
```

## How to Run
Create a new database in SQL Server, then run `sql/01_create_and_import.sql` from top to bottom (adjust the `data/` folder path in the `BULK INSERT` section to where the files are on your computer). The file is ordered: schema setup → import → verification → cleaning → all analysis queries (6.1-6.8).

---

**Note:** This dataset is simulated and was created for portfolio purposes, designed to resemble the patterns of a SaaS subscription business so the analysis stays realistic. It is not real company data.
