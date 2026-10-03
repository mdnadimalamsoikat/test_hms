# Sprint 3 — Employee (Page 91 + 911) — Ek ek step (APEX 24.2)

> Doctor Info + Schedule **porer step** (03c). Ekhon shudhu Employee: list + modal form (Personal + Job).
> Agey check: Department toiri ache ✅ · `07_default_on_null_ids.sql` run kora ✅ · `06_photo_mime_cols.sql` run kora (photo er jonno).

## PART A — Wizard
1. **Create Page ▸ Report ▸ Interactive Report ▸ Next**
2. | Field | Value |
   |---|---|
   | Page Number | `91` |
   | Name | `Employees` |
   | Include Form Page | **ON** · Mode **Modal Dialog** · Number `911` · Name `Employee` |
   | Breadcrumb | Yes (parent: *No parent*) |
3. Navigation Menu: **Don't use** ▸ Next
4. Source **Table** `HMS_EMPLOYEE` ▸ PK **EMPLOYEE_ID**. Columns (Shuttle) — sudhu ei gula:
   `EMPLOYEE_ID, BRANCH_ID, DEPT_ID, DESIGNATION_ID, EMPLOYEE_CODE, FIRST_NAME, LAST_NAME, GENDER, DATE_OF_BIRTH, NID_NUMBER, BLOOD_GROUP, PHOTO, PHONE, EMAIL, PRESENT_ADDRESS, JOINING_DATE, EMPLOYEE_TYPE, REPORTING_TO, BANK_NAME, BANK_ACCOUNT_NO, TIN_NO, IS_ACTIVE`
   (**CREATED_*, UPDATED_* bad**)
5. **Create Page**.

## PART B — Page 91 (list)
**B1. Page:** Title `Employees` · Page Group `Setup` · Authorization `AUTH_SETUP`.

**B2. Region ▸ Source ▸ SQL Query** (purono SQL muche):
```sql
SELECT e.EMPLOYEE_ID, e.EMPLOYEE_CODE,
       TRIM(e.FIRST_NAME||' '||e.LAST_NAME) EMP_NAME,
       d.DEPT_NAME, g.DESIGNATION_NAME, e.PHONE, e.JOINING_DATE, e.EMPLOYEE_TYPE,
       CASE WHEN EXISTS (SELECT 1 FROM HMS_DOCTOR x WHERE x.EMPLOYEE_ID = e.EMPLOYEE_ID)
            THEN 'Doctor' END IS_DOCTOR,
       e.IS_ACTIVE,
       CASE e.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END STATUS_TXT
  FROM HMS_EMPLOYEE e
  JOIN HMS_DEPARTMENT  d ON d.DEPT_ID = e.DEPT_ID
  JOIN HMS_DESIGNATION g ON g.DESIGNATION_ID = e.DESIGNATION_ID
 WHERE e.BRANCH_ID = :G_BRANCH_ID
```
**B3. Columns** (Attributes ▸ Columns):
| Column | Kora |
|---|---|
| EMPLOYEE_ID | Type **Link** ▸ Page **911** ▸ Set Items `P911_EMPLOYEE_ID` = `#EMPLOYEE_ID#` ▸ Clear Cache 911 ▸ Link Text `<span class="fa fa-edit"></span>` ▸ Heading faka |
| EMPLOYEE_CODE | Heading `Code` |
| EMP_NAME | Heading `Name` |
| DEPT_NAME / DESIGNATION_NAME | Heading `Department` / `Designation` |
| PHONE | Heading `Phone` |
| JOINING_DATE | Heading `Joined` ▸ Format Mask `DD/MM/YYYY` |
| EMPLOYEE_TYPE | Heading `Type` |
| IS_DOCTOR | Heading `Role` ▸ HTML Expression `<span class="hms-badge ADMITTED">#IS_DOCTOR#</span>` (faka hole kichu dekhabe na) |
| IS_ACTIVE | **Hidden Column** |
| STATUS_TXT | Heading `Status` ▸ HTML Expression `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>` |

**B4. Button:** `Add Employee` · Hot · Icon `fa-user-plus` · Redirect Page **911** (Clear Cache 911) · Authorization `AUTH_SETUP_ADD`.
**B5. No data message:** `Kono employee nai. "Add Employee" chepe notun toiri korun.`
**B6. Dialog Closed DA:** wizard dey — check: Event *Dialog Closed* ▸ Refresh region `Employees`.

