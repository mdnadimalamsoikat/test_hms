# PHASE 2 — Complete APEX 24.2 Application Guide (Design + All Modules)

> DB = Oracle 19c · UI = **APEX 24.2** · Theme = **Universal Theme 42 – Redwood Light**
> Principle (plan): **Business logic DB package e, APEX shudhu UI.** Tai form er default DML er bodole package call.

## Contents
- [0. Login fix + DB helper](#0)
- [1. Design system (APEX 24.2)](#1)
- [2. Sprint 1 – Foundation](#s1)
- [3. Sprint 2 – Patient](#s2)
- [4. Sprint 3 – Setup/Master](#s3)
- [5. Sprint 4 – Appointment + OPD](#s4)
- [6. Sprint 5 – Billing](#s5)
- [7. Sprint 6 – IPD](#s6)
- [8. Sprint 7 – Lab](#s7)
- [9. Sprint 8 – Pharmacy](#s8)
- [10. Sprint 9 – Reports / Print](#s9)
- [11. Sprint 10 – Baki module pattern](#s10)
- [12. Page number map](#map)

---
<a id="0"></a>
## 0. LOGIN FIX + DB helper (age eta)

**Keno login hocche na:** Authentication Scheme e *Post-Authentication Procedure* = `PKG_APP_SESSION.POST_AUTH` deya, kintu oi package DB te banano hoyni (`11_apex_support/01_apex_support.sql` chalano hoyni). APEX login er pore oi procedure call kore → na pele error → login fail.

HMS_APP diye **ei order e** chalan:
```sql
@C:\HMS_PROJECT\database\11_apex_support\00_LOGIN_FIX.sql     -- PKG_AUTH + PKG_APP_SESSION + ADMIN reset + test
@C:\HMS_PROJECT\database\11_apex_support\02_pkg_lab.sql       -- Lab workflow package
@C:\HMS_PROJECT\database\11_apex_support\03_apex_views.sql    -- Page source view
```
`00_LOGIN_FIX` er output e **`LOGIN TEST : SUCCESS`** dekhben → APEX e `ADMIN / Admin@12345`.

Still fail? APEX e check:
1. Shared Components → Authentication Schemes → *HMS Login* → **Current** lekha ache?
2. Authentication Function Name: `PKG_AUTH.AUTHENTICATE` (sudhu naam, `;`/parameter na)
3. Post-Authentication Procedure Name: `PKG_APP_SESSION.POST_AUTH`
4. App → Edit Application Properties → Security → *Parsing Schema* = **HMS_APP**
5. Debug: login page URL e `&debug=YES` → Monitor Activity → Debug message

---
<a id="1"></a>
## 1. DESIGN SYSTEM (APEX 24.2)

### 1.1 Theme
Shared Components → **Themes** → Universal Theme → Theme Style: **Redwood Light** (24.2 default, modern Oracle look).
Redwood Light e Theme Roller e shudhu kichu option (Header/Navigation Light-Dark) ache, **Primary color / Border radius nai** (Oracle Redwood design lock kora).
Tai:
1. Theme Roller → Header: **Light**, Navigation: **Light** (ba pochondo) → Save As `HMS Blue` → **Set as Current**
2. Blue color + rounded corner ashbe `apex/static/hms.css` er *THEME OVERRIDE* block theke (Static file upload + CSS File URL, section 1.2).
   Alternative: oi block copy → Theme Roller → **Custom CSS** → paste → Save.
3. Theme Roller e shob color nije set korte chaile Theme Style **Vita** select korun (Vita te Global Colors ache).

### 1.2 User Interface Attributes
Shared Components → User Interface Attributes:
- Logo: Text `🏥 HMS` ba Image `#APP_FILES#logo.png`
- Navigation Menu: Side, List **HMS Menu**
- Navigation Bar: user name `&G_FULL_NAME.`, Change Password (page 2), Sign Out
- CSS File URLs: `#APP_FILES#hms.css` · JS: `#APP_FILES#hms.js`
- Static Application Files e upload: `apex/static/hms.css` **ar** `apex/static/hms.min.css` (dutoi lagbe), `apex/static/hms.js`, logo
  - CSS File URL: `#APP_FILES#hms#MIN#.css` (jodi file `static/` folder e thake: `#APP_FILES#static/hms#MIN#.css`) — **#MIN# mane:** normal run e `hms.min.css`, Debug on e `hms.css` load hoy. Tai CSS change korle **duita file-i replace** korben, nahole notun design ashbe na.
  - `hms.min.css` = `hms.css` er comment/space bad deya version. Repo te duita-i ache; CSS edit korle min abar toiri korun (python/online minifier).

### 1.3 Globalization (Bangladesh)
Edit Application Properties → Globalization:
- Primary Language: English (en) · Application Date Format: `DD-MON-YYYY` · Timestamp: `DD-MON-YYYY HH12:MIPM`
- Automatic Time Zone: No (server Asia/Dhaka)

### 1.4 Page design standard (sob page e same)
| Page type | Layout |
|---|---|
| **List page** (search) | Page template *Standard*, Breadcrumb bar e title + **Create** button (Hot, icon `fa-plus`), body te Interactive Report / Faceted Search |
| **Form page** | *Modal Dialog* (master) ba *Standard* (transaction). Region template **Standard**, Items label *Floating* (Redwood), 2-column (Column Span 6) |
| **Transaction page** (OPD, Sale, Bill) | Top e **Patient banner** (hms-banner), bame form, dane summary card (sticky) |
| **Dashboard** | Cards (KPI) + Charts + Classic report, 12-col grid |
| **Print** | Blank page template, `@media print` CSS, `window.print()` button |

Button standard: Save = Hot/Primary, Cancel = default, Delete = Danger + *Confirm*. Icon: `fa-save`, `fa-times`, `fa-trash-o`, `fa-print`.
Status badge: `<span class="hms-badge #STATUS#">#STATUS#</span>`
Required item: Value Required = Yes (red * CSS e ache).
Number/Tk: Format Mask `FML999G999G990D00` → Tk er jonno Column heading `(Tk)`.

### 1.5 Global Page (Page 0)
- Region *Patient Banner* (Static, Condition: `:P0_PATIENT_ID IS NOT NULL` – optional)
- DA: Page Load → `hms.enterAsTab();` (sob form e Enter = next field)

---
<a id="s1"></a>
## 2. SPRINT 1 — Foundation  (Page 1, 2, 9999)

### 2.1 App
App Builder → Create → New Application → Name `Hospital Management System`, ID **100**, Theme **Redwood Light**, Schema **HMS_APP**.

### 2.2 Application Items
`G_USER_ID`, `G_BRANCH_ID`, `G_EMPLOYEE_ID`, `G_ROLES`, `G_FULL_NAME`, `G_FORCE_PWD` → Session State Protection **Restricted – May not be set from browser**.

### 2.3 Authentication
Authentication Schemes → Create → *Based on pre-configured scheme* → Custom:
- Authentication Function Name: `PKG_AUTH.AUTHENTICATE`
- Post-Authentication Procedure Name: `PKG_APP_SESSION.POST_AUTH`
- Session Not Valid → Login page · **Make Current**

Login page (9999) design: Page → Region *Login* → Template Options: *Login* region, Title `Hospital Management System`, Icon `fa-hospital-o`. Username item label `User ID`.

### 2.4 Authorization Schemes (Exists SQL Query, Once per page view) — detail: pages/01_SPRINT1_FOUNDATION.md §B
Protiti module er jonno 1 ta VIEW + 1 ta ADD:
```
AUTH_<MODULE>      :  select 1 from dual where PKG_APP_SESSION.can_yn('<MODULE>') = 'Y'
AUTH_<MODULE>_ADD  :  select 1 from dual where PKG_APP_SESSION.can_yn('<MODULE>','ADD') = 'Y'
AUTH_<MODULE>_EDIT :  select 1 from dual where PKG_APP_SESSION.can_yn('<MODULE>','EDIT') = 'Y'
```
MODULE = DASHBOARD, PATIENT, APPOINTMENT, OPD, IPD, LAB, PHARMACY, BILLING, REPORTS, SETUP, SECURITY (+ baki pore).
`AUTH_SUPER` : Exists SQL Query on HMS_USER/HMS_USER_ROLE/HMS_ROLE (ROLE_CODE='SUPER_ADMIN') — see Sprint 1 §B

### 2.5 Navigation Menu (dynamic, role wise)
Shared Components → Lists → Create → From Scratch → `HMS Menu`, **Dynamic**:
```sql
SELECT LEVEL, MODULE_NAME label,
       CASE WHEN APEX_PAGE_NO IS NOT NULL THEN APEX_PAGE.GET_URL(p_page => APEX_PAGE_NO) END target,
       NULL is_current, 'fa ' || ICON_CLASS image
  FROM VW_APEX_MENU
 WHERE PKG_APP_SESSION.can_yn(MODULE_CODE) = 'Y'
 START WITH PARENT_MODULE_ID IS NULL
CONNECT BY PRIOR MODULE_ID = PARENT_MODULE_ID
 ORDER SIBLINGS BY DISPLAY_ORDER
```
User Interface Attributes → Navigation Menu List = `HMS Menu`.

### 2.6 Page 1 – Dashboard
Region 1 **Cards** (Title "Today") – source:
```sql
SELECT 'New Patients' lbl, NEW_PATIENTS_TODAY val, 'blue' clr, 'fa-user-plus' ico, 11 pg FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 'OPD Today',   OPD_TODAY,       'green', 'fa-stethoscope', 21 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 'OPD Waiting', OPD_WAITING,     'orange','fa-clock-o',     21 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 'Admitted',    IPD_CURRENT,     'purple','fa-bed',         42 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 'Beds Free',   BEDS_AVAILABLE,  'teal',  'fa-check',       41 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 'Lab Pending', LAB_PENDING,     'red',   'fa-flask',       54 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 'Collection',  COLLECTION_TODAY,'green', 'fa-money',       80 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
```
Cards Attributes → Layout *Grid 4 col* · Title `&VAL.` · Subtitle `&LBL.` · Icon `&ICO.` · **CSS Classes** `hms-kpi &CLR.` · Action: Full Card → Redirect Page `&PG.`

Region 2 **Chart – Bar (stacked)** "Ward Occupancy" (col span 6):
`SELECT WARD_NAME, OCCUPIED, AVAILABLE FROM VW_BED_OCCUPANCY WHERE BRANCH_ID=:G_BRANCH_ID` (2 series)

Region 3 **Chart – Line** "7 din collection" (col span 6):
```sql
SELECT TO_CHAR(COLLECTION_DATE,'DD-Mon') lbl, SUM(NET_COLLECTION) amt
  FROM VW_DAILY_REVENUE WHERE BRANCH_ID=:G_BRANCH_ID AND COLLECTION_DATE >= TRUNC(SYSDATE)-6
 GROUP BY COLLECTION_DATE ORDER BY COLLECTION_DATE
```
Region 4 **Classic Report** "Live OPD Queue": `VW_OPD_DASHBOARD` today; Refresh DA: *Timer* na thakle `setInterval(()=>apex.region('queue').refresh(),30000)` page load e.

Role-wise dashboard: Region → Server-side Condition → Authorization (Pharmacy card shudhu AUTH_PHARMACY).

### 2.7 Page 2 – Change Password (Modal)
Items `P2_OLD_PWD`, `P2_NEW_PWD`, `P2_CONFIRM_PWD` (Password). Validation (Function Returning Error Text):
```plsql
IF :P2_NEW_PWD <> :P2_CONFIRM_PWD THEN RETURN 'Notun password mile nai'; END IF;
IF LENGTH(:P2_NEW_PWD) < 8 OR NOT REGEXP_LIKE(:P2_NEW_PWD,'[0-9]') OR NOT REGEXP_LIKE(:P2_NEW_PWD,'[A-Z]')
THEN RETURN 'Min 8 char, 1 boro hater okkhor + 1 number'; END IF;
RETURN NULL;
```
Process: `PKG_AUTH.change_password(:APP_USER,:P2_OLD_PWD,:P2_NEW_PWD); :G_FORCE_PWD := 'N';` → Close Dialog.
Application Process (On Load Before Header), Condition `:G_FORCE_PWD='Y' AND :APP_PAGE_ID NOT IN (2,9999)`:
`APEX_UTIL.REDIRECT_URL(APEX_PAGE.GET_URL(p_page=>2));`

✅ **Checklist:** login OK · bhul pwd fail · 5 bar → lock · first login e page 2 · menu role-wise · dashboard load.

---
<a id="s2"></a>
## 3. SPRINT 2 — Patient (10, 11, 12)

### Page 11 – Patient Search (Faceted Search – 24.2)
Create Page → **Faceted Search**, source:
```sql
SELECT PATIENT_ID, MRN, PATIENT_NAME, GENDER, AGE, BLOOD_GROUP, PHONE_PRIMARY,
       PATIENT_CATEGORY, REGISTRATION_DATE, TOTAL_OPD_VISITS, CURRENT_ADMISSION_NO, TOTAL_DUE
  FROM VW_PATIENT_SUMMARY WHERE IS_ACTIVE='Y'
```
Facets: Search (MRN, NAME, PHONE), GENDER (checkbox), BLOOD_GROUP, PATIENT_CATEGORY, REGISTRATION_DATE (range).
Result region → change to **Cards**: Title `&PATIENT_NAME.`, Subtitle `&MRN. · &PHONE_PRIMARY.`, Body `&GENDER. · &AGE. · Due Tk &TOTAL_DUE.`, Initials icon, Card link → Page 12 (`P12_PATIENT_ID=&PATIENT_ID.`).
Button `New Patient` (Hot) → Page 10. Authorization page: `AUTH_PATIENT`.

### Page 10 – Patient Registration (Form, Standard)
Create Page → Form → table `HMS_PATIENT`, PK `PATIENT_ID`.
Region layout (3 region, each *Standard* template, collapsible):
1. **Basic Info** – TITLE, FIRST_NAME*, LAST_NAME, GENDER* (Radio, pill style), DATE_OF_BIRTH, AGE_YEARS, BLOOD_GROUP, MARITAL_STATUS, RELIGION
2. **Contact** – PHONE_PRIMARY*, PHONE_SECONDARY, EMAIL, PRESENT_ADDRESS (textarea), PRESENT_DISTRICT, PRESENT_DIVISION, NID_NUMBER
3. **Other** – FATHER_NAME, MOTHER_NAME, EMERGENCY_CONTACT_NAME/PHONE/RELATION, REFERRED_DOCTOR_ID, PATIENT_CATEGORY, PHOTO
LOV pattern: `SELECT D,R FROM VW_LOV_LOOKUP WHERE LOOKUP_TYPE='GENDER' ORDER BY DISPLAY_ORDER` (TITLE/BLOOD_GROUP/RELIGION/MARITAL_STATUS/DIVISION/RELATION)
Doctor: Popup LOV `SELECT D,R FROM VW_LOV_DOCTOR WHERE BRANCH_ID=:G_BRANCH_ID`
Hidden: `P10_BRANCH_ID` default `&G_BRANCH_ID.` · `P10_MRN` Display Only.

Processing: **Automatic Row Processing → Server-side condition: Request = SAVE** (edit only). Notun Process *Register* (Request = CREATE), BEFORE ARP:
```plsql
DECLARE l_mrn VARCHAR2(30);
BEGIN
  :P10_PATIENT_ID := PKG_PATIENT.register_patient(
      p_branch_id=>:G_BRANCH_ID, p_first_name=>:P10_FIRST_NAME, p_last_name=>:P10_LAST_NAME,
      p_gender=>:P10_GENDER, p_phone=>:P10_PHONE_PRIMARY,
      p_dob=>TO_DATE(:P10_DATE_OF_BIRTH, 'DD/MM/YYYY'), p_age_years=>:P10_AGE_YEARS,
      p_blood_group=>:P10_BLOOD_GROUP, p_father_name=>:P10_FATHER_NAME, p_nid=>:P10_NID_NUMBER,
      p_address=>:P10_PRESENT_ADDRESS, p_district=>:P10_PRESENT_DISTRICT,
      p_category=>NVL(:P10_PATIENT_CATEGORY,'GENERAL'), p_ref_doctor_id=>:P10_REFERRED_DOCTOR_ID,
      p_mrn=>l_mrn);
  :P10_MRN := l_mrn;
END;
```
Success: `Patient registered. MRN: &P10_MRN.` · Branch → 12 (`P12_PATIENT_ID=&P10_PATIENT_ID.`)
Validations: phone `REGEXP_LIKE(REPLACE(:P10_PHONE_PRIMARY,' '),'^(\+?880)?01[3-9][0-9]{8}$')` · DOB or Age required.
Duplicate check: Ajax Callback `CHECK_DUPLICATE` (code niche) + DA *Change* on P10_PHONE_PRIMARY → JS `hms.checkDuplicate();`
```plsql
DECLARE l_id NUMBER; l_mrn VARCHAR2(30);
BEGIN
  l_id := PKG_PATIENT.find_duplicate(:P10_PHONE_PRIMARY,:P10_FIRST_NAME,:P10_GENDER);
  IF l_id IS NOT NULL THEN SELECT MRN INTO l_mrn FROM HMS_PATIENT WHERE PATIENT_ID=l_id; END IF;
  APEX_JSON.open_object; APEX_JSON.write('patient_id',l_id); APEX_JSON.write('mrn',l_mrn);
  APEX_JSON.write('url',APEX_PAGE.GET_URL(p_page=>12,p_items=>'P12_PATIENT_ID',p_values=>l_id));
  APEX_JSON.close_object;
END;
```
(Page Items to Submit er jonno hms.js already pageItems pathay.)
DA: DOB change → Set Value (PL/SQL) `P10_AGE_YEARS := TRUNC(MONTHS_BETWEEN(SYSDATE,TO_DATE(:P10_DATE_OF_BIRTH,'DD/MM/YYYY'))/12)` (item Format `DD/MM/YYYY`, Fire on Initialization OFF).

### Page 12 – Patient Profile 360°
Item `P12_PATIENT_ID` hidden. Layout:
- **Hero region** (template *Hero*): Title `&P12_NAME.`, sub `MRN &P12_MRN. · &P12_AGE. · &P12_GENDER. · Blood &P12_BLOOD.`; Pre-rendering process fills P12_* from `VW_PATIENT_SUMMARY`. Allergy thakle red badge.
- Buttons (Hero e): **New OPD Visit** → 20 · **Admit** → 40 (Condition CURRENT_ADMISSION_NO null) · **Lab Order** → 50 · **Edit** → 10 · **Statement** → 72
- **Region Display Selector** (tabs) + sub-regions:
  | Tab | Source |
  |---|---|
  | OPD Visits | `SELECT v.VISIT_NO,v.VISIT_DATE,v.DOCTOR_NAME,v.DEPT_NAME,v.VISIT_STATUS FROM VW_OPD_DASHBOARD v WHERE v.VISIT_ID IN (SELECT VISIT_ID FROM HMS_OPD_VISIT WHERE PATIENT_ID=:P12_PATIENT_ID) ORDER BY v.VISIT_DATE DESC` |
  | Admissions | `SELECT ADMISSION_NO,ADMISSION_DATE,DISCHARGE_DATE,ADMISSION_STATUS FROM HMS_IPD_ADMISSION WHERE PATIENT_ID=:P12_PATIENT_ID` |
  | Lab | `SELECT o.ORDER_NO,o.ORDER_DATE,d.SERVICE_NAME,d.ITEM_STATUS FROM HMS_INVESTIGATION_ORDER o JOIN HMS_INVESTIGATION_ORDER_DTL d ON d.ORDER_ID=o.ORDER_ID WHERE o.PATIENT_ID=:P12_PATIENT_ID` |
  | Bills | `SELECT BILL_NO,BILL_DATE,BILL_TYPE,NET_AMOUNT,PAID_AMOUNT,DUE_AMOUNT,BILL_STATUS FROM VW_BILL_LIST WHERE PATIENT_ID=:P12_PATIENT_ID` |
  | Allergy | **Interactive Grid** editable on `HMS_PATIENT_ALLERGY` (PATIENT_ID default `:P12_PATIENT_ID`) |
  | Timeline | Region *Comments/Timeline* template: union of visit/admission/bill with date |

✅ MRN auto · duplicate popup · profile tabs · audit log entry.

---
<a id="s3"></a>
## 4. SPRINT 3 — Setup / Master (90–97)
Sob master = **Interactive Report (list) + Modal Form** (Create Page → *Report with Form*). Authorization `AUTH_SETUP`.
Master e direct table DML OK (business logic nai), audit trigger already.

| Page | Table | Special |
|---|---|---|
| 90/901 Department | HMS_DEPARTMENT | BRANCH_ID default G_BRANCH_ID; HOD Popup LOV employee |
| 91/911 Employee + Doctor | HMS_EMPLOYEE, HMS_DOCTOR | Form e 2 region; Doctor region condition *Designation doctor type*; Doctor schedule = IG `HMS_DOCTOR_SCHEDULE` (DAY_OF_WEEK select, START_TIME/END_TIME text `HH24:MI`) |
| 92/921 Service Master | HMS_SERVICE_MASTER | Category select; Lab parameter IG (`HMS_LAB_PARAMETER`) + reference range IG (master-detail) |
| 93 Ward + Bed | HMS_WARD (IR) + HMS_BED (**IG master-detail**) | 24.2 Master-Detail *Stacked* |
| 94 Medicine Master | HMS_PHARMA_ITEM | Generic/Category/Manufacturer popup LOV |
| 95 User Management | HMS_USER | **Create e ARP na**: `:P951_USER_ID := PKG_AUTH.create_user(:P951_USERNAME,:P951_PASSWORD,:G_BRANCH_ID,:P951_EMPLOYEE_ID,:P951_ROLE);` · Reset button → `PKG_AUTH.reset_password` · Unlock button → `UPDATE HMS_USER SET IS_LOCKED='N',FAILED_ATTEMPTS=0` · PASSWORD_HASH column **hide** |
| 96 Role & Permission | HMS_ROLE + HMS_ROLE_PERMISSION | IG: MODULE (display), CAN_VIEW/ADD/EDIT/DELETE/PRINT/APPROVE → **Switch** column |
| 97 System Config / Number Series / Lookup | HMS_SYSTEM_CONFIG, HMS_NUMBER_SERIES, HMS_LOOKUP_MASTER | IG editable |
| 98 Audit Log Viewer | HMS_AUDIT_TRAIL | IR read-only, `AUTH_SUPER` |

---
<a id="s4"></a>
## 5. SPRINT 4 — Appointment + OPD (20–23, 30–31)

### Page 30 – Appointment Booking (Modal)
Items: PATIENT_ID (Popup LOV `VW_LOV_PATIENT`, *Manual entry* allowed → walk-in name), MOBILE_NO, DOCTOR_ID (VW_LOV_DOCTOR), APPOINTMENT_DATE, SLOT_TIME (Select, cascading on doctor+date):
```sql
SELECT TO_CHAR(TO_DATE(s.START_TIME,'HH24:MI') + (LEVEL-1)*s.SLOT_DURATION_MIN/1440,'HH24:MI') d,
       TO_CHAR(TO_DATE(s.START_TIME,'HH24:MI') + (LEVEL-1)*s.SLOT_DURATION_MIN/1440,'HH24:MI') r
  FROM HMS_DOCTOR_SCHEDULE s
 WHERE s.DOCTOR_ID=:P30_DOCTOR_ID AND s.IS_ACTIVE='Y'
   AND s.DAY_OF_WEEK = TO_CHAR(TO_DATE(:P30_APPOINTMENT_DATE,'DD-MON-YYYY'),'FMDAY','NLS_DATE_LANGUAGE=ENGLISH')
CONNECT BY LEVEL <= NVL(s.MAX_SLOTS,20) AND PRIOR SYS_GUID() IS NOT NULL AND PRIOR s.SCHEDULE_ID = s.SCHEDULE_ID
MINUS
SELECT SLOT_TIME, SLOT_TIME FROM HMS_APPOINTMENT
 WHERE DOCTOR_ID=:P30_DOCTOR_ID AND APPOINTMENT_DATE=TO_DATE(:P30_APPOINTMENT_DATE,'DD-MON-YYYY')
   AND APPOINTMENT_STATUS NOT IN ('CANCELLED')
```
(Cascading LOV Parent Items: P30_DOCTOR_ID,P30_APPOINTMENT_DATE. DAY_OF_WEEK = SUNDAY..SATURDAY full name.)
Process: `APPOINTMENT_NO := FN_GET_NEXT_NO(:G_BRANCH_ID,'APPOINTMENT')` then ARP insert.

### Page 31 – Appointment Calendar
Region **Calendar** (source `VW_APPOINTMENT_CAL WHERE BRANCH_ID=:G_BRANCH_ID`), Start `START_DT`, Display `PATIENT_NAME || ' - ' || DOCTOR_NAME`, CSS by status (`apex-cal-green` CONFIRMED, `apex-cal-red` CANCELLED). Drag&drop: off. Create link → 30. Filter: Doctor select list (item P31_DOCTOR_ID, `WHERE :P31_DOCTOR_ID IS NULL OR DOCTOR_ID=:P31_DOCTOR_ID`).

### Page 20 – New OPD Visit (Front desk)
Layout 2 column: left form, right **Fee summary card**.
Items: P20_PATIENT_ID (Popup LOV VW_LOV_PATIENT; default from P12), P20_DEPT_ID (VW_LOV_DEPARTMENT, CLINICAL), P20_DOCTOR_ID (cascading on dept: `SELECT D,R FROM VW_LOV_DOCTOR WHERE DEPT_ID=:P20_DEPT_ID`), P20_APPOINTMENT_ID (optional), P20_FEE (Display, DA on doctor change: `SELECT CONSULTATION_FEE FROM VW_LOV_DOCTOR WHERE R=:P20_DOCTOR_ID`), P20_DISCOUNT, P20_PAY_NOW (Y/N switch), P20_PAYMENT_MODE.
Process (Create Visit):
```plsql
DECLARE l_no VARCHAR2(30); l_bill NUMBER; l_rcpt NUMBER;
BEGIN
  :P20_VISIT_ID := PKG_OPD.create_visit(:G_BRANCH_ID, :P20_PATIENT_ID, :P20_DOCTOR_ID, :P20_DEPT_ID,
                                        :P20_APPOINTMENT_ID, NVL(:P20_DISCOUNT,0), l_no, l_bill);
  :P20_VISIT_NO := l_no; :P20_BILL_ID := l_bill;
  IF :P20_PAY_NOW = 'Y' THEN
     SELECT DUE_AMOUNT INTO :P20_DUE FROM HMS_BILLING WHERE BILL_ID = l_bill;
     l_rcpt := PKG_BILLING.receive_payment(l_bill, :P20_DUE, :P20_PAYMENT_MODE, NULL, :G_EMPLOYEE_ID);
  END IF;
END;
```
Success `Visit &P20_VISIT_NO. created` → Branch to print token/receipt page 73.

### Page 21 – OPD Queue (Token display + reception list)
Interactive Report `VW_OPD_DASHBOARD WHERE VISIT_DATE=TRUNC(SYSDATE) AND BRANCH_ID=:G_BRANCH_ID`, Doctor facet, VISIT_STATUS badge, WAITING_MIN > 30 → orange highlight. Auto refresh 30s.
**Token TV screen** (Page 211, Page template *Minimal/No Navigation*, public = no auth optional): big Cards: `TOKEN_NO` title (font 4rem), `DOCTOR_NAME`, current `IN_CONSULTATION`.

### Page 22 – Doctor Consultation (EMR) — main doctor page
Entry: Doctor Dashboard (Page 3 = Cards from `VW_DOCTOR_QUEUE WHERE DOCTOR_EMPLOYEE_ID=:G_EMPLOYEE_ID`) → card click → Process `PKG_OPD.start_consultation(:VISIT_ID)` → page 22.
Layout:
- Top **Patient banner** (hms-banner) + allergy
- Left (span 4): **Vitals** form → button Save → `PKG_OPD.save_vitals(:P22_VISIT_ID,:P22_BP_SYS,:P22_BP_DIA,:P22_PULSE,:P22_TEMP,:P22_SPO2,:P22_WEIGHT,:P22_HEIGHT)`; **Previous visits** list
- Right (span 8) **Tabs**:
  1. *Complaint & Exam* – Form on `HMS_OPD_CONSULTATION` (CHIEF_COMPLAINT, HISTORY_OF_ILLNESS, EXAMINATION_NOTES, PROVISIONAL_DIAGNOSIS, ICD_ID popup LOV `HMS_ICD_MASTER`) — ARP OK
  2. *Prescription* – Interactive Grid on `HMS_OPD_PRESCRIPTION_DTL` (ITEM_ID popup LOV VW_LOV_MEDICINE → MEDICINE_NAME auto, DOSAGE, FREQUENCY select `LOOKUP FREQUENCY`, ROUTE, DURATION_DAYS, MEAL_INSTRUCTION (Before/After), QUANTITY computed). Header row HMS_OPD_PRESCRIPTION auto-create in *Before Header* process if null.
  3. *Investigation* – Shuttle `P22_TESTS` (`VW_LOV_SERVICE WHERE REPORTING_SECTION IS NOT NULL`) → Button *Order* → `PKG_LAB.create_order(...,'OPD',:P22_VISIT_ID,...)` + `PKG_LAB.add_tests(l_id,:P22_TESTS)`
  4. *Advice & Follow-up* – ADVICE, FOLLOWUP_DATE, ADMISSION_ADVISED (switch → button "Admit" → 40)
- Footer buttons: **Save Draft**, **Complete & Print** → `PKG_OPD.complete_visit(:P22_VISIT_ID)` → Page 23

### Page 23 – Prescription Print
Page template *Blank*, Classic Report template *Standard* with custom HTML:
Header (hospital name/logo, doctor name + BMDC, date), patient line, **Rx** list (MEDICINE_NAME · DOSAGE · FREQUENCY · DURATION · meal), Advice, Follow-up, signature. Button `Print` → `window.print()`.

---
<a id="s5"></a>
## 6. SPRINT 5 — Billing (70–73)

### Page 70 – Bill list / Create
Faceted Search `VW_BILL_LIST WHERE BRANCH_ID=:G_BRANCH_ID` (facets BILL_TYPE, BILL_STATUS, BILL_DATE). DUE_AMOUNT > 0 red.
Create Misc Bill (Modal 701): patient + type → `:P701_BILL_ID := PKG_BILLING.create_bill(:G_BRANCH_ID,:P701_PATIENT_ID,:P701_BILL_TYPE);`

### Page 71 – Bill Detail + Payment (cashier screen)
- Banner: Bill no, patient, status
- **IG (read-only)** `HMS_BILLING_DTL WHERE BILL_ID=:P71_BILL_ID AND IS_ACTIVE='Y'`
- Add Item region: SERVICE_ID (VW_LOV_SERVICE), QTY, DISCOUNT → button *Add* → `PKG_BILLING.add_bill_item(:P71_BILL_ID,:P71_SERVICE_ID,NULL,:P71_QTY,NULL,:P71_DISC);`
- Right **Summary card** (Gross, Discount, Net, Paid, **Due** big)
- Discount (AUTH_BILLING_APPROVE): `PKG_BILLING.apply_discount(:P71_BILL_ID,:P71_HDR_DISC,:P71_DISC_REASON,:G_EMPLOYEE_ID);`
- **Payment**: Amount (default due), Mode (LOOKUP PAYMENT_MODE: CASH/CARD/BKASH/NAGAD…), TXN ref (show if not CASH) → `:P71_RECEIPT_ID := PKG_BILLING.receive_payment(:P71_BILL_ID,:P71_AMOUNT,:P71_MODE,:P71_TXN,:G_EMPLOYEE_ID);` → print 73
- Cancel (AUTH_SUPER, confirm): `PKG_BILLING.cancel_bill(:P71_BILL_ID,:P71_REASON);`
Error from package (-201xx) → APEX nijei inline dekhabe (Process Error display: *Inline in Notification*).

### Page 72 – Patient Account Statement
Patient LOV + date range → Classic report (bill + receipt union, running balance with `SUM() OVER (ORDER BY dt)`), Print button.

### Page 73 – Invoice / Money Receipt print
Blank template; hospital header, bill items table, totals, "Paid / Due", *In words* (`TO_CHAR(TO_DATE(TRUNC(amt),'J'),'JSP')`), cashier, QR (optional). CSS A5 size: `@page{size:A5}`.

---
<a id="s6"></a>
## 7. SPRINT 6 — IPD (40–45)

### Page 41 – Bed Map (visual) ⭐
**Cards** region, source `VW_BED_MAP WHERE BRANCH_ID=:G_BRANCH_ID`, *Group by* WARD_NAME (24.2 cards grouping not native → use one Cards region per ward ba order by ward + Classic "Badge List"). Card: Title `&BED_NO.`, Subtitle `&PATIENT_NAME.`, Badge `&BED_STATUS.`, CSS `&STATUS_CSS.` (green free / red occupied / yellow reserved). Layout *Float* small cards.
Action: AVAILABLE → Page 40 (`P40_BED_ID`), OCCUPIED → Page 43 (`P43_ADMISSION_ID`). Facet: Ward, Status.

### Page 40 – Admission
Items: PATIENT_ID (VW_LOV_PATIENT), DEPT, DOCTOR (cascading), BED_ID (Popup LOV `SELECT WARD_NAME||' - '||BED_NO||' (Tk '||DAILY_CHARGE||')' d, BED_ID r FROM VW_BED_MAP WHERE BED_STATUS='AVAILABLE'`), ADMISSION_TYPE (PLANNED/EMERGENCY), REASON, ATTENDANT_NAME/PHONE, ADVANCE, PAYMENT_MODE, OPD_VISIT_ID (hidden).
```plsql
DECLARE l_no VARCHAR2(30);
BEGIN
  :P40_ADMISSION_ID := PKG_IPD.admit_patient(:G_BRANCH_ID,:P40_PATIENT_ID,:P40_DOCTOR_ID,:P40_DEPT_ID,:P40_BED_ID,
        :P40_ADMISSION_TYPE,:P40_REASON,:P40_OPD_VISIT_ID,:P40_ATTENDANT_NAME,:P40_ATTENDANT_PHONE,
        NVL(:P40_ADVANCE,0),:P40_PAYMENT_MODE,l_no);
  :P40_ADMISSION_NO := l_no;
END;
```
→ Admission slip print.

### Page 42 – Current Inpatients
IR `VW_IPD_CURRENT_PATIENTS` (ward, bed, days, due). Row actions (24.2 *Actions menu* column): Round note → 43, Medication → 44, Transfer → 421, Bill → 71, Discharge → 45.

### Page 43 – Patient IPD chart (doctor round + nursing)
Banner + Tabs: *Doctor Round* (IG `HMS_IPD_DOCTOR_VISIT`, DOCTOR_ID default own), *Nursing notes*, *Vitals chart* (Line chart), *Lab results*.
### Page 44 – Medication chart
IG `HMS_IPD_MEDICATION` (order) + IG `HMS_IPD_MED_ADMINISTRATION` (nurse tick given time).
### Page 421 – Bed Transfer (Modal): to-bed LOV available → `PKG_IPD.transfer_bed(:P421_ADMISSION_ID,:P421_BED_ID,:P421_REASON,:G_EMPLOYEE_ID);`
### Page 45 – Discharge
Step 1 form `HMS_DISCHARGE_SUMMARY` (diagnosis, treatment, advice, medication, follow-up) · Step 2 bill check (due card; allow due switch AUTH_SUPER) · Button **Discharge** →
`PKG_IPD.post_bed_charges(:P45_ADMISSION_ID); PKG_IPD.discharge_patient(:P45_ADMISSION_ID,:P45_TYPE,NVL(:P45_ALLOW_DUE,'N'));`
→ Page 451 Discharge Summary print. (APEX 24.2 **Wizard** progress list template use korle 3 step sundor dekhay.)

---
<a id="s7"></a>
## 8. SPRINT 7 — Lab (50–54)

| Page | Design | Logic |
|---|---|---|
| **50 Order Entry** | Patient LOV, Source, Priority (pill), Ref doctor, **Shuttle** tests (VW_LOV_SERVICE, category facet), total Tk DA | `l_id := PKG_LAB.create_order(:G_BRANCH_ID,:P50_PATIENT_ID,:P50_SOURCE,NULL,:P50_ADMISSION_ID,:P50_DOCTOR,:P50_PRIORITY,:P50_NOTES,l_no); PKG_LAB.add_tests(l_id,:P50_TESTS);` → bill 71 |
| **51 Sample Collection** | IR `VW_LAB_PENDING WHERE ITEM_STATUS='ORDERED'`, row button *Collect* | Ajax/Process `:P51_SAMPLE_NO := PKG_LAB.collect_sample(:P51_DTL_ID);` → barcode label print (`<svg>` via JS lib ba plain text) |
| **54 Worklist** | Faceted: section, priority, status; STAT red | – |
| **52 Result Entry** | Header (patient/test) + **Interactive Grid** on `VW_LAB_RESULT_ENTRY WHERE ORDER_DTL_ID=:P52_DTL_ID` (only RESULT_VALUE editable; FLAG colored H red/L blue) | IG *Custom PL/SQL* DML: `PKG_LAB.save_result(:ORDER_DTL_ID,:PARAMETER_ID,:RESULT_VALUE);` · Button *Verify* (AUTH_LAB_APPROVE) → `PKG_LAB.verify_test(:P52_DTL_ID);` |
| **53 Report Print** | Blank template; parameter, result, unit, ref range, flag bold; pathologist sign; only VERIFIED | – |

IG setup for 52: Region Source *SQL Query* → Edit Enabled, Operations Update only → Target Type **PL/SQL Code** (code above). Primary key column: ORDER_DTL_ID + PARAMETER_ID.

---
<a id="s8"></a>
## 9. SPRINT 8 — Pharmacy (60–64)

### Page 60 – POS / Sale ⭐
Design (POS style):
- Top: Sale type (OTC / OPD / IPD pill), Patient LOV (optional), customer name/phone
- **Barcode / search box** (Popup LOV VW_LOV_MEDICINE, *Search on type*) + QTY → Enter → Ajax `ADD_ITEM`
- Middle: Classic Report cart `HMS_PHARMA_SALE_DTL WHERE SALE_ID=:P60_SALE_ID` (batch, expiry, qty, MRP, total, remove icon)
- Right sticky card: Gross / Discount / **Net** / Paid / Change
Processes:
```plsql
-- On first item (P60_SALE_ID null):
:P60_SALE_ID := PKG_PHARMACY.create_sale(:G_BRANCH_ID,:P60_STORE_ID,:P60_SALE_TYPE,:P60_PATIENT_ID,:P60_ADMISSION_ID,:P60_CUSTOMER,:P60_PHONE);
-- Ajax ADD_ITEM:
PKG_PHARMACY.add_sale_item(:P60_SALE_ID,:P60_ITEM_ID,:P60_QTY,NVL(:P60_ITEM_DISC,0));
-- Finalize button:
PKG_PHARMACY.finalize_sale(:P60_SALE_ID,:P60_PAID,:P60_PAYMENT_MODE);
```
Stock kom → package error → notification. FEFO batch auto (package).
Store: `P60_STORE_ID` default from `HMS_PHARMA_STORE` (branch main).

| Page | Type | Notes |
|---|---|---|
| 61 Purchase Order | Master-Detail (PO + PO_DTL IG) | PO_NO = FN_GET_NEXT_NO(branch,'PO') |
| 62 GRN | Master-Detail (GRN + GRN_DTL IG: item, batch, expiry, qty, cost, MRP) | Button *Post* → `PKG_PHARMACY.post_grn(:P62_GRN_ID);` (stock in) |
| 63 Stock | IR `VW_PHARMA_STOCK_STATUS` (low stock red, near expiry orange), chart by category | |
| 64 Expiry Alert | Cards: 30/60/90 din er moddhe expiry | |
| 65 Return | Sale no search → line → `PKG_PHARMACY.return_item(:DTL_ID,:QTY,:REASON)` | |

---
<a id="s9"></a>
## 10. SPRINT 9 — Reports / MIS (80–86)
Sob report: Page item filter (From/To date, Branch, Doctor) + **Interactive Report** (Download CSV/PDF/Excel on) + chart.
| Page | Source |
|---|---|
| 80 Daily Revenue | `VW_DAILY_REVENUE` (group by BILL_TYPE, PAYMENT_MODE) + Pie chart |
| 81 OPD Summary | `VW_OPD_DASHBOARD` group by dept/doctor/date |
| 82 IPD Occupancy | `VW_BED_OCCUPANCY` + Gauge/Bar chart |
| 83 Lab Statistics | test wise count/TAT from order dtl |
| 84 Pharmacy Sales | `HMS_PHARMA_SALE` by day/item |
| 85 Doctor Revenue | `VW_DOCTOR_DAILY_OPD` + `HMS_DOCTOR_EARNING` |
| 86 MIS Dashboard | Cards + 4 charts (month revenue, patient trend, occupancy, top 10 tests) |
PDF: IR → Actions → Download → PDF (24.2 built-in, no BI Publisher needed). Formal print = custom HTML page (73 pattern).

---
<a id="s10"></a>
## 11. SPRINT 10 — Baki module (same pattern)
Protiti module = **List (IR/Faceted) + Form (Modal) + 1 transaction page**. Tables already ready.
| Module | Pages | Tables |
|---|---|---|
| Emergency 150 | Triage board (Cards by triage color), ER visit form | HMS_EMERGENCY_* , HMS_AMBULANCE_* |
| Radiology 160 | Order (reuse 50 with section RADIOLOGY), Report entry (Rich Text Editor) | HMS_RADIOLOGY_* |
| OT 170 | OT booking **Calendar**, OT notes, consumables IG | HMS_OT_* |
| Blood Bank 180 | Donor, Bag stock (cards by group), Request/Issue, cross-match | HMS_BLOOD_* |
| Nursing 190 | Nursing assessment, vitals chart, shift handover | HMS_NURSING_* |
| Diet 200 | Diet order by patient, kitchen list report | HMS_DIET_* |
| Accounts 210 | Journal voucher (Master-Detail), COA tree (Tree region), Ledger report | HMS_JOURNAL_VOUCHER*, HMS_CHART_OF_ACCOUNTS |
| Inventory 220 | Item, indent, issue, stock | HMS_INV_* |
| HR 230 | Employee (91 reuse), attendance, leave, payroll | HMS_ATTENDANCE, HMS_LEAVE_*, HMS_PAYROLL_* |
| Insurance 240 | Company, policy, claim | HMS_INSURANCE_* |
| Mortuary 250 | Body register, release | HMS_MORTUARY_* |
(Exact table name: `docs/TABLE_LIST.md`.) Business rule lagle age package banabo — module shuru korar age amake janaben.

---
<a id="map"></a>
## 12. Page Number Map
| # | Page | # | Page |
|---|---|---|---|
| 1 | Dashboard | 50 | Lab Order |
| 2 | Change Password | 51 | Sample Collection |
| 3 | Doctor Dashboard | 52 | Result Entry |
| 10 | Patient Registration | 53 | Lab Report Print |
| 11 | Patient Search | 54 | Lab Worklist |
| 12 | Patient Profile | 60 | Pharmacy POS |
| 20 | OPD New Visit | 61 | Purchase Order |
| 21 | OPD Queue (211 TV) | 62 | GRN |
| 22 | Consultation EMR | 63 | Stock |
| 23 | Prescription Print | 64 | Expiry |
| 30 | Appointment Booking | 65 | Return |
| 31 | Appointment Calendar | 70 | Bills |
| 40 | Admission | 71 | Bill + Payment |
| 41 | Bed Map | 72 | Statement |
| 42 | Inpatients | 73 | Invoice/Receipt Print |
| 43 | IPD Chart | 80–86 | Reports |
| 44 | Medication | 90–98 | Setup / Security |
| 45 | Discharge (451 print) | 150–250 | Other modules |
| 421 | Bed Transfer | 9999 | Login |

**Protiti sprint shesh e:** App export (`apex/f100.sql`) + `END_OF_DAY.bat`.
