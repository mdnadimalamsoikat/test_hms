# SPRINT 1 — Foundation (APEX 24.2)

**Ei sprint e ki banabo:** login er por user er info mone rakha, permission system, sob page er common jinish, Change Password, Dashboard.

**Kivabe porben:** protiti step e 3 ta jinish ache —
- 🎯 **Keno** – ei kaj ta keno lagbe (1 line)
- 👉 **Steps** – kothay click korben, ki likhben
- ✅ **Test** – thik hoyeche kina kivabe bujhben

⚠️ **Order maintain korun** (A → H). Age-pore korle problem hoy (jemon: Page 2 banano-r age Force Password process banale login atke jay — eta-i apnar login problem chilo).

---
## Shuru-r age (already done — shudhu check)
| Check | Kothay | Thakte hobe |
|---|---|---|
| DB script | SQL Developer e HMS_APP diye `database/11_apex_support/00_LOGIN_FIX.sql` run | "LOGIN TEST OK" |
| Login scheme | Shared Components ▸ Security ▸ **Authentication** Schemes | *HMS Login* — **Current** |
| CSS/JS file | Shared Components ▸ Static Application Files | `hms.css`, `hms.js` |
| CSS/JS link | Shared Components ▸ User Interface Attributes ▸ JavaScript ▸ File URLs = `#APP_FILES#hms.js` ; Cascading Style Sheets ▸ File URLs = `#APP_FILES#hms.css` | |

---
## A. Application Items (6 ta)
🎯 **Keno:** Login er pore user er ID, branch, role, naam ekhane joma thake. Sob page `:G_BRANCH_ID` diye nijer branch er data dekhay. Login er somoy `PKG_APP_SESSION.POST_AUTH` egulo fill kore.

👉 **Steps:** Shared Components ▸ Application Logic ▸ **Application Items** ▸ **Create**
| Field | Value |
|---|---|
| Name | `G_USER_ID` |
| Scope | Application |
| Session State Protection | **Restricted - May not be set from browser** (browser theke keu value bodlate parbe na = security) |

▸ Create. Same vabe aro 5 ta: `G_BRANCH_ID`, `G_EMPLOYEE_ID`, `G_ROLES`, `G_FULL_NAME`, `G_FORCE_PWD`.

✅ **Test:** Step C3 (Session Info) korar por page er niche naam/branch dekhabe.

---
## B. Authorization Schemes (permission)
🎯 **Keno:** Kon user kon page/button dekhbe. Role-permission DB te (`HMS_ROLE_PERMISSION`) — APEX shudhu jiggesh kore "ei user PATIENT dekhte parbe?" → `PKG_APP_SESSION.can_yn('PATIENT')` 'Y'/'N' dey.

⚠️ **Authoriz**ation (permission) ≠ **Authentic**ation (login). Scheme Type list e *Builder Extension Sign-In / Custom…* dekhle vul jaygay → **Cancel**.

👉 **Steps:** Shared Components ▸ Security ▸ **Authorization Schemes** ▸ **Create** ▸ From Scratch ▸ Next
| Field | Value |
|---|---|
| Name | `AUTH_PATIENT` |
| Scheme Type | **Exists SQL Query** (query row dile = permission ache) |
| SQL Query | `select 1 from dual where PKG_APP_SESSION.can_yn('PATIENT') = 'Y'` |
| Error message | `Apnar ei page e permission nai.` |
| Validate authorization scheme | **Once per page view** (protiti page khulle check — role change sathe sathe kaj kore) |

▸ **Create Authorization Scheme**. Baki gula: list e scheme open ▸ **Copy** ▸ Name + SQL er module/action bodlan.

**Pattern:** `select 1 from dual where PKG_APP_SESSION.can_yn('<MODULE>','<ACTION>') = 'Y'`
(ACTION na dile = VIEW. Onno: ADD, EDIT, DELETE, PRINT, APPROVE)

