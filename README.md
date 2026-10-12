# Data Analyst Portfolio

Hi, I'm Sasa (Sari Saldi). I'm building a career in data analysis, and this repo holds my portfolio projects. Each folder is one project with its own README. Most folders also include the SQL scripts, data files, or dashboard so you can follow the work step by step.

All datasets are synthetic and all companies are fictional. Each dataset was built with realistic problems such as duplicate rows, inconsistent labels, and missing dates, so the cleaning and analysis steps look like real work.

## Projects

| Project | Tools | What I found |
|---|---|---|
| [SQL-Logistik-Delivery-Performance](./SQL-Logistik-Delivery-Performance) | SQL | Late deliveries at a delivery startup came mostly from one understaffed city. Bandung had 215 orders per driver against about 122 elsewhere, and a 59% SLA breach rate against 21-25% in the other cities. |
| [SQL-SaaS-Subscription-Churn-Analysis](./SQL-SaaS-Subscription-Churn-Analysis) | SQL Server (T-SQL) | I tested three conflicting churn theories. Failed payments came before about 56% of all cancellations, and subscriptions with a failed payment were 38 times more likely to cancel within 30 days (61.4% vs 1.6%). |
| [PBI-IT-Helpdesk-Ticket-Performance](./PBI-IT-Helpdesk-Ticket-Performance) | Power BI | Ticket volume rose 123% after an enterprise client came on board. The team that broke the SLA most often also had the highest customer satisfaction, so the problem was process quality in one team, not capacity everywhere. |
| [PBI-FnB-Retail-Outlet-Performance](./PBI-FnB-Retail-Outlet-Performance) | Power BI | An outlet ranked 4th of 10 on revenue had the lowest net margin of all. Melted and wasted stock took 30.7% of the company's gross margin. |
| [Excel-Digital-Product-Sales-Consolidation](./Excel-Digital-Product-Sales-Consolidation) | Excel (Power Query, Power Pivot, DAX) | After merging three differently formatted sales sources and removing 9.6% refund and chargeback transactions, the channel with the biggest raw revenue dropped from 1st to 2nd. Net margin ranged from 85.1% to 58.2% between channels. |
| [Excel-Kedai-Renjana-Budget-Cashflow-Planning](./Excel-Kedai-Renjana-Budget-Cashflow-Planning) | Excel (Data Table, Scenario Manager, Goal Seek) | A two-outlet coffee shop can afford a third outlet without a bank loan, even if coffee bean prices rise 20%. Cash in the worst realistic scenario stays at Rp110.9 million at its lowest, above the Rp86.3 million safety threshold. |

## Tools and techniques

- **SQL:** data cleaning, CTEs, window functions, cohort and churn logic, confidence intervals
- **Power BI:** star schema modeling, DAX measures, conditional formatting, report design
- **Excel:** Power Query, Power Pivot, DAX measures, what-if analysis (Data Table, Scenario Manager, Goal Seek), data cleaning

## How to read a project folder

Start with the README in the folder. It explains the business question, the data, the cleaning steps, and the findings. The `sql/` or `data/` folders hold the files behind the numbers.
