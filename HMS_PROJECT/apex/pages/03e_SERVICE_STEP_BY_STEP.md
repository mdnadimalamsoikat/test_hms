# Sprint 3 — Service Master (Page 92 + 921) — Ek ek step (APEX 24.2)

Table `HMS_SERVICE_MASTER` (+ `HMS_SERVICE_CATEGORY`). Page 92 = list (IR), Page 921 = modal form (width 960).
Seed data: `database/08_master_data/03_insert_services.sql` (re-runnable; SQL Workshop ▸ SQL Scripts). Jodi ORA-00918/partial insert hoy, statement gulo SQL Commands e **ek ek kore** chalan (category → services → ...).

## STEP 0 — Data check
```sql
SELECT 'category' t, COUNT(*) c FROM HMS_SERVICE_CATEGORY
UNION ALL SELECT 'service', COUNT(*) FROM HMS_SERVICE_MASTER
UNION ALL SELECT 'parameter', COUNT(*) FROM HMS_LAB_PARAMETER
UNION ALL SELECT 'range', COUNT(*) FROM HMS_LAB_REFERENCE_RANGE
UNION ALL SELECT 'ward', COUNT(*) FROM HMS_WARD
UNION ALL SELECT 'bed', COUNT(*) FROM HMS_BED
```
Expected: 14 / 26 / 9 / 10 / 4 / 36.

## STEP 1 — Page 92 (list)
Create Page ▸ Report ▸ Interactive Report ▸ Page 92 `Services` ▸ SQL Query:
```sql
SELECT s.SERVICE_ID, s.SERVICE_CODE, s.SERVICE_NAME, c.CATEGORY_NAME, d.DEPT_NAME,
       s.BASE_CHARGE, s.EMERGENCY_CHARGE, s.REPORTING_SECTION,
       CASE s.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END AS STATUS_TXT, s.IS_ACTIVE
  FROM HMS_SERVICE_MASTER s
  JOIN HMS_SERVICE_CATEGORY c ON c.CATEGORY_ID = s.CATEGORY_ID
  LEFT JOIN HMS_DEPARTMENT d ON d.DEPT_ID = s.DEPT_ID
```
(Chat theke copy korle `s.IS_ACTIVE` link hoye jete pare — `[` / `http://` thakle muche din.)
SERVICE_ID, IS_ACTIVE = Hidden Column · Page Group Setup · Authorization `AUTH_SETUP`.

## STEP 2 — Page 921 basic (form)
Source = **Table** `HMS_SERVICE_MASTER` (SQL na). Delete items `P921_CREATED_BY/CREATED_DATE/UPDATED_BY/UPDATED_DATE`.
Page: Title `Service`, Page Group `Setup`, Dialog Width `960`, Authorization `AUTH_SETUP`. Region Title `Service Details`.

| Item | Type | Key settings |
|---|---|---|
| P921_SERVICE_ID | Hidden | seq 10 |
| P921_SERVICE_CODE | Text Field | Code · Required · Text Case Upper · Row yes, span 4 · seq 20 |
| P921_SERVICE_NAME | **Text Field** (wizard makes Textarea) | Required · span 8 · seq 30 |
| P921_SHORT_NAME | Text Field | Row yes, span 4 · seq 40 |
| P921_CATEGORY_ID | Select List | LOV `SELECT CATEGORY_NAME d, CATEGORY_ID r FROM HMS_SERVICE_CATEGORY WHERE IS_ACTIVE='Y' ORDER BY DISPLAY_ORDER` · Display Null `- Select -` · Required · span 4 · seq 50 |
| P921_DEPT_ID | Select List | LOV `SELECT DEPT_NAME d, DEPT_ID r FROM HMS_DEPARTMENT WHERE IS_ACTIVE='Y' ORDER BY 1` · Display Null `- None -` · span 4 · seq 60 |
| P921_IS_ACTIVE | Switch | Y/N · Default Static Y · Value Required **Off** · seq 70 |

