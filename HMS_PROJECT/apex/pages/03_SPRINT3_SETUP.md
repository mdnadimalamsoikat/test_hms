# SPRINT 3 — Setup / Master / Security (Page 90–98)

🎯 **Ei sprint e ki hobe:** Department, Doctor, Schedule, Service/Price, User/Role — OPD/Billing/Lab er age ei master data lagbe.

## Shuru-r age (check)
- [ ] **DB fix:** `database/11_apex_support/07_default_on_null_ids.sql` run (nahole form save e `ORA-01400: cannot insert NULL into ..._ID`)
- [ ] Sprint 1 complete
- [ ] AUTH_SETUP*, AUTH_SECURITY, AUTH_SUPER scheme

**Build order:** 90/901 Dept → 91/911 Employee + Doctor + Schedule → 92/921 Service → 93 Ward/Bed → 94/941 Medicine → 95/951 User → 96 Role → 97 Settings → 98 Audit (karon employee er jonno dept, doctor er jonno employee lage)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Master page = **Report + Modal Form** pair. Prothom ta (Department) puro detail e; baki gula same pattern + ja alada.
Page group banan: **Shared Components ▸ Page Groups ▸ Create** `Setup` — protiti setup page ▸ Identification ▸ Page Group = Setup (organize).

## 🎨 Design standard (Setup page gulo — sob page e ekoi look)
> Sprint 2 er moto `hms.css` + `hms.min.css` (notun v5) **duita-i** replace kore Ctrl+F5 korun.

| Jaygay | Ki korben | Kano |
|---|---|---|
| Page title | Page ▸ Title e chhoto, bujhar moto naam (`Departments`, `Users & Access`) · Page Group **Setup** | Breadcrumb + nil title bar auto |
| List page (IR) | Region ▸ Appearance ▸ Template **Standard** · Icon `fa-building-o` (page er jonno alada) · Toolbar e **Search bar** rakhun, baki column sob dekhabe na — prothome **6–8 ta** column dekhan, baki *Actions ▸ Columns* e | Kom column = dekhte sundor, druto bujha jay |
| Active/Inactive | Plain `Y/N` na — **badge** (`hms-badge hms-st-Y` Active sobuj, `hms-st-N` Inactive dhusor) | Ek nojore status |
| Summary strip | Page 90/95 er upore choto **KPI card** (nicher *Dynamic Content* region) | Dashboard feel |
| Modal form | Dialog **Width 720** (choto) / **960** (boro) · Footer e buttons: Cancel (bame), Delete (danger), Save (Hot, dane) | Standard software pattern |
| Form item | Sob item **Template Optional - Floating**, Y/N gulo **Switch**, choto option (Gender) **Radio Pill** | Modern look |
| Grid row | IG te `Edit ▸ Enabled`, toolbar e *Save* **Hot**, Actions ▸ Report ▸ Save as Default | |
| Date | Date Picker **Format `DD/MM/YYYY`** shob jaygay (Sprint 2 er ORA-01843 er shikkha) | |
| Empty state | Report ▸ Messages ▸ *No data found*: `Kono data nai. "Add" chepe notun toiri korun.` | |

**Summary strip region** (Page 90 / 95 / 91 er upore) — Region ▸ Type **Dynamic Content** ▸ PL/SQL Function Body returning CLOB, Template **Blank with Attributes**, Static ID `summary`:
```plsql
DECLARE
  l_tot NUMBER; l_act NUMBER; l_clin NUMBER;
BEGIN
  SELECT COUNT(*), SUM(CASE WHEN IS_ACTIVE='Y' THEN 1 ELSE 0 END),
         SUM(CASE WHEN DEPT_TYPE='CLINICAL' THEN 1 ELSE 0 END)
    INTO l_tot, l_act, l_clin
    FROM HMS_DEPARTMENT WHERE BRANCH_ID = :G_BRANCH_ID;
  RETURN '<div class="hms-kpi-row">'
    || '<div class="hms-kpi blue"><div class="hms-kpi-val">'||l_tot||'</div><div class="hms-kpi-lbl">Total Departments</div></div>'
    || '<div class="hms-kpi green"><div class="hms-kpi-val">'||NVL(l_act,0)||'</div><div class="hms-kpi-lbl">Active</div></div>'
    || '<div class="hms-kpi teal"><div class="hms-kpi-val">'||NVL(l_clin,0)||'</div><div class="hms-kpi-lbl">Clinical</div></div>'
    || '</div>';
END;
```
Dialog Closed DA te ei region o **Refresh** korben (Page 90 e). Page 95 (User) er jonno: Total users · Active · **Locked** (`hms-kpi red`) · Never logged in.