| Scheme name | can_yn(...) er vitore |
|---|---|
| AUTH_PATIENT · AUTH_PATIENT_ADD · AUTH_PATIENT_EDIT | `'PATIENT'` · `'PATIENT','ADD'` · `'PATIENT','EDIT'` |
| AUTH_APPOINTMENT · _ADD | `'APPOINTMENT'` · `'APPOINTMENT','ADD'` |
| AUTH_OPD · _ADD · _EDIT | `'OPD'` · `'OPD','ADD'` · `'OPD','EDIT'` |
| AUTH_IPD · _ADD · _EDIT | `'IPD'` · `'IPD','ADD'` · `'IPD','EDIT'` |
| AUTH_LAB · _ADD · _APPROVE | `'LAB'` · `'LAB','ADD'` · `'LAB','APPROVE'` |
| AUTH_PHARMACY · _ADD | `'PHARMACY'` · `'PHARMACY','ADD'` |
| AUTH_BILLING · _ADD · _APPROVE | `'BILLING'` · `'BILLING','ADD'` · `'BILLING','APPROVE'` |
| AUTH_REPORTS | `'REPORTS'` |
| AUTH_SETUP · _ADD · _EDIT | `'SETUP'` · `'SETUP','ADD'` · `'SETUP','EDIT'` |
| AUTH_SECURITY | `'SECURITY'` |

**Role-based 2 ta** (Exists SQL Query):
AUTH_SUPER
```sql
select 1 from HMS_USER u
  join HMS_USER_ROLE ur on ur.USER_ID = u.USER_ID and ur.IS_ACTIVE = 'Y'
  join HMS_ROLE r on r.ROLE_ID = ur.ROLE_ID
 where u.USERNAME = upper(:APP_USER) and r.ROLE_CODE = 'SUPER_ADMIN'
```
AUTH_DOCTOR — same, shesh line: `and r.ROLE_CODE in ('DOCTOR','SUPER_ADMIN')`

✅ **Test:** SQL Commands: `SELECT MODULE_CODE FROM HMS_APP_MODULE;` → scheme e je code likhechen shegulo list e ache.
⚠️ **Application-level e kono scheme set korben na:** Shared Components ▸ Security Attributes ▸ Authorization Scheme = **No application authorization required** thakbe. Scheme gula shudhu page/region/button e boshabo.

---
## C. Page 0 — Global Page
🎯 **Keno:** Page 0 te ja rakhben sheta **sob page e** auto thake. Ekbar banalei holo.

### C1. Page 0 open
App Builder ▸ App 101 ▸ **0 - Global Page** click. Na thakle: Create Page ▸ **Global Page** ▸ Create Page.

### C2. DA "Enter as Tab" (Enter chaple next field)
🎯 Data entry fast — mouse chara Enter diye field to field.
1. Page Designer bam pashe **⚡ Dynamic Actions** tab
2. **Page Load** e right-click ▸ **Create Dynamic Action** ▸ Name = `Enter as Tab`
3. Tree te **True** er nicher action click ▸ Action = **Execute JavaScript Code** ▸ Code = `hms.enterAsTab();`
4. Tree te DA er naam `Enter as Tab` click ▸ **Server-side Condition** ▸ Type **Expression** ▸ PL/SQL Expression = `:APP_PAGE_ID NOT IN (9999)`
   (keno: login page e Enter = login submit hote hobe)
5. **Save**

✅ Page 11 e Enter chaple next field e jay; login page e Enter chaple login hoy.

### C3. Region "Session Info" (optional, development only)
🎯 Login er por G_ item gula thik fill hocche kina dekha.
1. **Rendering** tab ▸ **Footer** e right-click ▸ **Create Region**
2. Title `Session Info` · Type **Static Content** · Template **Blank with Attributes**
3. Text: `<small style="opacity:.6">&G_FULL_NAME. · Branch &G_BRANCH_ID. · &G_ROLES.</small>`
4. Server-side Condition ▸ Expression ▸ `:APP_PAGE_ID NOT IN (9999)` ▸ **Save**

