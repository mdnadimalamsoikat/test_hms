# Sprint 3 — Medicine Master (Page 94 + 941) — Ek ek step (APEX 24.2)

Table `HMS_PHARMA_ITEM` (+ `HMS_PHARMA_GENERIC`, `HMS_PHARMA_CATEGORY`, `HMS_PHARMA_MANUFACTURER`). Page 94 = list (IR), Page 941 = modal form.

## STEP 0 — DB (ITEM_CODE auto + demo data)
1. Trigger: `database/06_triggers/TRG_AUTO_CODES.sql` er `SEQ_PHARMA_ITEM_CODE` + `TRG_PHARMA_ITEM_CODE_BI` (MED-00001...). Form e ITEM_CODE item rakhben na / Display Only `(Auto)`.
2. Demo: `database/08_master_data/05_insert_pharmacy_demo.sql` (18 generic, 5 manufacturer, 20 medicine). Expected counts: 18 / 5 / 20, first_code `MED-00001`.

## STEP 1 — Page 94 (list)
Create Page ▸ Report ▸ Interactive Report ▸ Page 94 `Medicines`:
```sql
SELECT i.ITEM_ID, i.ITEM_CODE, i.ITEM_NAME, g.GENERIC_NAME, i.STRENGTH, i.DOSAGE_FORM,
       m.MANUFACTURER_NAME, i.PURCHASE_PRICE, i.MRP,
       CASE i.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END AS STATUS_TXT, i.IS_ACTIVE
  FROM HMS_PHARMA_ITEM i
  LEFT JOIN HMS_PHARMA_GENERIC g ON g.GENERIC_ID = i.GENERIC_ID
  LEFT JOIN HMS_PHARMA_MANUFACTURER m ON m.MANUFACTURER_ID = i.MANUFACTURER_ID
```