---
## PATTERN — Department (Page 90 list + 901 form)

### Create
Create Page ▸ **Interactive Report** ▸ Page 90 ▸ Name `Departments` ▸ ✅ **Include Form Page** ▸ Form Page Number **901** ▸ Form Page Mode **Modal Dialog** ▸ Data Source Table `HMS_DEPARTMENT` ▸ Primary Key `DEPT_ID`.
Wizard 2 ta page banabe + edit link column.

### Page 90 (list)
- Authorization **AUTH_SETUP**, Page Group Setup
- Region source e SQL change (join kore naam dekhano):
```sql
SELECT d.DEPT_ID, d.DEPT_CODE, d.DEPT_NAME, d.DEPT_TYPE, p.DEPT_NAME PARENT_DEPT,
       TRIM(e.FIRST_NAME||' '||e.LAST_NAME) HOD, d.FLOOR_NO, d.ROOM_NO, d.EXTENSION_NO, d.IS_ACTIVE,
       CASE d.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END STATUS_TXT
  FROM HMS_DEPARTMENT d
  LEFT JOIN HMS_DEPARTMENT p ON p.DEPT_ID = d.PARENT_DEPT_ID
  LEFT JOIN HMS_EMPLOYEE  e ON e.EMPLOYEE_ID = d.HOD_EMPLOYEE_ID
 WHERE d.BRANCH_ID = :G_BRANCH_ID
```
- Column **IS_ACTIVE** ▸ Type **Hidden Column**. Column **STATUS_TXT** ▸ Heading `Status` ▸ HTML Expression `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>` (CSS `hms.css` e ache). DEPT_ID = edit link column (pencil icon) — sundor korte Link ▸ Link Icon `<span aria-label="Edit" class="fa fa-edit"></span>`
- Run ▸ Actions ▸ **Format / Highlight**: IS_ACTIVE = 'N' → gray row ▸ Actions ▸ **Save Report ▸ As Default Report Settings (Primary)** (developer hisebe) — sobai ei layout dekhbe
- Attributes ▸ Download: CSV, HTML, PDF, **XLSX** ON
- Button CREATE (wizard toiri) ▸ Label `Add Department` ▸ Hot ▸ fa-plus ▸ Authorization **AUTH_SETUP_ADD**

### Page 901 (modal form)
- Dialog Width **720** · Authorization AUTH_SETUP
- Delete: CREATED_*/UPDATED_* items
| Item | Type | Setting |
|---|---|---|
| P901_BRANCH_ID | Hidden | Default Item G_BRANCH_ID |
| P901_DEPT_CODE | Text | Required, Text Case Upper, Span 4 |
| P901_DEPT_NAME | Text | Required, Span 8 (New Row No) |
| P901_DEPT_TYPE | Select List | Static `Clinical;CLINICAL,Non-Clinical;NON_CLINICAL,Diagnostic;DIAGNOSTIC,Admin;ADMIN,Support;SUPPORT,Pharmacy;PHARMACY,Lab;LAB` (DB CHECK er sathe mile) |
| P901_PARENT_DEPT_ID | Select List | `SELECT DEPT_NAME d, DEPT_ID r FROM HMS_DEPARTMENT WHERE BRANCH_ID=:G_BRANCH_ID AND DEPT_ID <> NVL(:P901_DEPT_ID,-1) ORDER BY 1` |
| P901_HOD_EMPLOYEE_ID | Popup LOV | `SELECT TRIM(FIRST_NAME||' '||LAST_NAME)||' ('||EMPLOYEE_CODE||')' d, EMPLOYEE_ID r FROM HMS_EMPLOYEE WHERE IS_ACTIVE='Y'` |
| P901_FLOOR_NO / ROOM_NO / EXTENSION_NO | Text | Span 4 each |
| P901_IS_ACTIVE | **Switch** | On `Y` Off `N`, Default Y |
- Buttons: CANCEL (Cancel Dialog) · DELETE (Danger, confirm, AUTH_SUPER) · SAVE / CREATE (Hot)
- Validation: `Unique code` ▸ Type *No Rows returned* ▸ `SELECT 1 FROM HMS_DEPARTMENT WHERE DEPT_CODE=:P901_DEPT_CODE AND BRANCH_ID=:G_BRANCH_ID AND DEPT_ID<>NVL(:P901_DEPT_ID,-1)` ▸ `Ei code age theke ache`
- Processes: ARP (wizard) → Close Dialog (wizard)
- Page 90 e: **[DA] Dialog Closed** ▸ Selection Type Region (report) ▸ True: Refresh region (wizard 24.2 nijei dey, check korun)

