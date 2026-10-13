# Page 97 — System Settings (step by step)

> Design: **Interactive Grid NAY.** Classic Report (sundor list) + Modal Form (Edit/Add popup) — Department/Service/Medicine er moto.

## Page 97 ta ki — hospital e kon kaj
Admin code na chhuye system er setting badle: hospital er naam, VAT, MRN/Bill number kon prefix diye shuru, dropdown list, branch info + logo. 4 ta tab:

| Tab | Table | Hospital e ki | Real example |
|---|---|---|---|
| Config | HMS_SYSTEM_CONFIG | System er "rules" (key = value) | `MAX_DISCOUNT_PCT = 20` → approval chara 20% er beshi discount dewa jabe na; `IPD_MIN_ADVANCE = 5000` |
| Number Series | HMS_NUMBER_SERIES | Document number er format | MRN = `MRN-0000001` (kokhono reset hoy na); OPD = `OPD-00001` (protidin 1 theke) |
| Lookup | HMS_LOOKUP_MASTER | Dropdown er list | Blood group, Religion, Dosage form |
| Branch | HMS_BRANCH | Hospital/shakha er parichoy + logo | Naam, thikana, phone — report/print header e |

Page structure: **97** (4 tab list) + modal forms **971** Config, **972** Number Series, **973** Lookup, **974** Branch.

## Step 0 — DB check
```
SELECT 'branch' t, COUNT(*) c FROM HMS_BRANCH
UNION ALL SELECT 'config', COUNT(*) FROM HMS_SYSTEM_CONFIG
UNION ALL SELECT 'number_series', COUNT(*) FROM HMS_NUMBER_SERIES
UNION ALL SELECT 'lookup', COUNT(*) FROM HMS_LOOKUP_MASTER;
```
Expected: branch 1, config 7, number_series 21, lookup > 0. Also Shared Components ▸ Application Items ▸ `G_BRANCH_ID` thakte hobe.

## Step 1 — Page + Tabs Container
- Create Page ▸ **Blank Page**, 97, `System Settings`, Page Group `Setup`.
- Region `Settings Tabs`: Type **Static Content**, Appearance ▸ Template **Tabs Container** (Tabs Container region *type* na, *template*).
- Child region: Layout ▸ **Parent Region** = `Settings Tabs`; child er Title = tab label.
