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

## Problem
- Items 0 row (error chara): `HMS_PHARMA_CATEGORY` khali thakle JOIN mile na. Seed script ekhon category-o dhokay; check: `SELECT COUNT(*) FROM HMS_PHARMA_CATEGORY` = 8.

## STEP 2 — Page 94 design (CSS v11)
Columns: ITEM_CODE Heading `Code` + HTML Expression `<span class="hms-code">#ITEM_CODE#</span>` · ITEM_NAME `Medicine` · GENERIC_NAME `Generic` + HTML Expression `<span class="hms-cat">#GENERIC_NAME#</span>` (CSS `.hms-cat:empty` NULL e chip lukay) · STRENGTH `Strength` · DOSAGE_FORM `Form` · MANUFACTURER_NAME `Manufacturer` · PURCHASE_PRICE `Buy (Tk)` / MRP `MRP (Tk)` right align + Format Mask `999G999G990D00` · STATUS_TXT badge `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>` · ITEM_ID (Link to 941) + IS_ACTIVE Hidden. Empty message `No medicines found. Click "Add Medicine" to create one.`
Edit link, `Add Medicine` button, Dialog Closed DA — Page 941 toiri hobar por (STEP 3).

## STEP 3 — Page 941 (modal form) — wizard + Medicine Details
Create Page ▸ **Form** ▸ **Form** ▸ Page `941` · Name `Medicine` · Page Mode **Modal Dialog** · Navigation: don't use · Table `HMS_PHARMA_ITEM` · PK `ITEM_ID` · columns: `ITEM_ID, ITEM_CODE, ITEM_NAME, GENERIC_ID, PH_CATEGORY_ID, MANUFACTURER_ID, STRENGTH, DOSAGE_FORM, UNIT_OF_MEASURE, PACK_SIZE, PURCHASE_PRICE, MRP, VAT_PERCENT, REORDER_LEVEL, BARCODE, RACK_NO, IS_NARCOTIC, IS_ANTIBIOTIC, REQUIRES_PRESCRIPTION, IS_ACTIVE` (CREATED_*/UPDATED_* bad).
Page: Title `Medicine` · Page Group Setup · Dialog Width `960` · Authorization `AUTH_SETUP`. Region Title `Medicine Details`.
Items (seq): ITEM_ID Hidden 10 · ITEM_CODE Display Only `Medicine Code`, Default Static `(Auto)`, span 3, 20 (code trigger `TRG_PHARMA_ITEM_CODE_BI`; Save Session State etc. bodlabena) · ITEM_NAME Text `Medicine Name` Required span 9, 30 · GENERIC_ID Select `Generic Name` (`SELECT GENERIC_NAME d, GENERIC_ID r FROM HMS_PHARMA_GENERIC WHERE IS_ACTIVE='Y' ORDER BY 1`, Null `- Select -`, Required) span 6, 40 · PH_CATEGORY_ID Select `Category` (`SELECT CATEGORY_NAME d, PH_CATEGORY_ID r FROM HMS_PHARMA_CATEGORY WHERE IS_ACTIVE='Y' ORDER BY 1`, Required) span 6, 50 · MANUFACTURER_ID Select `Manufacturer` (`SELECT MANUFACTURER_NAME d, MANUFACTURER_ID r FROM HMS_PHARMA_MANUFACTURER WHERE IS_ACTIVE='Y' ORDER BY 1`, Null `- Select -`) span 6, 60 · STRENGTH Text, Placeholder `e.g. 500 mg`, span 3, 70 · DOSAGE_FORM Select `Dosage Form` (`SELECT LOOKUP_VALUE d, LOOKUP_VALUE r FROM HMS_LOOKUP_MASTER WHERE LOOKUP_TYPE='DOSAGE_FORM' AND IS_ACTIVE='Y' ORDER BY DISPLAY_ORDER`, Required) span 3, 80 · UNIT_OF_MEASURE Select `Unit` (Pcs, Strip, Bottle, Vial, Amp, Bag, Tube, Box; Default `Pcs`) span 3, 90 · PACK_SIZE Number `Pack Size` Default 1, Min 1, span 3, 95. Other items: seq 100+ (STEP 4).