✅ Add/edit/deactivate department.

---
## PAGE 91 / 911 — Employee + Doctor
Create Page ▸ IR + Form (91/911, Modal, width **960**), table `HMS_EMPLOYEE`.
911 layout: **Tabs Container** er bhitore 3 sub-region:
1. **Personal** – EMPLOYEE_CODE (**Display Only** `(Auto)` — save er somoy toiri hobe, niche dekhun), FIRST/LAST_NAME, GENDER (radio pill), DOB, NID, BLOOD_GROUP, PHONE, EMAIL, PRESENT_ADDRESS, PHOTO (Image Upload BLOB — ⚠️ `HMS_EMPLOYEE` e MIME column nai; age `database/11_apex_support/06_photo_mime_cols.sql` run korun, tarpor Item ▸ Settings e MIME Type Column `PHOTO_MIME`, Filename `PHOTO_FILENAME`)
2. **Job** – DEPT_ID (VW_LOV_DEPARTMENT), DESIGNATION_ID (`SELECT DESIGNATION_NAME d, DESIGNATION_ID r FROM HMS_DESIGNATION ORDER BY DESIGNATION_LEVEL`), JOINING_DATE, EMPLOYEE_TYPE (Select Static `Permanent;PERMANENT,Contract;CONTRACT,Visiting;VISITING,Intern;INTERN,Trainee;TRAINEE` — DB CHECK er sathe mile), REPORTING_TO (popup employee), BANK_NAME / BANK_ACCOUNT_NO / TIN_NO (Authorization AUTH_SUPER)
3. **Doctor Info** (Condition: designation doctor type ba switch `P911_IS_DOCTOR`) – non-table items:
   `P911_IS_DOCTOR` (Switch), `P911_DOCTOR_CODE`, `P911_SPECIALIZATION`, `P911_QUALIFICATION`, `P911_BMDC_REG_NO`, `P911_CONSULTATION_FEE`, `P911_FOLLOWUP_FEE`, `P911_FOLLOWUP_VALID_DAYS`, `P911_DOCTOR_TYPE` (Select: FULL_TIME, PART_TIME, VISITING, CONSULTANT, RESIDENT)
   - Source ▸ Type **Null** (form table er na), load: Pre-Rendering process `SELECT ... INTO :P911_... FROM HMS_DOCTOR WHERE EMPLOYEE_ID=:P911_EMPLOYEE_ID` (exception no_data_found null)
   - **[Process] Save Doctor** (after ARP, when IS_DOCTOR='Y'):
```plsql
MERGE INTO HMS_DOCTOR d USING (SELECT :P911_EMPLOYEE_ID EID FROM DUAL) x ON (d.EMPLOYEE_ID = x.EID)
WHEN MATCHED THEN UPDATE SET DOCTOR_CODE=:P911_DOCTOR_CODE, SPECIALIZATION=:P911_SPECIALIZATION,
     QUALIFICATION=:P911_QUALIFICATION, BMDC_REG_NO=:P911_BMDC_REG_NO, CONSULTATION_FEE=:P911_CONSULTATION_FEE,
     FOLLOWUP_FEE=:P911_FOLLOWUP_FEE, FOLLOWUP_VALID_DAYS=:P911_FOLLOWUP_VALID_DAYS, DOCTOR_TYPE=:P911_DOCTOR_TYPE
WHEN NOT MATCHED THEN INSERT (EMPLOYEE_ID, DOCTOR_CODE, SPECIALIZATION, QUALIFICATION, BMDC_REG_NO,
     CONSULTATION_FEE, FOLLOWUP_FEE, FOLLOWUP_VALID_DAYS, DOCTOR_TYPE)
     VALUES (:P911_EMPLOYEE_ID, :P911_DOCTOR_CODE, :P911_SPECIALIZATION, :P911_QUALIFICATION, :P911_BMDC_REG_NO,
     :P911_CONSULTATION_FEE, :P911_FOLLOWUP_FEE, :P911_FOLLOWUP_VALID_DAYS, :P911_DOCTOR_TYPE);
```
   ARP e **Return Primary Key(s) after Insert = Yes** (EMPLOYEE_ID pawar jonno).
