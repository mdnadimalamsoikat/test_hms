# SPRINT 9 — Reports & MIS (Page 80–86)

🎯 **Ei sprint e ki hobe:** Collection, OPD, IPD, Lab, Pharmacy, Doctor revenue report + MIS dashboard.

## Shuru-r age (check)
- [ ] Sprint 4–8 er data (na thakle report khali — normal)
- [ ] AUTH_REPORTS, AUTH_SUPER

**Build order:** 80 → 86 (je kono ta age korte paren)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

**Standard report page template (sob report e same):**
1. Create Page ▸ Blank ▸ Page Group `Reports` ▸ Authorization **AUTH_REPORTS**
2. Region **Filters** (Static, Template *Standard*, Span 12): `P8x_FROM` (Date, default `TRUNC(SYSDATE,'MM')`), `P8x_TO` (Date, default today), extra filter (doctor/dept), Button `GO` (Hot, fa-search) → Submit (ba DA Refresh regions)
3. Region **Summary cards** (Cards, small, 4 col)
4. Region **Chart** (Span 6/12)
5. Region **Detail** Interactive Report ▸ Download: CSV, XLSX, PDF ON ▸ Page Items to Submit filter items
6. Date where clause pattern: `COL >= TO_DATE(:P80_FROM,'DD-MON-YYYY') AND COL < TO_DATE(:P80_TO,'DD-MON-YYYY') + 1`

---
## 80 — Daily Revenue / Collection
Cards: Total collection, Cash, Digital (bKash/Nagad/Card), Refund
```sql
SELECT 'Total' lbl, SUM(NET_COLLECTION) val FROM VW_DAILY_REVENUE WHERE BRANCH_ID=:G_BRANCH_ID AND COLLECTION_DATE BETWEEN TO_DATE(:P80_FROM,'DD-MON-YYYY') AND TO_DATE(:P80_TO,'DD-MON-YYYY')
UNION ALL SELECT 'Cash', SUM(NET_COLLECTION) FROM VW_DAILY_REVENUE WHERE PAYMENT_MODE='CASH' AND BRANCH_ID=:G_BRANCH_ID AND COLLECTION_DATE BETWEEN TO_DATE(:P80_FROM,'DD-MON-YYYY') AND TO_DATE(:P80_TO,'DD-MON-YYYY')
UNION ALL SELECT 'Non-Cash', SUM(NET_COLLECTION) FROM VW_DAILY_REVENUE WHERE PAYMENT_MODE<>'CASH' AND BRANCH_ID=:G_BRANCH_ID AND COLLECTION_DATE BETWEEN TO_DATE(:P80_FROM,'DD-MON-YYYY') AND TO_DATE(:P80_TO,'DD-MON-YYYY')
```
Chart 1 **Pie** by BILL_TYPE · Chart 2 **Bar** by COLLECTION_DATE (stacked by PAYMENT_MODE: series per mode ba *Series Name Column* = PAYMENT_MODE)
IR detail: `VW_DAILY_REVENUE` rows. **Cashier-wise**: extra IR `SELECT e.FIRST_NAME cashier, r.PAYMENT_MODE, SUM(r.AMOUNT) FROM HMS_PAYMENT_RECEIPT r LEFT JOIN HMS_EMPLOYEE e ON e.EMPLOYEE_ID=r.CASHIER_ID WHERE ... GROUP BY ...` (day-end cash handover).

## 81 — OPD Summary
Filters + P81_DEPT_ID. IR:
```sql
SELECT VISIT_DATE, DEPT_NAME, DOCTOR_NAME, VISIT_TYPE, COUNT(*) visits, SUM(NET_FEE) fee
  FROM VW_OPD_DASHBOARD
 WHERE BRANCH_ID=:G_BRANCH_ID AND VISIT_STATUS<>'CANCELLED'
   AND VISIT_DATE BETWEEN TO_DATE(:P81_FROM,'DD-MON-YYYY') AND TO_DATE(:P81_TO,'DD-MON-YYYY')
   AND (:P81_DEPT_ID IS NULL OR DEPT_NAME = (SELECT DEPT_NAME FROM HMS_DEPARTMENT WHERE DEPT_ID=:P81_DEPT_ID))
 GROUP BY VISIT_DATE, DEPT_NAME, DOCTOR_NAME, VISIT_TYPE
```
Chart Line: visits per day · Bar: by department. IR ▸ Group By / Pivot enable (user nije pivot korte parbe).

## 82 — IPD Occupancy
Chart **Status Meter Gauge** (overall %): `SELECT ROUND(100*SUM(OCCUPIED)/NULLIF(SUM(TOTAL_BEDS),0)) FROM VW_BED_OCCUPANCY WHERE BRANCH_ID=:G_BRANCH_ID`
Bar per ward (OCCUPANCY_PCT) · IR: admissions/discharges per day:
```sql
SELECT TRUNC(ADMISSION_DATE) dt, COUNT(*) admissions,
       (SELECT COUNT(*) FROM HMS_IPD_ADMISSION x WHERE TRUNC(x.DISCHARGE_DATE)=TRUNC(a.ADMISSION_DATE) AND x.BRANCH_ID=:G_BRANCH_ID) discharges
  FROM HMS_IPD_ADMISSION a WHERE BRANCH_ID=:G_BRANCH_ID
   AND ADMISSION_DATE >= TO_DATE(:P82_FROM,'DD-MON-YYYY') AND ADMISSION_DATE < TO_DATE(:P82_TO,'DD-MON-YYYY')+1
 GROUP BY TRUNC(ADMISSION_DATE)
```
ALOS (avg length of stay) card: `AVG(CAST(DISCHARGE_DATE AS DATE) - CAST(ADMISSION_DATE AS DATE))` for discharged in range.

