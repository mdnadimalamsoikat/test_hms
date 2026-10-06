# Sprint 3 — Ward & Bed (Page 93) — Ek ek step (APEX 24.2)

Master-Detail (Stacked): Master IG `HMS_WARD`, Detail IG `HMS_BED` (wizard: Create Page ▸ Master Detail ▸ Stacked, audit columns bad).
Bed seed: `03_insert_services.sql` statement 6 (needs services first). Check `SELECT COUNT(*) FROM HMS_BED` = 36.

## STEP 2 — Ward grid
Region Title `Wards` · Source **SQL Query** (no `ORDER BY` inside; put `WARD_CODE` in Source ▸ **Order By Clause**) · Edit ▸ Enabled, Target Table `HMS_WARD`, Add + Update (no Delete):
```sql
SELECT w.WARD_ID, w.BRANCH_ID, w.DEPT_ID, w.WARD_CODE, w.WARD_NAME, w.WARD_TYPE,
       w.FLOOR_NO, w.TOTAL_BEDS, w.GENDER_ALLOWED, w.NURSE_STATION_PHONE, w.IS_ACTIVE,
       (SELECT COUNT(*) FROM HMS_BED b WHERE b.WARD_ID = w.WARD_ID AND b.IS_ACTIVE = 'Y') AS BED_COUNT,
       (SELECT COUNT(*) FROM HMS_BED b WHERE b.WARD_ID = w.WARD_ID AND b.IS_ACTIVE = 'Y' AND b.BED_STATUS = 'AVAILABLE') AS AVAILABLE_COUNT
  FROM HMS_WARD w WHERE w.BRANCH_ID = :G_BRANCH_ID
```
Columns: WARD_ID Hidden+PK · BRANCH_ID Hidden, Default Item `G_BRANCH_ID` · DEPT_ID Select (`SELECT DEPT_NAME d, DEPT_ID r FROM HMS_DEPARTMENT WHERE IS_ACTIVE='Y' ORDER BY 1`, Null `- None -`) · WARD_CODE Text Upper Required · WARD_NAME Text Required · WARD_TYPE Select (GENERAL, CABIN, ICU, CCU, NICU, PICU, HDU, ISOLATION, MATERNITY, POST_OP, EMERGENCY) Required · FLOOR_NO Text · TOTAL_BEDS Hidden · GENDER_ALLOWED Select (ALL/MALE/FEMALE, default ALL) · NURSE_STATION_PHONE Text · IS_ACTIVE Switch · **BED_COUNT / AVAILABLE_COUNT** Display Only + **Source ▸ Query Only = On** (na dile ORA-01733).
(`Multiple Selection` property optional — skip.)

## STEP 3 — Bed grid (CSS v9: bed status badge)
Region Title `Beds` · Order By Clause `BED_NO` · Edit Add + Update.
Columns: BED_ID Hidden+PK · WARD_ID Hidden (wizard master link) · BED_NO Text Upper Required · BED_TYPE Select (GENERAL, CABIN_AC, CABIN_NON_AC, SUITE, ICU, CCU, NICU, CRADLE) Required · SERVICE_ID Select `SELECT s.SERVICE_NAME d, s.SERVICE_ID r FROM HMS_SERVICE_MASTER s JOIN HMS_SERVICE_CATEGORY c ON c.CATEGORY_ID = s.CATEGORY_ID WHERE c.CATEGORY_TYPE = 'BED' AND s.IS_ACTIVE = 'Y' ORDER BY 1` · DAILY_CHARGE Number, Format `999G999G990D00`, right · **BED_STATUS** Type **Plain Text** + HTML Expression `<span class="hms-badge #BED_STATUS#">#BED_STATUS#</span>` + **Source ▸ Query Only = On** (status admission trigger/ward board theke change hoy; insert e DB default `AVAILABLE`) · IS_ACTIVE Switch default Y.

## Problem — IG column e HTML badge `<span ...>` text hoye dekhay (escape)
IG te **Display Only/Plain Text** column e `HTML Expression` / `Escape special characters` nai (24.2). Solution: column Type **Link** (Link Text HTML render hoy — Edit pencil er moto) + CSS v10:
BED_STATUS_BADGE (SQL column) → Type **Link** · Heading `Status` · Link Target Type **URL** `javascript:void(0);` · Link Text `<span class="hms-badge #BED_STATUS#">#BED_STATUS#</span>` · Appearance ▸ CSS Classes `hms-nolink` · Source ▸ Query Only On. BED_STATUS = Hidden, Query Only On.