4. **Doctor Schedule** (sub-region, Condition doctor exists): Interactive Grid on `HMS_DOCTOR_SCHEDULE WHERE DOCTOR_ID = (SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID=:P911_EMPLOYEE_ID)`
   - DAY_OF_WEEK Select Static: `Sunday;SUNDAY,Monday;MONDAY,Tuesday;TUESDAY,Wednesday;WEDNESDAY,Thursday;THURSDAY,Friday;FRIDAY,Saturday;SATURDAY`
   - START_TIME/END_TIME Text (Placeholder `09:00`, validation regex `^[0-2][0-9]:[0-5][0-9]$`)
   - SLOT_DURATION_MIN default 10, MAX_SLOTS 30, BRANCH_ID default G_BRANCH_ID, DOCTOR_ID default (PL/SQL expression above)

**Employee Code auto (save e toiri — gap hoy na):** Processing ▸ ARP er **age** (Sequence 5) `[Process] Generate Employee Code` · Execute Code · When Button Pressed **CREATE**:
```plsql
:P911_EMPLOYEE_CODE := FN_GET_NEXT_NO(:G_BRANCH_ID,'EMPLOYEE');   -- EMP-00001
```
(Item P911_EMPLOYEE_CODE ▸ Type Display Only ▸ **Save Session State = Yes** ▸ Source ▸ Used **Always, replacing any existing value in session state**.)
> ⚠️ Item Default e `FN_GET_NEXT_NO` dile form **khulleii** number kharach hoy (Cancel korleo) — tai save e korun.

**Doctor Code:** `HMS_DOCTOR.DOCTOR_CODE` NOT NULL, kintu `DOCTOR` number series nai. `P911_DOCTOR_CODE` ▸ Default PL/SQL Expression (create e) `'DR-' || :P911_EMPLOYEE_CODE`, Required. Ba Save Doctor process e `NVL(:P911_DOCTOR_CODE, 'DR-'||:P911_EMPLOYEE_CODE)`.

Page 91 IR source: employee + dept + designation + `CASE WHEN EXISTS(doctor) THEN 'Doctor' END`.

---
## PAGE 92 / 921 — Service Master (+ Lab parameter)
IR + Form, table `HMS_SERVICE_MASTER`, 921 width 960.
- CATEGORY_ID Select `SELECT CATEGORY_NAME d, CATEGORY_ID r FROM HMS_SERVICE_CATEGORY ORDER BY 1`
- DEPT_ID VW_LOV_DEPARTMENT · BASE_CHARGE / EMERGENCY_CHARGE Number (Format `999G999G990D00`)
- Y/N columns (TAX_APPLICABLE, SAMPLE_REQUIRED, IS_PACKAGE, IS_OUTSOURCED, CONSENT_REQUIRED, DOCTOR_COMMISSION_APPLICABLE) → **Switch**
- REPORTING_SECTION Select Static `Hematology,Biochemistry,Microbiology,Serology,Histopathology,Radiology,Cardiology`
- SAMPLE_TYPE Select `Blood,Urine,Stool,Sputum,Swab,Tissue` · Server-side? Client **[DA]** show only when SAMPLE_REQUIRED = Y (Show/Hide)
- **Sub-region Lab Parameters** (Condition `:P921_SERVICE_ID IS NOT NULL`): IG `HMS_LAB_PARAMETER WHERE SERVICE_ID=:P921_SERVICE_ID` (PARAMETER_CODE, NAME, UNIT, RESULT_TYPE select NUMERIC/TEXT/OPTION/MEMO, GROUP_NAME, DISPLAY_ORDER)
- **Page 922 Reference Range** (modal, IG): open from parameter row link → `HMS_LAB_REFERENCE_RANGE WHERE PARAMETER_ID=:P922_PARAMETER_ID` (GENDER select MALE/FEMALE/ALL, AGE_FROM_DAYS, AGE_TO_DAYS, MIN, MAX, CRITICAL_LOW/HIGH, NORMAL_TEXT)