✅ Page 1 er niche: `ADMIN · Branch 1 · SUPER_ADMIN`. ⚠️ Go-live er age delete.

---
## D. Page 9999 — Login design
🎯 Login page e hospital er naam/logo, bangla-friendly label.
Page Designer ▸ Page 9999:
1. Login region ▸ Title `Hospital Management System` ▸ Appearance ▸ Icon `fa-hospital-o`
2. `P9999_USERNAME` ▸ Label `User ID` · `P9999_PASSWORD` ▸ Label `Password`
3. Body te notun region ▸ Static Content ▸ Template **Blank with Attributes** ▸ Text:
   `<p style="text-align:center;color:#888">© Hospital Name · IT Support: 01XXXXXXXXX</p>`
4. Save
⚠️ Page 9999 ▸ Security ▸ Authentication = **Page Is Public** (na thakle keu login page-i dekhbe na).

✅ Logout ▸ notun login page ▸ ADMIN / Admin@12345 ▸ Enter ▸ dashboard.

---
## E. Page 2 — Change Password
🎯 User nijer password bodlabe; notun user first login e ekhane ashbe.

👉 Create Page ▸ **Blank Page** ▸ Page Number `2` ▸ Name `Change Password` ▸ Page Mode **Modal Dialog** ▸ Navigation Menu: No ▸ Create.
Page properties ▸ Security ▸ Authorization Scheme = **Must Not Be Public User** (login kora sobai).

**Region** `Change Password` (Static Content). **Items** (Type **Password**, Value Required **On**):
| Item | Label |
|---|---|
| P2_OLD_PWD | Current Password |
| P2_NEW_PWD | New Password |
| P2_CONFIRM_PWD | Confirm New Password |

**Buttons:**
| Button | Label | Hot | Action |
|---|---|---|---|
| CANCEL | Cancel | No | Defined by Dynamic Action → DA Click ▸ **Cancel Dialog** |
| SAVE | Change Password | **Yes** | Submit Page |

**Validation** (Processing tab ▸ Validations ▸ Create) ▸ Name `Password Rules` ▸ Type **Function Body (returning Error Text)** ▸ When Button Pressed `SAVE`:
```plsql
IF :P2_NEW_PWD <> :P2_CONFIRM_PWD THEN RETURN 'Notun password duibar same hoy nai'; END IF;
IF LENGTH(:P2_NEW_PWD) < 8 OR NOT REGEXP_LIKE(:P2_NEW_PWD,'[0-9]') OR NOT REGEXP_LIKE(:P2_NEW_PWD,'[A-Z]') THEN
   RETURN 'Min 8 character, 1 boro hater okkhor + 1 number lagbe';
END IF;
RETURN NULL;
```
🎯 Keno: DB te jawar age rule check → user sathe sathe error dekhe.

**Process 1** `Change Password` ▸ Type Execute Code ▸ When Button Pressed `SAVE`:
```plsql
PKG_AUTH.change_password(:APP_USER, :P2_OLD_PWD, :P2_NEW_PWD);
:G_FORCE_PWD := 'N';
```
🎯 Keno: package purono pwd check kore, hash kore save kore, `FORCE_PWD_CHANGE='N'` kore. `:G_FORCE_PWD := 'N'` → ei session e ar Page 2 te pathabe na.
Success Message `Password change hoyeche.`

**Process 2** ▸ Type **Close Dialog** ▸ When Button Pressed `SAVE`.

✅ Vul current pwd → error · rule vango → error · thik → success → logout ▸ notun pwd diye login.

---
## F. Force Password Change (Page 2 banano-r **pore**)
🎯 Notun user (FORCE_PWD_CHANGE='Y') login korle age password bodlate badhyo.