## 83 — Lab Statistics
```sql
SELECT s.REPORTING_SECTION, d.SERVICE_NAME, COUNT(*) tests, SUM(d.NET_AMOUNT) revenue,
       ROUND(AVG((CAST(d.VERIFIED_DATE AS DATE) - CAST(o.ORDER_DATE AS DATE))*24),1) avg_tat_hrs
  FROM HMS_INVESTIGATION_ORDER_DTL d
  JOIN HMS_INVESTIGATION_ORDER o ON o.ORDER_ID=d.ORDER_ID
  JOIN HMS_SERVICE_MASTER s ON s.SERVICE_ID=d.SERVICE_ID
 WHERE o.BRANCH_ID=:G_BRANCH_ID AND d.ITEM_STATUS<>'CANCELLED'
   AND o.ORDER_DATE >= TO_DATE(:P83_FROM,'DD-MON-YYYY') AND o.ORDER_DATE < TO_DATE(:P83_TO,'DD-MON-YYYY')+1
 GROUP BY s.REPORTING_SECTION, d.SERVICE_NAME
```
Chart: Top 10 tests (bar, `ORDER BY tests DESC FETCH FIRST 10 ROWS ONLY`).

## 84 — Pharmacy Sales
IR by day/item:
```sql
SELECT TRUNC(s.SALE_DATE) dt, s.SALE_TYPE, i.ITEM_NAME, SUM(d.QUANTITY) qty, SUM(d.LINE_TOTAL) amount
  FROM HMS_PHARMA_SALE s JOIN HMS_PHARMA_SALE_DTL d ON d.SALE_ID=s.SALE_ID AND d.IS_ACTIVE='Y'
  JOIN HMS_PHARMA_ITEM i ON i.ITEM_ID=d.ITEM_ID
 WHERE s.BRANCH_ID=:G_BRANCH_ID AND s.SALE_STATUS='COMPLETED'
   AND s.SALE_DATE >= TO_DATE(:P84_FROM,'DD-MON-YYYY') AND s.SALE_DATE < TO_DATE(:P84_TO,'DD-MON-YYYY')+1
 GROUP BY TRUNC(s.SALE_DATE), s.SALE_TYPE, i.ITEM_NAME
```
Cards: total sale, OTC vs IPD, gross margin (`SUM(d.QUANTITY*(d.UNIT_PRICE - stock.UNIT_COST))` optional).
(SALE_STATUS value DB CHECK dekhe milan.)

## 85 — Doctor-wise Revenue
`VW_DOCTOR_DAILY_OPD` (+date filter jodi view e date column thake) · plus IR from `HMS_BILLING_DTL WHERE DOCTOR_ID IS NOT NULL` group by doctor, REF_TYPE. Doctor commission: `HMS_DOCTOR_EARNING`. Chart horizontal bar top doctors.

## 86 — MIS Dashboard (Management)
Authorization AUTH_SUPER (ba ADMIN role). No filters (this month vs last month).
| Region | Type | Source idea |
|---|---|---|
| KPI (6 cards) | Cards | This month: revenue, patients, OPD visits, admissions, lab tests, pharmacy sale — each with `vs last month %` in subtitle |
| Revenue trend 12 months | Line | `SELECT TO_CHAR(COLLECTION_DATE,'YYYY-MM') m, SUM(NET_COLLECTION) FROM VW_DAILY_REVENUE WHERE COLLECTION_DATE >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-11) GROUP BY ... ORDER BY 1` |
| Revenue by department | Donut | billing dtl → service → dept |
| New vs follow-up patients | Stacked bar | OPD VISIT_TYPE by month |
| Bed occupancy | Gauge | VW_BED_OCCUPANCY |
| Top 10 tests / medicines | Bar | 83 / 84 queries |
| Outstanding dues | Classic top 20 | `VW_BILL_LIST WHERE DUE_AMOUNT>0 ORDER BY DUE_AMOUNT DESC` |

---
### Formal print reports
IR Download PDF = quick. Official (letterhead) print = Minimal page + **Dynamic Content** region (PL/SQL Function Body returning a CLOB — Page 23 er moto `w()` + `RETURN l_html`) (page 73 technique).
Excel: IR ▸ Download ▸ XLSX (24.2 native).
**Scheduled email report** (optional): IR ▸ Actions ▸ Subscription (APEX mail config lagbe: Instance Admin ▸ Email SMTP).

## Sprint 9 checklist
- [ ] 7 report page, filter kaj kore, download XLSX/PDF
- [ ] MIS dashboard load < 3 sec (slow hole index / materialized view — amake janan)
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Report khali | Date filter range e data nai / :G_BRANCH_ID null (Session Info check) |
| Date error ORA-01843 | Date item Format Mask `DD-MON-YYYY` set korun |