---
## PAGE 93 — Ward & Bed (Master-Detail)
Create Page ▸ **Master Detail** ▸ Style **Stacked** ▸ Master `HMS_WARD` (PK WARD_ID) ▸ Detail `HMS_BED` (FK WARD_ID).
- Master IG: WARD_CODE, WARD_NAME, WARD_TYPE (Select: GENERAL, CABIN, ICU, CCU, NICU, PICU, HDU, ISOLATION, MATERNITY, POST_OP, EMERGENCY), FLOOR_NO, GENDER_ALLOWED, DEPT_ID, BRANCH_ID (hidden default), IS_ACTIVE switch
- Detail IG: BED_NO, BED_TYPE (Select Static `General;GENERAL,Cabin AC;CABIN_AC,Cabin Non-AC;CABIN_NON_AC,Suite;SUITE,ICU;ICU,CCU;CCU,NICU;NICU,Cradle;CRADLE`), DAILY_CHARGE, SERVICE_ID (VW_LOV_SERVICE WHERE category BED), BED_STATUS (**Read-only** · default `AVAILABLE` · DB: AVAILABLE/OCCUPIED/RESERVED/MAINTENANCE/CLEANING), IS_ACTIVE
- Master where: `BRANCH_ID = :G_BRANCH_ID`
- Authorization AUTH_SETUP

## PAGE 94 / 941 — Medicine Master
IR + Form `HMS_PHARMA_ITEM`. GENERIC_ID popup (`SELECT GENERIC_NAME d, GENERIC_ID r FROM HMS_PHARMA_GENERIC`), PH_CATEGORY_ID select, MANUFACTURER_ID popup, DOSAGE_FORM LOOKUP 'DOSAGE_FORM', MRP/PURCHASE_PRICE number, IS_NARCOTIC / IS_ANTIBIOTIC / REQUIRES_PRESCRIPTION switch, BARCODE text (icon fa-barcode).
Extra small pages (IG only, one page 945 with 3 tabs): **Generic**, **Manufacturer**, **Supplier** (`HMS_PHARMA_SUPPLIER`), **Store** (`HMS_PHARMA_STORE`).

---
## PAGE 95 / 951 — User Management (security critical)
Page 95 IR:
```sql
SELECT u.USER_ID, u.USERNAME, TRIM(e.FIRST_NAME||' '||e.LAST_NAME) EMPLOYEE,
       (SELECT LISTAGG(r.ROLE_NAME, ', ') WITHIN GROUP (ORDER BY r.ROLE_NAME)
          FROM HMS_USER_ROLE ur JOIN HMS_ROLE r ON r.ROLE_ID=ur.ROLE_ID
         WHERE ur.USER_ID=u.USER_ID AND ur.IS_ACTIVE='Y') ROLES,
       u.LAST_LOGIN, u.FAILED_ATTEMPTS, u.IS_LOCKED, u.IS_ACTIVE
  FROM HMS_USER u LEFT JOIN HMS_EMPLOYEE e ON e.EMPLOYEE_ID=u.EMPLOYEE_ID
```
IS_LOCKED = 'Y' → red highlight. Authorization **AUTH_SECURITY**.
Badge: SQL e `CASE WHEN u.IS_LOCKED='Y' THEN 'Locked' WHEN u.IS_ACTIVE='Y' THEN 'Active' ELSE 'Inactive' END STATUS_TXT, CASE WHEN u.IS_LOCKED='Y' THEN 'LOCK' ELSE u.IS_ACTIVE END STATUS_CLS` → HTML Expression `<span class="hms-badge hms-st-#STATUS_CLS#">#STATUS_TXT#</span>`.