👉 Shared Components ▸ Application Logic ▸ **Application Processes** ▸ Create
| Field | Value |
|---|---|
| Name | `Force Password Change` |
| Process Point | **On Load: Before Header** |
| Code | `APEX_UTIL.REDIRECT_URL(APEX_PAGE.GET_URL(p_page => 2));` |
| Condition Type | **Expression** ▸ PL/SQL |
| Expression | `:G_FORCE_PWD = 'Y' AND :APP_PAGE_ID NOT IN (0, 2, 9999)` |

✅ Test:
```sql
UPDATE HMS_USER SET FORCE_PWD_CHANGE='Y' WHERE USERNAME='ADMIN'; COMMIT;
```
Login → Page 2 ashe → pwd change → dashboard. (Atke gele: `UPDATE ... SET FORCE_PWD_CHANGE='N'` + COMMIT.)

---
## G. Navigation Bar (upore dane user menu)
🎯 Upore user er naam + Change Password + Sign Out.
Shared Components ▸ Navigation ▸ Lists ▸ **Navigation Bar**:
1. `&APP_USER.` entry ▸ Label = `&G_FULL_NAME.` ▸ Apply
2. Create Entry ▸ Parent `&G_FULL_NAME.` ▸ Image `fa-key` ▸ Label `Change Password` ▸ Target Page `2` ▸ Create
Bam menu: User Interface Attributes ▸ Navigation Menu ▸ List = **HMS Menu**.

✅ Upore dane naam; click → Change Password, Sign Out.

---
## H. Page 1 — Dashboard
🎯 Login er por prothom screen: aajker hisab ek nojore.
Page 1 ▸ default hero region delete. Page ▸ Security ▸ Authorization = **Must Not Be Public User**.

### H1. KPI cards
Region ▸ Title `Today` ▸ Type **Cards** ▸ Static ID `kpi_cards` ▸ Template **Blank with Attributes** ▸ Source SQL:
```sql
SELECT 1 seq,'New Patients' lbl, NEW_PATIENTS_TODAY val,'fa fa-user-plus' ico, 11 pg FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 2,'OPD Today',   OPD_TODAY,       'fa fa-stethoscope', 21 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 3,'OPD Waiting', OPD_WAITING,     'fa fa-clock-o',     21 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 4,'Admitted',    IPD_CURRENT,     'fa fa-bed',         42 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 5,'Beds Free',   BEDS_AVAILABLE,  'fa fa-check-circle',41 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 6,'Lab Pending', LAB_PENDING,     'fa fa-flask',       54 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
UNION ALL SELECT 7,'Collection (Tk)', COLLECTION_TODAY,'fa fa-money',   80 FROM VW_DASHBOARD_KPI WHERE BRANCH_ID=:G_BRANCH_ID
ORDER BY 1
```
Region ▸ **Attributes** tab: Layout **Grid**, **4 Columns** · Primary Key `SEQ` · Title `VAL` · Subtitle `LBL` · Icon and Badge ▸ Icon Source **Icon Class Column** · Icon Column = `ICO` · Icon Position **Start** (icon value e `fa fa-...` duitai lagbe) · Actions ▸ Add ▸ **Full Card** ▸ Target Page `&PG.`

### H2. Ward Occupancy chart
Region ▸ Type **Chart** ▸ Column Span 6 ▸ Attributes: Type **Bar**, Orientation Horizontal, Stack Yes.
Series `Occupied`: `SELECT WARD_NAME, OCCUPIED FROM VW_BED_OCCUPANCY WHERE BRANCH_ID=:G_BRANCH_ID` (Label WARD_NAME, Value OCCUPIED)
Series `Available`: same, AVAILABLE. Region ▸ Security ▸ Authorization `AUTH_IPD`.

### H3. Collection – Last 7 Days
Chart ▸ **Start New Row: No** ▸ Span 6 ▸ Type **Line**:
```sql
SELECT TO_CHAR(COLLECTION_DATE,'DD-Mon') lbl, SUM(NET_COLLECTION) amt, COLLECTION_DATE
  FROM VW_DAILY_REVENUE
 WHERE BRANCH_ID=:G_BRANCH_ID AND COLLECTION_DATE >= TRUNC(SYSDATE)-6
 GROUP BY COLLECTION_DATE ORDER BY COLLECTION_DATE
```
Label LBL, Value AMT. Authorization `AUTH_BILLING`.