## STEP 3 — Region `Charges & Tax`
New static region `Charges & Tax` (Static ID `service_charges`, seq 20, template Blank with Attributes). Items move into it (item ▸ Layout ▸ Region):

| Item | Type | Key settings |
|---|---|---|
| P921_BASE_CHARGE | Number Field | Label `Base Charge (Tk)` · Required · Default Static `0` · Format Mask `999G999G990D00` · Min 0 · span 3 · seq 10 |
| P921_EMERGENCY_CHARGE | Number Field | Label `Emergency Charge (Tk)` · Format Mask `999G999G990D00` · Min 0 · span 3 · row no · seq 20 |
| P921_TAX_APPLICABLE | Switch | Y/N · Default Static `N` · Value Required Off · span 3 · seq 30 |
| P921_TAX_PERCENT | Number Field | Label `Tax %` · Default Static `0` · Min 0 · Max 100 · Format Mask `990D00` · span 3 · seq 40 |

Dynamic Action `Tax toggle` (Event Change · Item `P921_TAX_APPLICABLE` · Client-side Condition Item = Value `Y`):
True ▸ **Show** `P921_TAX_PERCENT` (Fire on Initialization **Yes**) · False ▸ **Hide** `P921_TAX_PERCENT` + **Set Value** Static `0`.

## STEP 4 — Region `Lab & Sample` (Static ID `service_lab`, seq 30)
| Item | Type | Key settings |
|---|---|---|
| P921_REPORTING_SECTION | Text Field with Autocomplete | Label `Reporting Section` · LOV SQL (static sections UNION existing `REPORTING_SECTION`) · Search Type Contains & Ignore Case · span 3 · seq 10 |
| P921_TURN_AROUND_TIME | Text Field | Label `Report Time` · Placeholder `e.g. 4 Hours` · span 3 · seq 20 |
| P921_SAMPLE_REQUIRED | Switch | Y/N · Default `N` · Required Off · span 3 · seq 30 |
| P921_SAMPLE_TYPE | Select List | Static: Blood, Urine, Stool, Sputum, Swab, Tissue, Fluid · Null `- Select -` · span 3 · seq 40 |

DA `Sample toggle` (Change on SAMPLE_REQUIRED, condition = `Y`): True ▸ Show SAMPLE_TYPE (init On) · False ▸ Hide (init On) + Clear (init Off).
Validation `Sample type required` (Expression PL/SQL): `:P921_SAMPLE_REQUIRED = 'N' OR :P921_SAMPLE_TYPE IS NOT NULL` · Error `Please select a Sample Type.` · Item P921_SAMPLE_TYPE.

## STEP 5 — Region `Other Settings` (Static ID `service_other`, seq 40)
| Item | Type | Key settings |
|---|---|---|
| P921_IS_PACKAGE | Switch | Label `Package` · Y/N · Default N · Required Off · Row yes, span 3 · seq 10 |
| P921_CONSENT_REQUIRED | Switch | Label `Consent Required` · Default N · span 3 · seq 20 |
| P921_DOCTOR_COMMISSION_APPLICABLE | Switch | Label `Doctor Commission` · Default N · span 3 · seq 30 |
| P921_GENDER_SPECIFIC | Select List | Label `Gender` · Static: Male→MALE, Female→FEMALE · Null `All (no restriction)` · span 3 · seq 40 |
| P921_IS_OUTSOURCED | Switch | Label `Outsourced` · Default N · Row yes, span 3 · seq 50 |
| P921_OUTSOURCE_LAB | Text Field | Label `Outsource Lab` · span 5 · seq 60 |
| P921_OUTSOURCE_COST | Number Field | Label `Outsource Cost (Tk)` · Format Mask `999G999G990D00` · Min 0 · span 4 · seq 70 |