## PART C — Page 911 (modal form)
**C1. Page:** Title `Employee` · Page Group `Setup` · Dialog ▸ **Width `960`** · Authorization `AUTH_SETUP`.

**C2. Regions** (2 ta, ekta niche arekta):
1. Wizard er region rename ▸ Title `Personal Information` · Template **Standard**.
2. Create Region ▸ Title `Job & Bank` · Type **Static Content** · Template **Standard** · Sequence Personal er pore. *(Item gula Personal region theke drag kore ei region e niye jaben — Page Designer e item drag-drop kore region e rakha jay.)*

**C3. Items — sob item Template ▸ `Optional - Floating` (Required gula `Required - Floating`)**

*Region 1: Personal Information*
| Item | Type | Label | Kora |
|---|---|---|---|
| P911_EMPLOYEE_ID | Hidden | – | PK (wizard) |
| P911_BRANCH_ID | Hidden | – | Default ▸ Item `G_BRANCH_ID` |
| P911_EMPLOYEE_CODE | **Display Only** | Employee Code | Default Static `(Auto)` · **Settings ▸ Save Session State = Yes** · Source ▸ *Used* **Always, replacing any existing value in session state** · **Required Off** · Span 3 |
| P911_FIRST_NAME | Text Field | First Name | Required · Start New Row No · Span 4 |
| P911_LAST_NAME | Text Field | Last Name | Span 5 |
| P911_GENDER | **Radio Group** | Gender | LOV **SQL**: `SELECT D,R FROM VW_LOV_LOOKUP WHERE LOOKUP_TYPE='GENDER' ORDER BY DISPLAY_ORDER` · Number of Columns 3 · Display Extra/Null **Off** · Template Option *Item Group Display* **Display as Pill Button** · Start New Row Yes · Span 4 |
| P911_DATE_OF_BIRTH | Date Picker | Date of Birth | **Format `DD/MM/YYYY`** · Max Date `+0d` · Span 4 |
| P911_BLOOD_GROUP | Select List | Blood Group | LOV SQL `... LOOKUP_TYPE='BLOOD_GROUP'` · Null `- Select -` · Span 4 |
| P911_NID_NUMBER | Text Field | NID | Span 4 · New Row Yes |
| P911_PHONE | Text Field (Subtype **Telephone**) | Phone | Required · Placeholder `01XXXXXXXXX` · Span 4 |
| P911_EMAIL | Text Field (Subtype **Email**) | Email | Span 4 |
| P911_PRESENT_ADDRESS | Textarea | Present Address | Rows 2 · Span 12 · New Row Yes |
| P911_PHOTO | **Image Upload** | Photo | Storage **BLOB column specified in Item Source** · MIME Type Column `PHOTO_MIME` · Filename Column `PHOTO_FILENAME` · Display ▸ Preview 120x120 · Max 2MB · New Row Yes · Span 6 |

*Region 2: Job & Bank*
| Item | Type | Label | Kora |
|---|---|---|---|
| P911_DEPT_ID | Select List | Department | LOV SQL `SELECT D,R FROM VW_LOV_DEPARTMENT WHERE BRANCH_ID=:G_BRANCH_ID ORDER BY D` · **Required** · Null `- Select -` · Span 4 |
| P911_DESIGNATION_ID | Select List | Designation | LOV SQL `SELECT DESIGNATION_NAME d, DESIGNATION_ID r FROM HMS_DESIGNATION WHERE IS_ACTIVE='Y' ORDER BY DESIGNATION_LEVEL, 1` · **Required** · Span 4 |
| P911_EMPLOYEE_TYPE | Select List | Employee Type | Static: `Permanent;PERMANENT,Contract;CONTRACT,Visiting;VISITING,Intern;INTERN,Trainee;TRAINEE` · Default `PERMANENT` · Span 4 |
| P911_JOINING_DATE | Date Picker | Joining Date | **Required** · Format `DD/MM/YYYY` · Default ▸ PL/SQL Expression `TO_CHAR(SYSDATE,'DD/MM/YYYY')` · Span 4 · New Row Yes |
| P911_REPORTING_TO | Popup LOV | Reports To | LOV SQL `SELECT TRIM(FIRST_NAME||' '||LAST_NAME)||' ('||EMPLOYEE_CODE||')' d, EMPLOYEE_ID r FROM HMS_EMPLOYEE WHERE IS_ACTIVE='Y' AND EMPLOYEE_ID <> NVL(:P911_EMPLOYEE_ID,-1) ORDER BY 1` · Display As **Modal Dialog** · Span 4 |
| P911_BANK_NAME | Text Field | Bank | Span 4 · New Row Yes · **Authorization `AUTH_SUPER`** |
| P911_BANK_ACCOUNT_NO | Text Field | Account No | Span 4 · **AUTH_SUPER** |
| P911_TIN_NO | Text Field | TIN | Span 4 · **AUTH_SUPER** |
| P911_IS_ACTIVE | **Switch** | Active | On `Y` / Off `N` · Default Static `Y` · New Row Yes |

