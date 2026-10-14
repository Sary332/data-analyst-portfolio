# IT Helpdesk & Support Ticket Performance: Ardana Cloud

## Business Problem
Ardana Cloud (a fictional company) saw a surge in support ticket volume after onboarding new enterprise clients. Leadership needs to know which team or shift is most affected, whether a high SLA breach rate really correlates with low customer satisfaction, and, if only 3 additional headcount are approved this year, where they should go.

## Screenshots
**Overview**
![Overview](images/dashboard-overview.png)

**Deep Dive**
![Deep Dive](images/dashboard-deep-dive.png)

## Approach
- Star schema: `fact_tickets` plus the dimensions `dim_agents`, `dim_category`, `dim_sla`, and `Dim_Date`
- Data cleaning: deduplicated rows created by a system migration, standardized ticket categories, fixed a timezone bug, and excluded tickets without a survey response from the average CSAT
- DAX time intelligence to compare performance before vs. after onboarding (March 2026)
- Two SLA breach definitions calculated in parallel (first response vs. full resolution) to test whether the conclusion about the "most problematic team" changes with the definition

## Key Findings & Business Impact
- Ticket volume rose **123%** (308/month → 687/month) since the enterprise client onboarding in March 2026
- Overall SLA Breach Rate is **56.9%**, spread evenly across all priority levels. The problem is systemic, not tied to one priority
- **Tier 1** is the only team whose resolution time got significantly worse since onboarding (83h to 124h, up 49%), making it the main bottleneck right now
- A paradox: **Tier 3** breaches SLA most often (77%) yet has the highest CSAT (4.01/5). A high breach rate does not automatically mean unhappy customers
- Night shift: first response takes **21.3 hours** vs. an 11.7-hour average for the other shifts, with only 2 agents on duty
- The Software Bug × Tier 2 combination has a reopen rate far above any other combination (27.7%)
- **3-headcount recommendation**: prioritize Tier 1 (capacity), then the night shift. Tier 2 is not recommended because it is the most stable and fastest right now, and any issue there is about process quality, not capacity

## Dashboard Features
- 2 pages: **Overview** (general condition plus the headcount recommendation) and **Deep Dive** (root cause diagnostics)
- A date slicer on each page, deliberately not synced (the analysis goals differ)
- KPI cards with conditional formatting, with thresholds based on the actual data distribution
- Edit Interactions configured manually so clicks between visuals do not change the intended findings (anti-misleading)

## Repository Structure
```
report/   → .pbix file
data/     → raw data (fact_tickets.csv, dim_agents.csv, dim_category.csv, dim_sla.csv)
images/   → dashboard screenshots
```

## How to Open
Download the file from the `/report` folder and open it with the latest version of Power BI Desktop.

---

**Note:** This dataset is simulated and was created for portfolio purposes, designed to resemble the patterns of an IT helpdesk/support business so the analysis stays realistic. It is not real company data.