DA `Outsource toggle` (Change on IS_OUTSOURCED, condition = `Y`): True ▸ Show OUTSOURCE_LAB + OUTSOURCE_COST (init On) · False ▸ Hide (init On) + Clear (init Off).
Validation `Outsource lab required` (Expression PL/SQL): `:P921_IS_OUTSOURCED = 'N' OR :P921_OUTSOURCE_LAB IS NOT NULL` · Error `Please enter the outsource lab name.` · Item P921_OUTSOURCE_LAB.

## STEP 6 — Page 921 buttons, validation, test
- Buttons: CANCEL (Position Close, Action Defined by Dynamic Action) · **DELETE button muche din** (service bill/lab e use hoy — Active switch diye bondho korun) · SAVE (Label `Save`, Hot, Condition `P921_SERVICE_ID` Item is NOT NULL) · CREATE (Label `Add Service`, Hot, Condition `P921_SERVICE_ID` Item is NULL).
- Validation `Unique code` (Type **No Rows returned**, SQL Query, Item `P921_SERVICE_CODE`, condition lagbe na):
```sql
SELECT 1 FROM HMS_SERVICE_MASTER
 WHERE SERVICE_CODE = :P921_SERVICE_CODE AND SERVICE_ID <> NVL(:P921_SERVICE_ID,-1)
```
  Error `This code already exists.`
- Test: Run 921 ▸ Code `TEST-01`, Name `Test Service`, Category Consultation, Base Charge 100 ▸ Add Service. Check `SELECT * FROM HMS_SERVICE_MASTER WHERE SERVICE_CODE='TEST-01'`. Same code again ▸ error. Cleanup: `DELETE FROM HMS_SERVICE_MASTER WHERE SERVICE_CODE='TEST-01'; COMMIT;`
- ORA-01400 (NULL into SERVICE_ID / CREATED_DATE): run `database/11_apex_support/07_default_on_null_ids.sql` v3 again.

## STEP 7 — Page 92 design (CSS v8 + columns)
CSS: `hms.css` + `hms.min.css` v8 (`.hms-code`, `.hms-cat`, price right-align) → replace in APEX Shared Components ▸ Static Application Files, Ctrl+F5.
SQL (add `c.CATEGORY_TYPE`):
```sql
SELECT s.SERVICE_ID, s.SERVICE_CODE, s.SERVICE_NAME, c.CATEGORY_NAME, c.CATEGORY_TYPE, d.DEPT_NAME,
       s.BASE_CHARGE, s.EMERGENCY_CHARGE, s.REPORTING_SECTION,
       CASE s.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END AS STATUS_TXT, s.IS_ACTIVE
  FROM HMS_SERVICE_MASTER s
  JOIN HMS_SERVICE_CATEGORY c ON c.CATEGORY_ID = s.CATEGORY_ID
  LEFT JOIN HMS_DEPARTMENT d ON d.DEPT_ID = s.DEPT_ID
```
Columns: SERVICE_ID = Link (Page 921, Set Items `P921_SERVICE_ID`=`#SERVICE_ID#`, Clear Cache 921, Link Text `<span class="fa fa-edit" aria-label="Edit"></span>`, Heading blank) · SERVICE_CODE HTML Expression `<span class="hms-code">#SERVICE_CODE#</span>` · CATEGORY_NAME HTML Expression `<span class="hms-cat hms-cat-#CATEGORY_TYPE#">#CATEGORY_NAME#</span>` · CATEGORY_TYPE, IS_ACTIVE = Hidden Column · BASE_CHARGE/EMERGENCY_CHARGE right aligned + Format Mask `999G999G990D00` · STATUS_TXT HTML Expression `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>`.
Button `Add Service` (Region Buttons slot, Hot, `fa-plus`, Redirect Page 921, Clear Cache 921, `AUTH_SETUP_ADD`) · Empty message `No services found. Click "Add Service" to create one.` · DA `Dialog Closed` (Event Dialog Closed, Region `Services`, Refresh Region `Services`).