> Item **Authorization** = item ▸ Security ▸ Authorization Scheme.
> Bank/TIN `AUTH_SUPER` — sudhu admin dekhbe.

**C4. Buttons:**
| Button | Position | Kora |
|---|---|---|
| CANCEL | Close | Cancel Dialog |
| SAVE (`Save`) | Next | Hot · Condition `P911_EMPLOYEE_ID` NOT NULL |
| CREATE (`Add Employee`) | Next | Hot · Condition `P911_EMPLOYEE_ID` IS NULL |
| DELETE | – | **Remove kore din** (employee delete korle doctor/user FK bhenge jay) — **Active switch off** i delete |

**C5. Process — Employee Code auto (ARP er AGE)**
Processing tab ▸ Processing ▸ right-click ▸ **Create Process**:
| Property | Value |
|---|---|
| Name | `Generate Employee Code` |
| Type | **Execute Code** |
| PL/SQL | `:P911_EMPLOYEE_CODE := FN_GET_NEXT_NO(:G_BRANCH_ID,'EMPLOYEE');` |
| Sequence | **5** (wizard er *Process form Employee* er **age** — oita 10 ba 20 hole thik) |
| Server-side Condition ▸ When Button Pressed | **CREATE** |

> Item er Default e na, process e rakhar karon: form khulleii number kharach hoy, Cancel korleo (EMP-00001 → 00003 gap).

**C6. Validation — Phone** (Validating ▸ Create Validation):
Type **Expression** (PL/SQL) · `REGEXP_LIKE(REPLACE(REPLACE(:P911_PHONE,' '),'-'),'^(\+?880)?01[3-9][0-9]{8}$')` · Error `Sothik mobile number din (01XXXXXXXXX)` · Associated Item `P911_PHONE` · When Button CREATE, SAVE.

## PART D — ✅ Test
1. Page 91 Run ▸ **Add Employee**.
2. Name `Rahim Uddin` · Gender Male · Phone `01712345678` · Dept (jekono) · Designation `Medical Officer` · Joining aj ▸ **Add Employee**.
3. Dialog bondho · list e `EMP-00001` dekha jabe (Active badge).
4. Pencil click ▸ Blood Group select ▸ Save ▸ code ager i thake (`EMP-00001`).
5. Wrong phone `123` ▸ error.
6. Photo upload ▸ Save ▸ abar khule preview.

## Problem hole
| Problem | Fix |
|---|---|
| ORA-01400 ...EMPLOYEE_ID/CREATED_DATE | `07_default_on_null_ids.sql` run + form e CREATED_*/UPDATED_* item nai check |
| ORA-01400 ...EMPLOYEE_CODE | Process `Generate Employee Code` er Sequence ARP er **age**, Condition CREATE; Item Save Session State = Yes |
| ORA-20001 Number series not configured: EMPLOYEE | `SELECT * FROM HMS_NUMBER_SERIES WHERE SERIES_TYPE='EMPLOYEE'` — nai hole `08_master_data/01_insert_core_master.sql` er number series insert run |
| ORA-02290 check constraint | EMPLOYEE_TYPE / GENDER value guide er static list er hubohu |
| ORA-01843 not a valid month | Date Picker Format `DD/MM/YYYY` |
| Department dropdown khali | Department ache? `SELECT * FROM VW_LOV_DEPARTMENT` |
| Photo e error | `06_photo_mime_cols.sql` run kora hoyeche? |
