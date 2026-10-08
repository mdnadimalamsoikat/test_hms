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

## PART D — Success message (Add / Update) + newest-first list
**D1. Success message** — wizard er `Process form Medicine` e `Success Message` ache kintu dialog close hole dekhay na / Add-Update alada hoy na. Solution: duplicate message bad, dui ta chhoto PL/SQL process.
1. Page 941 ▸ Processing ▸ `Process form Medicine` ▸ **Success Message** = (faka kore din).
2. Right-click Processing ▸ Create Process:
   - Name `Msg added` · Type **Execute Code** (PL/SQL) · Sequence **ARP er pore, `Close Dialog` er age** · Server-side Condition **When Button Pressed = CREATE**:
```sql
DECLARE
    l_code HMS_PHARMA_ITEM.ITEM_CODE%TYPE;
BEGIN
    SELECT ITEM_CODE INTO l_code FROM HMS_PHARMA_ITEM WHERE ITEM_ID = :P941_ITEM_ID;
    apex_application.g_print_success_message :=
        apex_escape.html(l_code || ' - ' || :P941_ITEM_NAME) || ' added successfully.';
EXCEPTION WHEN NO_DATA_FOUND THEN
    apex_application.g_print_success_message := 'Medicine added successfully.';
END;
```
   - Name `Msg updated` · same Type/Sequence · Condition **When Button Pressed = SAVE**:
```sql
BEGIN
    apex_application.g_print_success_message :=
        apex_escape.html(:P941_ITEM_NAME) || ' updated successfully.';
END;
```
**D2. Newest first** — IR e SQL `ORDER BY` kaj kore na (user sort/default report override kore; ward IG te ORDER BY remove kora hoyechhe). Solution: Page 94 ke Developer hishebe run ▸ Actions ▸ Data ▸ Sort ▸ Column `Code` ▸ Direction **Descending** ▸ Apply ▸ Actions ▸ Report ▸ **Save Report ▸ As Default Report Settings** (Primary). (Code `MED-00021` > `MED-00020`, zero-padded tai desc = newest first.)

## PART E — Code gulo ki kaj kore (bujhe nin, porer bar nijei likhte parben)

1. **Page 94 SQL** (`FROM HMS_PHARMA_ITEM i LEFT JOIN ...generic g ... manufacturer m`)
   - *Keno:* item table e sudhu ID thake (`GENERIC_ID = 3`). Manush ke naam dekhate hole onno table theke naam ante hoy = **JOIN**.
   - *LEFT JOIN keno:* manufacturer faka thakle-o oshudh ta list e thakbe. Normal JOIN e oi row **hariye jay**.
   - `CASE i.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END` → DB te `Y/N`, user ke dekhay `Active/Inactive`.
   - *Fol:* prottek oshudh = 1 row, ID er jaygay naam.
2. **HTML Expression** `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>`
   - `#COLUMN#` = prottek row er nijer value boshe. Class `hms-st-Y` ke CSS (`hms.css`) shobuj rong dey, `hms-st-N` lal. Fol: rongin Active/Inactive tag.
3. **Edit link** (Set Items `P941_ITEM_ID = #ITEM_ID#`, Clear Cache `941`)
   - Click kora row er ID form e pathay; form oi ID diye table theke row anay (**Fetch Row**). Clear Cache purono value muche dey, tai "Add" e faka form ashe.
4. **LOV** `SELECT GENERIC_NAME d, GENERIC_ID r ...`
   - `d` = display (user dekhe naam), `r` = return (DB te ID jay → Foreign Key). `WHERE IS_ACTIVE='Y'` = inactive ta dropdown e ashe na. `ORDER BY 1` = naam A–Z.
5. **Validation MRP >= Buy**: `:P941_MRP IS NULL OR ... OR TO_NUMBER(:P941_MRP) >= TO_NUMBER(:P941_PURCHASE_PRICE)`
   - Expression **TRUE hole pass**. Page item sob text, tai `TO_NUMBER` na dile "9" > "10" hoye jay (text compare). NULL guard: faka thakle error dey na (Required alada check kore).
   - *Keno:* kom daame bikri = hospital er loss.
6. **Validation Duplicate** (type *No Rows returned*)
   - Query jodi **kono row dey = error**. Same naam+strength+form (UPPER = boro/choto hater farak ignore).
   - `NVL(STRENGTH,'-')`: SQL e `NULL = NULL` **false**; NVL na dile strength faka oshudh er duplicate dhora porto na.
   - `ITEM_ID <> NVL(:P941_ITEM_ID,-1)`: **Edit** e nijeke nijer duplicate bole na ... **Add** e ID faka, tai `-1` (kono real ID na).
7. **Success message process**: `apex_application.g_print_success_message := ...`
   - APEX er bilt-in variable; ja boshabe parent page e shobuj bar e dekhabe. `SELECT ITEM_CODE ...` keno: code ta **trigger banay insert er por**, tai save er por table theke poro. `apex_escape.html` = naam e `<script>` thakle-o safe (**XSS** theke bachay).
8. **Trigger `TRG_PHARMA_ITEM_CODE_BI`** (DB e)
   - Insert er thik age ITEM_CODE faka/`(Auto)` hole `MED-` + sequence (5 digit) boshay. Page/Import/API jei insert korbe, **rule ek**. Page process e likhle onno path e bhul hoto.
9. **Dialog Closed DA → Refresh**: form dialog bondho hole browser list region tazа kore, tai notun row dekha jay.