### H4. Live OPD Queue
Region ▸ **Classic Report** ▸ Static ID `opd_queue`:
```sql
SELECT TOKEN_NO, MRN, PATIENT_NAME, DOCTOR_NAME, DEPT_NAME, VISIT_STATUS, WAITING_MIN
  FROM VW_OPD_DASHBOARD
 WHERE VISIT_DATE = TRUNC(SYSDATE) AND BRANCH_ID = :G_BRANCH_ID
   AND VISIT_STATUS IN ('WAITING','IN_CONSULTATION')
 ORDER BY TOKEN_NO
```
Column VISIT_STATUS ▸ HTML Expression `<span class="hms-badge #VISIT_STATUS#">#VISIT_STATUS#</span>` · No Data Found: `Aj kono patient waiting nai` · Authorization `AUTH_OPD`.

### H5. Auto refresh (30 sec)
DA ▸ Page Load ▸ Execute JavaScript Code:
```javascript
setInterval(function(){ apex.region('opd_queue').refresh(); apex.region('kpi_cards').refresh(); }, 30000);
```

### H6. Quick Action buttons
🎯 Dashboard theke 1 click e common kaj. **Protiti button e 1 ta kore Authorization** (je module er kaj, sheta).
1. Rendering ▸ Body e right-click ▸ Create Region ▸ Title `Quick Actions` ▸ Type **Static Content** ▸ Template **Buttons Container** ▸ Sequence `5` (sobar upore)
2. Region e right-click ▸ **Create Button** — 5 bar, niche table moto:

| Button Name | Label | Icon | Hot | Behavior ▸ Action = Redirect to Page in this App ▸ Target | Security ▸ Authorization Scheme |
|---|---|---|---|---|---|
| NEW_PATIENT | New Patient | fa-user-plus | Yes | Page 10 | **AUTH_PATIENT_ADD** |
| OPD_VISIT | OPD Visit | fa-stethoscope | No | Page 20 | **AUTH_OPD_ADD** |
| ADMISSION | Admission | fa-bed | No | Page 40 | **AUTH_IPD_ADD** |
| LAB_ORDER | Lab Order | fa-flask | No | Page 50 | **AUTH_LAB_ADD** |
| PHARMACY_SALE | Pharmacy Sale | fa-medkit | No | Page 60 | **AUTH_PHARMACY_ADD** |

3. Save → Run. (Page 10/20/40… ekhono na banano → click e error, normal.)

✅ 7 card (0 hote pare), 2 chart, queue. Card click e na-banano page → error (thik ache, pore banabo).

---
## Sprint 1 checklist
- [ ] A: 6 app item
- [ ] B: 24 authorization scheme + AUTH_SUPER, AUTH_DOCTOR
- [ ] C: Page 0 DA + Session Info
- [ ] D: Login design, Enter e login hoy
- [ ] E: Page 2 kaj kore
- [ ] F: Force pwd test pass
- [ ] G: Nav bar naam
- [ ] H: Dashboard
- [ ] Export: App Builder ▸ App 101 ▸ Export/Import ▸ Export → `f101.sql` → `apex/` folder e rakhun (home PC te import korte)

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Login hoy na, kintu DB test OK | `UPDATE HMS_USER SET FORCE_PWD_CHANGE='N', IS_LOCKED='N', FAILED_ATTEMPTS=0 WHERE USERNAME='ADMIN'; COMMIT;` |
| Enter chaple login hoy na | C2 step 4 (9999 condition) |
| "permission nai" sob page e | Security Attributes ▸ Authorization = No application authorization required |
| `PKG_APP_SESSION must be declared` | `00_LOGIN_FIX.sql` HMS_APP e run |