Page 951 — **Blank Page** (Form wizard na — password hash er jonno), Modal 640:
| Item | Type | Note |
|---|---|---|
| P951_USER_ID | Hidden | |
| P951_USERNAME | Text | Required, Upper; edit mode e Read Only (`:P951_USER_ID IS NOT NULL`) |
| P951_EMPLOYEE_ID | Popup LOV | employee |
| P951_EMAIL / P951_MOBILE | Text | |
| P951_PASSWORD | Password | Condition create only; Required |
| P951_ROLES | **Checkbox Group** (ba Shuttle) | `SELECT ROLE_NAME d, ROLE_ID r FROM HMS_ROLE WHERE IS_ACTIVE='Y' ORDER BY 1` · multiple value `:` separated |
| P951_IS_ACTIVE | Switch | |
Pre-Rendering Load (when USER_ID not null):
```plsql
SELECT USERNAME, EMPLOYEE_ID, EMAIL, MOBILE, IS_ACTIVE INTO :P951_USERNAME, :P951_EMPLOYEE_ID, :P951_EMAIL, :P951_MOBILE, :P951_IS_ACTIVE
  FROM HMS_USER WHERE USER_ID = :P951_USER_ID;
SELECT LISTAGG(ROLE_ID, ':') WITHIN GROUP (ORDER BY ROLE_ID) INTO :P951_ROLES
  FROM HMS_USER_ROLE WHERE USER_ID = :P951_USER_ID AND IS_ACTIVE='Y';
```
Buttons & processes:
| Button | Process |
|---|---|
| CREATE | (Password min **8 character** — PKG_AUTH rule; `FORCE_PWD_CHANGE` DB default `Y`, alada update lagbe na) `:P951_USER_ID := PKG_AUTH.create_user(:P951_USERNAME, :P951_PASSWORD, :G_BRANCH_ID, :P951_EMPLOYEE_ID, NULL);` then Save Roles |
| SAVE | `UPDATE HMS_USER SET EMPLOYEE_ID=:P951_EMPLOYEE_ID, EMAIL=:P951_EMAIL, MOBILE=:P951_MOBILE, IS_ACTIVE=:P951_IS_ACTIVE WHERE USER_ID=:P951_USER_ID;` then Save Roles |
| RESET_PWD (`Reset Password`, confirm) | `PKG_AUTH.reset_password(:P951_USERNAME, 'Hms@' || TO_CHAR(SYSDATE,'YYYY')); UPDATE HMS_USER SET FORCE_PWD_CHANGE='Y' WHERE USER_ID=:P951_USER_ID;` Success `Temporary password: Hms@2026` |
| UNLOCK | `UPDATE HMS_USER SET IS_LOCKED='N', FAILED_ATTEMPTS=0 WHERE USER_ID=:P951_USER_ID;` (Condition locked) |
**Save Roles** process (CREATE, SAVE):
```plsql
DELETE FROM HMS_USER_ROLE WHERE USER_ID = :P951_USER_ID;
INSERT INTO HMS_USER_ROLE (USER_ID, ROLE_ID)
SELECT :P951_USER_ID, TO_NUMBER(COLUMN_VALUE) FROM TABLE(APEX_STRING.SPLIT(:P951_ROLES, ':'));
```
Then **Close Dialog**. Validation: username unique (No Rows returned), password rule (Sprint 1 er motoi).

---
## PAGE 96 — Role & Permission ⭐
**Create Page ▸ Blank** 96, Authorization **AUTH_SUPER**.
- `P96_ROLE_ID` Select List (roles) ▸ Page Action on Selection **Submit Page**? → Na, **Redirect and Set Value**? Simple: DA Change → Refresh IG.
- **[Region] Permissions** Interactive Grid, Static ID `perm_ig`, SQL:
```sql
SELECT rp.PERMISSION_ID, m.MODULE_ID, m.MODULE_NAME, rp.ROLE_ID,
       NVL(rp.CAN_VIEW,'N') CAN_VIEW, NVL(rp.CAN_ADD,'N') CAN_ADD, NVL(rp.CAN_EDIT,'N') CAN_EDIT,
       NVL(rp.CAN_DELETE,'N') CAN_DELETE, NVL(rp.CAN_PRINT,'N') CAN_PRINT, NVL(rp.CAN_APPROVE,'N') CAN_APPROVE
  FROM HMS_APP_MODULE m
  LEFT JOIN HMS_ROLE_PERMISSION rp ON rp.MODULE_ID = m.MODULE_ID AND rp.ROLE_ID = :P96_ROLE_ID
 WHERE m.IS_ACTIVE = 'Y'
 ORDER BY m.DISPLAY_ORDER
```
  Page Items to Submit `P96_ROLE_ID` · Edit Enabled (**Update only**) · MODULE_NAME Display Only · PERMISSION_ID, MODULE_ID, ROLE_ID Hidden · primary key column = MODULE_ID
  CAN_* columns ▸ Type **Switch** (On Y / Off N)
  Save target ▸ **PL/SQL Code**:
```plsql
MERGE INTO HMS_ROLE_PERMISSION t
USING (SELECT :P96_ROLE_ID ROLE_ID, :MODULE_ID MODULE_ID FROM DUAL) s
   ON (t.ROLE_ID = s.ROLE_ID AND t.MODULE_ID = s.MODULE_ID)
 WHEN MATCHED THEN UPDATE SET CAN_VIEW=:CAN_VIEW, CAN_ADD=:CAN_ADD, CAN_EDIT=:CAN_EDIT,
      CAN_DELETE=:CAN_DELETE, CAN_PRINT=:CAN_PRINT, CAN_APPROVE=:CAN_APPROVE, IS_ACTIVE='Y'
 WHEN NOT MATCHED THEN INSERT (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_EDIT, CAN_DELETE, CAN_PRINT, CAN_APPROVE)
      VALUES (s.ROLE_ID, s.MODULE_ID, :CAN_VIEW, :CAN_ADD, :CAN_EDIT, :CAN_DELETE, :CAN_PRINT, :CAN_APPROVE);
```
- [DA] P96_ROLE_ID Change → Refresh `perm_ig`
- Button SAVE (Hot) → Action *Defined by DA*? IG er nijer Save button use korun (toolbar), ba page button → Submit + *Interactive Grid - Automatic Row Processing* process (wizard toiri).
- Role add: small IG region upore `HMS_ROLE` (ROLE_CODE, ROLE_NAME, IS_ACTIVE).

✅ RECEPTION role e PHARMACY view off → oi user er menu te Pharmacy nai.

---
## PAGE 97 — System Settings (3 tabs, IG each)
Tabs Container: **Config** (`HMS_SYSTEM_CONFIG WHERE BRANCH_ID=:G_BRANCH_ID`) · **Number Series** (`HMS_NUMBER_SERIES` — CURRENT_NO read-only, AUTH_SUPER) · **Lookup** (`HMS_LOOKUP_MASTER`, filter on LOOKUP_TYPE) · **Branch** (`HMS_BRANCH` form, LOGO image upload).

## PAGE 98 — Audit Trail Viewer
Faceted Search on `HMS_AUDIT_TRAIL` (read only), facets: TABLE_NAME, ACTION_TYPE, ACTION_BY, ACTION_TIME range. Authorization **AUTH_SUPER**. Column OLD_VALUE / NEW_VALUE truncate 100 char.
Tab 2 (optional): `HMS_LOGIN_HISTORY` report · Tab 3: `HMS_ERROR_LOG` (developer debug).

## Sprint 3 checklist
- [ ] Dept, Employee+Doctor+Schedule, Service+Parameter+Range, Ward/Bed, Medicine, Supplier, Store
- [ ] User create → login with new user → force pwd change
- [ ] Role permission change → menu change
- [ ] **Test data dhukan**: 3 dept, 3 doctor (schedule shoho), 10 service (5 lab with parameter/range), 2 ward 10 bed, 20 medicine, 1 store — Sprint 4 er jonno lagbe
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| LOV khali | Age er master e data nai (jemon Dept na thakle Employee te dept list khali) |
| Check constraint error (ORA-02290) | Select List er value guide er static list theke hubohu (boro hater) |
| Notun user login korte pare na | User e role assign + FORCE_PWD_CHANGE='Y' hole Page 2 ashbe (Sprint 1 E, F) |
| Employee/Doctor save e ORA-02290 (EMPLOYEE_TYPE/DOCTOR_TYPE) | Select List static value guide er list theke hubohu (upper case, `_` shoho) |
| Employee code e gap (EMP-00001, 00003...) | Code Item Default e na, save er somoy *Generate Employee Code* process e (upore) |
| Date ORA-01843 | Date Picker Format `DD/MM/YYYY` + TO_DATE mask ek |
| Modal title/color purono | `hms.css` **ar** `hms.min.css` duita-i replace + Ctrl+F5 |
| Save e `ORA-01400: cannot insert NULL into (...._ID)` | APEX ID e NULL pathay, DEFAULT SEQ.NEXTVAL kaj kore na → `07_default_on_null_ids.sql` run (DEFAULT ON NULL) |
