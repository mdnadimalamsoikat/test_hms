# Sprint 3 — Medicine Master (Page 94 + 941) — FULL config (APEX 24.2)

Table `HMS_PHARMA_ITEM` (+ `HMS_PHARMA_GENERIC`, `HMS_PHARMA_CATEGORY`, `HMS_PHARMA_MANUFACTURER`). Page 94 = list (IR), Page 941 = modal form.
**Column names (repo-te verified, `database/02_tables/10_pharmacy_tables.sql`):** `HMS_PHARMA_ITEM`: ITEM_ID, ITEM_CODE, ITEM_NAME, GENERIC_ID, **PH_CATEGORY_ID**, MANUFACTURER_ID, STRENGTH, DOSAGE_FORM, UNIT_OF_MEASURE, PACK_SIZE, PURCHASE_PRICE, MRP, VAT_PERCENT, REORDER_LEVEL, BARCODE, RACK_NO, IS_NARCOTIC, IS_ANTIBIOTIC, REQUIRES_PRESCRIPTION, IS_ACTIVE (+ audit). `HMS_PHARMA_CATEGORY` key = **PH_CATEGORY_ID** (`CATEGORY_ID` na), `HMS_PHARMA_GENERIC` = GENERIC_ID/GENERIC_NAME, `HMS_PHARMA_MANUFACTURER` = MANUFACTURER_ID/MANUFACTURER_NAME.

## PART A — DB check (APEX er age)
1. `SEQ_PHARMA_ITEM_CODE` + trigger `TRG_PHARMA_ITEM_CODE_BI` (`database/06_triggers/TRG_AUTO_CODES.sql`) — code `MED-00001...`.
2. Seed `database/08_master_data/05_insert_pharmacy_demo.sql` (category 8 + generic 18 + manufacturer 5 + medicine 20; category na thakle item 0 row dhoke).
3. Check: `SELECT COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME='HMS_PHARMA_ITEM'` (24) · counts generics 18 / manufacturers 5 / categories 8 / items 20 · trigger STATUS = VALID.

## PART B — Page 94 (list)
Create Page ▸ Report ▸ Interactive Report ▸ Page `94` `Medicines` ▸ Normal ▸ Navigation: don't use ▸ SQL:
```sql
SELECT i.ITEM_ID, i.ITEM_CODE, i.ITEM_NAME, g.GENERIC_NAME, i.STRENGTH, i.DOSAGE_FORM,
       m.MANUFACTURER_NAME, i.PURCHASE_PRICE, i.MRP,
       CASE i.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END AS STATUS_TXT, i.IS_ACTIVE
  FROM HMS_PHARMA_ITEM i
  LEFT JOIN HMS_PHARMA_GENERIC g ON g.GENERIC_ID = i.GENERIC_ID
  LEFT JOIN HMS_PHARMA_MANUFACTURER m ON m.MANUFACTURER_ID = i.MANUFACTURER_ID
```
Page: Title `Medicines` · Page Group `Setup` · Authorization `AUTH_SETUP`. Region: Title `Medicines` · Static ID `medicine_list`.
Columns: ITEM_ID Link (Page 941, Set Items `P941_ITEM_ID`=`#ITEM_ID#`, Clear Cache 941, Link Text `<span class="fa fa-edit" aria-label="Edit"></span>`, Heading blank) · ITEM_CODE `Code` + HTML `<span class="hms-code">#ITEM_CODE#</span>` · ITEM_NAME `Medicine` · GENERIC_NAME `Generic` + HTML `<span class="hms-cat">#GENERIC_NAME#</span>` · STRENGTH `Strength` · DOSAGE_FORM `Form` · MANUFACTURER_NAME `Manufacturer` · PURCHASE_PRICE `Buy (Tk)` / MRP `MRP (Tk)` right + Format Mask `999G999G990D00` · STATUS_TXT `Status` + HTML `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>` · IS_ACTIVE Hidden Column.
Button `Add Medicine` (slot Right of Interactive Report Search Bar, Hot, `fa-plus`, Redirect Page 941, Clear Cache 941, Authorization `AUTH_SETUP_ADD`) · Empty message `No medicines found. Click "Add Medicine" to create one.` · DA `Dialog Closed` (Event Dialog Closed · Region `Medicines` · Refresh Region `Medicines`). CSS v11 (`hms.css`+`hms.min.css`).

## PART C — Page 941 (form)
Create Page ▸ Form ▸ Form ▸ Page `941` `Medicine` ▸ **Modal Dialog** ▸ Navigation: don't use ▸ Table `HMS_PHARMA_ITEM` ▸ PK `ITEM_ID` ▸ Columns: sob 20 ta (ITEM_ID ... IS_ACTIVE), CREATED_BY/CREATED_DATE/UPDATED_BY/UPDATED_DATE **bad**. Form region Source = **Table `HMS_PHARMA_ITEM`** (SQL na).
Page: Title `Medicine` · Group Setup · Dialog Width `960` · Authorization `AUTH_SETUP`.
**Region 1 `Medicine Details`** (seq 10): ITEM_ID Hidden 10 · ITEM_CODE Display Only `Medicine Code` Default `(Auto)` span 3, 20 · ITEM_NAME Text `Medicine Name` Required span 9, 30 · GENERIC_ID Select (`SELECT GENERIC_NAME d, GENERIC_ID r FROM HMS_PHARMA_GENERIC WHERE IS_ACTIVE='Y' ORDER BY 1`, Null `- Select -`, Required) span 6, 40 · PH_CATEGORY_ID Select (`SELECT CATEGORY_NAME d, PH_CATEGORY_ID r FROM HMS_PHARMA_CATEGORY WHERE IS_ACTIVE='Y' ORDER BY 1`, Required) span 6, 50 · MANUFACTURER_ID Select (`SELECT MANUFACTURER_NAME d, MANUFACTURER_ID r FROM HMS_PHARMA_MANUFACTURER WHERE IS_ACTIVE='Y' ORDER BY 1`) span 6, 60 · STRENGTH Text, Placeholder `e.g. 500 mg`, span 3, 70 · DOSAGE_FORM Select (`SELECT LOOKUP_VALUE d, LOOKUP_VALUE r FROM HMS_LOOKUP_MASTER WHERE LOOKUP_TYPE='DOSAGE_FORM' AND IS_ACTIVE='Y' ORDER BY DISPLAY_ORDER`, Required) span 3, 80 · UNIT_OF_MEASURE Select static Pcs/Strip/Bottle/Vial/Amp/Bag/Tube/Box, Default `Pcs`, span 3, 90 · PACK_SIZE Number Default 1 Min 1 span 3, 95.
**Region 2 `Pricing & Stock`** (seq 20): PURCHASE_PRICE Number `Buy Price (Tk)` Min 0 span 3 · MRP Number `MRP (Tk)` Required Min 0 span 3 · VAT_PERCENT Number `VAT %` Default 0 Min 0 Max 100 span 3 · REORDER_LEVEL Number `Reorder Level` Default 0 Min 0 span 3 · BARCODE Text `Barcode` icon `fa-barcode` span 6 · RACK_NO Text `Rack No` span 6.
**Region 3 `Classification`** (seq 30): IS_NARCOTIC Switch `Narcotic` Default N · IS_ANTIBIOTIC Switch `Antibiotic` Default N · REQUIRES_PRESCRIPTION Switch `Requires Prescription` Default **Y** · IS_ACTIVE Switch `Active` Default Y — sob Y/N, Value Required Off, span 3.
Validations: `MRP >= Buy price` (Expression PL/SQL `:P941_MRP IS NULL OR :P941_PURCHASE_PRICE IS NULL OR TO_NUMBER(:P941_MRP) >= TO_NUMBER(:P941_PURCHASE_PRICE)`, Error `MRP cannot be less than the buy price.`, Item P941_MRP — number item e Format Mask dibenna) · `Duplicate medicine` (No Rows returned):
```sql
SELECT 1 FROM HMS_PHARMA_ITEM
 WHERE UPPER(ITEM_NAME) = UPPER(:P941_ITEM_NAME)
   AND NVL(UPPER(STRENGTH),'-') = NVL(UPPER(:P941_STRENGTH),'-')
   AND NVL(DOSAGE_FORM,'-') = NVL(:P941_DOSAGE_FORM,'-')
   AND ITEM_ID <> NVL(:P941_ITEM_ID,-1)
```
Error `This medicine (name, strength and form) already exists.` · Item P941_ITEM_NAME.
Buttons: CANCEL (Close, Defined by DA) · DELETE **muche din** · SAVE `Save` (Hot, Next, `P941_ITEM_ID` NOT NULL) · CREATE `Add Medicine` (Hot, Next, `P941_ITEM_ID` NULL).
Test: Add `Test Med`, Generic Paracetamol, Category Tablet, Form Tablet, MRP 5 ▸ code `MED-0002x` auto; same again ▸ duplicate error; MRP < Buy ▸ error. Cleanup `DELETE FROM HMS_PHARMA_ITEM WHERE ITEM_NAME='Test Med'; COMMIT;`

## Problems
- Items 0 row (error chara): category khali → seed e category ache; check `SELECT COUNT(*) FROM HMS_PHARMA_CATEGORY` = 8.
- Item missing in Rendering tree (GENERIC_ID etc.): wizard column shuttle e select hoy ni → region ▸ Create Page Item, Source ▸ Type **Database Column** ▸ Column Name.
- Category column name `PH_CATEGORY_ID` (`CATEGORY_ID` noy).
