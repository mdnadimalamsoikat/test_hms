# SPRINT 2 — Patient (Page 11 → 10 → 12)

🎯 **Ei sprint e ki hobe:** Patient register, khuja, profile dekha — hospital er sob kaj er shuru ekhane (MRN).

## Shuru-r age (check)
- [ ] Sprint 1 complete (login, AUTH_PATIENT* scheme)
- [ ] `hms.js` upload kora (duplicate check function)

**Build order:** 11 → 10 → 12 (list age, karon form save er por list e fire ashe)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Order: **11 Search** (list) → **10 Registration** (form) → **12 Profile**.

---
## PAGE 11 — Patient Search
**Purpose:** Reception patient khoje (MRN/phone/name), notun patient er jonno 10 e jay.

### Create
Create Page ▸ **Faceted Search**
| Wizard field | Value |
|---|---|
| Page Number | 11 |
| Name | Patient Search |
| Data Source | SQL Query (niche) |
| Navigation | Use Breadcrumb Yes · Navigation Menu: *Existing entry* na → HMS Menu dynamic, tai skip |
```sql
SELECT PATIENT_ID, MRN, PATIENT_NAME, GENDER, AGE, BLOOD_GROUP, PHONE_PRIMARY,
       PATIENT_CATEGORY, REGISTRATION_DATE, TOTAL_OPD_VISITS, CURRENT_ADMISSION_NO,
       TOTAL_DUE, ALLERGIES,
       CASE WHEN TOTAL_DUE > 0 THEN 'u-danger-text' END DUE_CSS,
       UPPER(SUBSTR(PATIENT_NAME,1,1)) NAME_INITIAL,
       CASE WHEN REGISTRATION_DATE >= TRUNC(SYSDATE)    THEN '1. Today'
            WHEN REGISTRATION_DATE >= TRUNC(SYSDATE)-7  THEN '2. Last 7 days'
            WHEN REGISTRATION_DATE >= TRUNC(SYSDATE)-30 THEN '3. Last 30 days'
            ELSE '4. Older' END REG_PERIOD
  FROM VW_PATIENT_SUMMARY
 WHERE IS_ACTIVE = 'Y'
```
### Page properties
Security ▸ Authorization **AUTH_PATIENT**.

### Facets (region *Search* er niche auto toiri; edit/delete kore ei gula rakhun)
| Facet | Type | Setting |
|---|---|---|
| P11_SEARCH | Search | Source ▸ Database Column(s): `MRN,PATIENT_NAME,PHONE_PRIMARY` |
| P11_GENDER | Checkbox Group | Column GENDER, LOV distinct |
| P11_BLOOD_GROUP | Checkbox Group | BLOOD_GROUP |
| P11_PATIENT_CATEGORY | Radio Group | PATIENT_CATEGORY |
| P11_REG_PERIOD | **Checkbox Group** | Label `Registered` ▸ Source Column **REG_PERIOD** ▸ List of Values: **Distinct Values** ▸ (Range facet date e use korben na — ORA-01841 dey) |
| P11_ADMITTED | Checkbox | Column `CURRENT_ADMISSION_NO` ▸ *Is Not Null* → label "Currently admitted" (Facet ▸ Type Checkbox ▸ LOV Static `Yes;Y`) — optional |

### Results region → Cards e convert
Results region select ▸ Type **Cards** ▸ Attributes:
| Property | Value |
|---|---|
| Layout | Grid, 3 Columns |
| Primary Key | PATIENT_ID |
| Title | PATIENT_NAME |
| Subtitle | `&MRN. · &PHONE_PRIMARY.` (Advanced Formatting ON → HTML) |
| Body | Advanced Formatting ▸ `&GENDER. · &AGE. · Blood &BLOOD_GROUP.<br><span class="&DUE_CSS.">Due Tk &TOTAL_DUE.</span>` |
| Icon | Initials ▸ Column NAME_INITIAL |
| Badge | CURRENT_ADMISSION_NO (label "IPD") |
| Action | Full Card ▸ Page **12** ▸ Set Items `P12_PATIENT_ID` = `&PATIENT_ID.` |
| Pagination | Scroll, 24 cards |
| No data | `Kono patient pawa jay nai. Notun registration korun.` |

Sort: Region ▸ Order By ▸ `REGISTRATION_DATE DESC`.

### Buttons
`[Button] CREATE` — Region *Search* ba breadcrumb ▸ Position **Create** ▸ Label `New Patient` ▸ Hot ▸ Icon `fa-user-plus` ▸ Action Redirect Page **10** (Clear Cache 10) ▸ Authorization `AUTH_PATIENT_ADD`.

✅ Test: search box e phone er ongsho likhle filter · card click → 12.

---
## PAGE 10 — Patient Registration / Edit
**Purpose:** Notun patient (MRN auto via PKG_PATIENT) ba existing edit.

### Create
Create Page ▸ **Form**
| Wizard | Value |
|---|---|
| Page Number | 10 · Name `Patient Registration` · Page Mode **Normal** |
| Data Source | Table `HMS_PATIENT` |
| Primary Key | PATIENT_ID (Select Primary Key Column) |
| Branch here on Submit / Cancel | 11 |

Wizard sob column item banabe. Ei gula **delete**: P10_CREATED_BY, CREATED_DATE, UPDATED_BY, UPDATED_DATE, AGE_MONTHS, AGE_DAYS, BIRTH_REG_NO, PASSPORT_NO, SPOUSE_NAME, PERMANENT_* (chaile rakhun), IS_VIP (rakhte paren).
> Delete na kore *Type = Hidden* dileo hoy, kintu kom item = druto page.

### Page properties
Title: `&P10_PAGE_TITLE.` (computation niche) · Authorization **AUTH_PATIENT_ADD** · Page Access Protection *Arguments Must Have Checksum*.

### Region layout (3 region)
Default form region rename ▸ `Basic Information`. Aro 2 region Create (Type Static Content? **Na** — item move korte hobe, tai region type *Static Content* banaye item gula drag kore nin; form source region-e thaka dorkar nai, 24.2 te item Source ▸ Form Region = default region select thake).

| Region | Template | Template Options | Items |
|---|---|---|---|
| Basic Information | Standard | Header visible, **Collapsible No** | TITLE, FIRST_NAME, MIDDLE_NAME, LAST_NAME, GENDER, DATE_OF_BIRTH, AGE_YEARS, BLOOD_GROUP, MARITAL_STATUS, RELIGION, NATIONALITY, OCCUPATION, PHOTO |
| Contact & Address | **Collapsible** | Expanded | PHONE_PRIMARY, PHONE_SECONDARY, EMAIL, NID_NUMBER, PRESENT_ADDRESS, PRESENT_THANA, PRESENT_DISTRICT, PRESENT_DIVISION |
| Family & Emergency | Collapsible | **Collapsed** | FATHER_NAME, MOTHER_NAME, EMERGENCY_CONTACT_NAME, EMERGENCY_CONTACT_PHONE, EMERGENCY_CONTACT_RELATION, REFERRED_BY, REFERRED_DOCTOR_ID, PATIENT_CATEGORY, REMARKS |

### Items — exact setting
Sob item: Appearance ▸ Template **Optional - Floating** (required gula **Required - Floating**).
| Item | Type | Layout (New Row / Span) | Other |
|---|---|---|---|
| P10_PATIENT_ID | Hidden | – | PK, Value Protected Yes |
| P10_BRANCH_ID | Hidden | – | Default ▸ Item `G_BRANCH_ID` |
| P10_MRN | Display Only | Yes / 3 | Label `MRN` · Default `(Auto)` · Template Optional |
| P10_TITLE | Select List | Yes / 2 | LOV: `SELECT D,R FROM VW_LOV_LOOKUP WHERE LOOKUP_TYPE='TITLE' ORDER BY DISPLAY_ORDER` · Display Null Yes |
| P10_FIRST_NAME | Text | No / 4 | Required · Max 100 · Text Case **Upper**? (optional) |
| P10_MIDDLE_NAME | Text | No / 3 | |
| P10_LAST_NAME | Text | No / 3 | |
| P10_GENDER | **Radio Group** | Yes / 4 | List of Values ▸ Type **SQL Query** ▸ `SELECT D,R FROM VW_LOV_LOOKUP WHERE LOOKUP_TYPE='GENDER' ORDER BY DISPLAY_ORDER` · Display Extra Values **Off** · Display Null Value **Off** · Settings ▸ Number of Columns **3** · Template Options ▸ Item Group Display **Display as Pill Button** · Validation ▸ Value Required **On** |
| P10_DATE_OF_BIRTH | Date Picker | No / 4 | Settings ▸ Maximum Date `+0d` · Format `DD-MON-YYYY` |
| P10_AGE_YEARS | Number Field | No / 2 | Label `Age (Y)` · Min 0 Max 130 |
| P10_BLOOD_GROUP | Select List | Yes / 3 | LOOKUP 'BLOOD_GROUP' |
| P10_MARITAL_STATUS | Select List | No / 3 | LOOKUP 'MARITAL_STATUS' |
| P10_RELIGION | Select List | No / 3 | LOOKUP 'RELIGION' |
| P10_NATIONALITY | Text | No / 3 | Default `Bangladeshi` |
| P10_OCCUPATION | Text | Yes / 6 | |
| P10_PHOTO | **Image Upload** | No / 6 | Storage ▸ **BLOB column specified in Item Source** · Display ▸ Preview Size 120x120 · Max 2MB |
| P10_PHONE_PRIMARY | Text (Subtype **Telephone**) | Yes / 4 | Required · Placeholder `01XXXXXXXXX` · Icon `fa-phone` |
| P10_PHONE_SECONDARY | Telephone | No / 4 | |
| P10_EMAIL | Text (Email) | No / 4 | |
| P10_NID_NUMBER | Text | Yes / 4 | |
| P10_PRESENT_ADDRESS | Textarea | Yes / 12 | Height 2 |
| P10_PRESENT_THANA | Text | Yes / 4 | |
| P10_PRESENT_DISTRICT | Text | No / 4 | (pore district LOV) |
| P10_PRESENT_DIVISION | Select List | No / 4 | LOOKUP 'DIVISION' |
| P10_REFERRED_DOCTOR_ID | **Popup LOV** | – / 6 | `SELECT D,R FROM VW_LOV_DOCTOR WHERE BRANCH_ID=:G_BRANCH_ID ORDER BY D` · Display As **Modal Dialog** |
| P10_EMERGENCY_CONTACT_RELATION | Select | | LOOKUP 'RELATION' |
| P10_PATIENT_CATEGORY | Select | | Static: `General;GENERAL,Staff;STAFF,VIP;VIP,Corporate;CORPORATE,Insurance;INSURANCE,Poor/Free;POOR_FREE` · Default GENERAL |

### Baki item gula (form wizard auto banay — shudhu settings thik korun)
| Item | Type | Setting |
|---|---|---|
| P10_FATHER_NAME | Text Field | Span 4 · Max 100 |
| P10_MOTHER_NAME | Text Field | Span 4 · Max 100 |
| P10_SPOUSE_NAME | Text Field | Span 4 |
| P10_EMERGENCY_CONTACT_NAME | Text Field | Span 4 |
| P10_EMERGENCY_CONTACT_PHONE | Text Field (Subtype Telephone) | Span 4 · Placeholder `01XXXXXXXXX` |
| P10_REFERRED_BY | Text Field | Span 6 · Label `Referred By (baire doctor/hospital)` |
| P10_AGE_MONTHS | Number Field | Label `Age (M)` · Span 1 · Min 0 Max 11 |
| P10_AGE_DAYS | Number Field | Label `Age (D)` · Span 1 · Min 0 Max 31 |
| P10_BIRTH_REG_NO | Text Field | Span 4 |
| P10_PASSPORT_NO | Text Field | Span 4 |
| P10_PERMANENT_ADDRESS | Textarea | Span 12 · Height 2 |
| P10_PERMANENT_DISTRICT | Text Field | Span 4 |
| P10_IS_VIP | **Switch** | On Value `Y` · Off Value `N` · Default `N` |
| P10_IS_MEDICO_LEGAL | **Switch** | On `Y` · Off `N` · Default `N` (police case) |
| P10_REMARKS | Textarea | Span 12 |
| P10_REGISTRATION_DATE | **Display Only** | (DB default SYSDATE) |
| P10_IS_ACTIVE | **Hidden** | Default `Y` |
| P10_CREATED_BY / CREATED_DATE / UPDATED_BY / UPDATED_DATE | **Hidden** (ba delete) | Trigger nije fill kore — form e dekhanor dorkar nai |

### Dropdown khali ashle
SQL Commands: `SELECT LOOKUP_TYPE, COUNT(*) FROM HMS_LOOKUP_MASTER GROUP BY LOOKUP_TYPE;` → khali hole SQL Developer e HMS_APP diye `database/11_apex_support/05_fix_lookup_data.sql` run (barbar run safe).

### Computations (Pre-Rendering ▸ Before Header)
`P10_PAGE_TITLE` (hidden item banan): Type Expression ▸ `CASE WHEN :P10_PATIENT_ID IS NULL THEN 'New Patient Registration' ELSE 'Edit Patient - ' || :P10_MRN END`
(Form *Initialize* process er **pore** sequence rakhun.)

### Buttons (default wizard buttons adjust)
| Button | Position | Hot | Icon | Condition | Action |
|---|---|---|---|---|---|
| CANCEL | Close | No | fa-times | – | Redirect 11 |
| DELETE | Delete | No, Template Option **Danger** | fa-trash-o | `P10_PATIENT_ID` not null + Authorization **AUTH_SUPER** | Submit, Confirmation *Danger* |
| SAVE (label `Save Changes`) | Next | Yes | fa-save | P10_PATIENT_ID not null + AUTH_PATIENT_EDIT | Submit |
| CREATE (label `Register Patient`) | Next | Yes | fa-user-plus | P10_PATIENT_ID **is null** | Submit |

> DELETE er bodole soft delete bhalo: Process `UPDATE HMS_PATIENT SET IS_ACTIVE='N' WHERE PATIENT_ID=:P10_PATIENT_ID`.

### Validations
| Name | Type | Code | When button |
|---|---|---|---|
| Phone format | Expression (PL/SQL) | `REGEXP_LIKE(REPLACE(REPLACE(:P10_PHONE_PRIMARY,' '),'-'),'^(\+?880)?01[3-9][0-9]{8}$')` · Error `Sothik mobile number din (01XXXXXXXXX)` · Associated item P10_PHONE_PRIMARY | CREATE, SAVE |
| DOB or Age | Expression | `:P10_DATE_OF_BIRTH IS NOT NULL OR :P10_AGE_YEARS IS NOT NULL` · `Jonmo tarikh ba boyosh din` | CREATE, SAVE |
| Email | Expression | `:P10_EMAIL IS NULL OR REGEXP_LIKE(:P10_EMAIL,'^[^@ ]+@[^@ ]+\.[^@ ]+$')` | CREATE, SAVE |

### Processes (Processing tab — order important)
1. **Register Patient** (Sequence 10) · Type Execute Code · Server-side Condition ▸ When Button Pressed **CREATE**
```plsql
DECLARE l_mrn VARCHAR2(30);
BEGIN
  :P10_PATIENT_ID := PKG_PATIENT.register_patient(
      p_branch_id     => :G_BRANCH_ID,
      p_first_name    => :P10_FIRST_NAME,
      p_last_name     => :P10_LAST_NAME,
      p_gender        => :P10_GENDER,
      p_phone         => :P10_PHONE_PRIMARY,
      p_dob           => TO_DATE(:P10_DATE_OF_BIRTH,'DD-MON-YYYY'),
      p_age_years     => :P10_AGE_YEARS,
      p_blood_group   => :P10_BLOOD_GROUP,
      p_father_name   => :P10_FATHER_NAME,
      p_nid           => :P10_NID_NUMBER,
      p_address       => :P10_PRESENT_ADDRESS,
      p_district      => :P10_PRESENT_DISTRICT,
      p_category      => NVL(:P10_PATIENT_CATEGORY,'GENERAL'),
      p_ref_doctor_id => :P10_REFERRED_DOCTOR_ID,
      p_mrn           => l_mrn);
  :P10_MRN := l_mrn;
  -- package e na thaka extra field gula update
  UPDATE HMS_PATIENT SET
         TITLE = :P10_TITLE, MIDDLE_NAME = :P10_MIDDLE_NAME, MOTHER_NAME = :P10_MOTHER_NAME,
         MARITAL_STATUS = :P10_MARITAL_STATUS, RELIGION = :P10_RELIGION, OCCUPATION = :P10_OCCUPATION,
         PHONE_SECONDARY = :P10_PHONE_SECONDARY, EMAIL = :P10_EMAIL,
         PRESENT_THANA = :P10_PRESENT_THANA, PRESENT_DIVISION = :P10_PRESENT_DIVISION,
         EMERGENCY_CONTACT_NAME = :P10_EMERGENCY_CONTACT_NAME,
         EMERGENCY_CONTACT_PHONE = :P10_EMERGENCY_CONTACT_PHONE,
         EMERGENCY_CONTACT_RELATION = :P10_EMERGENCY_CONTACT_RELATION, REFERRED_BY = :P10_REFERRED_BY
   WHERE PATIENT_ID = :P10_PATIENT_ID;
END;
```
   Success Message `Patient registered. MRN: &P10_MRN.`
2. **Process form Patient Registration** (wizard er Automatic Row Processing) · Server-side Condition ▸ When Button Pressed **SAVE** (DELETE o add korte paren) — CREATE e jeno na chole!
   - ARP → Settings ▸ **Prevent Lost Updates = Yes** (edit er jonno thik)
   - **Photo:** Image Upload (BLOB) ARP diye save hoy, tai photo shudhu **Edit (SAVE)** e save hobe.
     Workflow: Register → Profile (12) → Edit → photo upload → Save. (Create er somoy P10_PHOTO item ▸ Server-side Condition `:P10_PATIENT_ID IS NOT NULL` diye lukiye rakhun.)
   - Register process er UPDATE statement e extra field gula save hoy, tai CREATE e ARP lagbe na.
3. **Close/Branch**: After Processing ▸ Branch ▸ Page **12**, Set Items `P12_PATIENT_ID` = `&P10_PATIENT_ID.` (Condition: CREATE) · ar ekta Branch → 11 (SAVE/DELETE).

### Duplicate check (Ajax)
`[Process] CHECK_DUPLICATE` ▸ Processing Point **Ajax Callback**:
```plsql
DECLARE l_id NUMBER; l_mrn VARCHAR2(30);
BEGIN
  l_id := PKG_PATIENT.find_duplicate(:P10_PHONE_PRIMARY, :P10_FIRST_NAME, :P10_GENDER);
  IF l_id IS NOT NULL THEN SELECT MRN INTO l_mrn FROM HMS_PATIENT WHERE PATIENT_ID = l_id; END IF;
  APEX_JSON.open_object;
  APEX_JSON.write('patient_id', l_id);
  APEX_JSON.write('mrn', l_mrn);
  APEX_JSON.write('url', APEX_PAGE.GET_URL(p_page=>12, p_items=>'P12_PATIENT_ID', p_values=>l_id));
  APEX_JSON.close_object;
END;
```
`[DA] Check Duplicate` ▸ Event **Change** ▸ Item P10_PHONE_PRIMARY ▸ Client Condition: JS `$v('P10_PATIENT_ID') === ''` ▸ True: Execute JS `hms.checkDuplicate();`

### DA — DOB theke age
`[DA] DOB to Age` ▸ Change ▸ P10_DATE_OF_BIRTH ▸ True: **Set Value** ▸ Type PL/SQL Expression:
`TRUNC(MONTHS_BETWEEN(SYSDATE, TO_DATE(:P10_DATE_OF_BIRTH,'DD-MON-YYYY'))/12)` ▸ Items to Submit P10_DATE_OF_BIRTH ▸ Affected P10_AGE_YEARS.

✅ Test: New → MRN-000001 → page 12 · same phone+name+gender → popup · wrong phone → error · edit → save.

---
## PAGE 12 — Patient Profile (360°)
**Purpose:** Ek jaygay patient er sob: info, visit, admission, lab, bill, allergy + quick action.

### Create
Create Page ▸ **Blank Page** ▸ 12 ▸ `Patient Profile` ▸ Normal ▸ Breadcrumb Yes (parent 11).
Authorization **AUTH_PATIENT** · Page Access Protection **Arguments Must Have Checksum**.

### Items (hidden)
`P12_PATIENT_ID` (Hidden, Value Protected, SSP *Checksum Required - Session Level*), `P12_MRN`, `P12_NAME`, `P12_AGE`, `P12_GENDER`, `P12_BLOOD`, `P12_PHONE`, `P12_ALLERGIES`, `P12_DUE`, `P12_ADMISSION` — sob Hidden (position: kono region e, ba Page Items region).

**[Process] Load Patient** (Pre-Rendering ▸ Before Regions, Execute Code):
```plsql
BEGIN
  SELECT MRN, PATIENT_NAME, AGE, GENDER, BLOOD_GROUP, PHONE_PRIMARY, ALLERGIES, TOTAL_DUE, CURRENT_ADMISSION_NO
    INTO :P12_MRN, :P12_NAME, :P12_AGE, :P12_GENDER, :P12_BLOOD, :P12_PHONE, :P12_ALLERGIES, :P12_DUE, :P12_ADMISSION
    FROM VW_PATIENT_SUMMARY WHERE PATIENT_ID = :P12_PATIENT_ID;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    APEX_UTIL.REDIRECT_URL(APEX_PAGE.GET_URL(p_page => 11));   -- patient na pele list e ferot
END;
```
Server-side Condition ▸ Type **Item is NOT NULL** ▸ Item `P12_PATIENT_ID`.
⚠️ Page 12 **sorasori Run korben na** (ID chara khule) — Page 11 theke patient card click kore khulun.
**Page 12 ▸ Pre-Rendering ▸ Branch** (ID chara khulle list e pathabe): Before Header ▸ Branch to Page 11 ▸ Server-side Condition **Item is NULL** `P12_PATIENT_ID`.

### Region 1: Hero / Banner
Type **Static Content** ▸ Template **Hero** ▸ Title `&P12_NAME.` ▸ Icon `fa-user-circle`
Text:
```html
<div class="hms-banner">
  <span><b>MRN</b> &P12_MRN.</span><span><b>Age</b> &P12_AGE.</span>
  <span><b>Gender</b> &P12_GENDER.</span><span><b>Blood</b> &P12_BLOOD.</span>
  <span><b>Phone</b> &P12_PHONE.</span><span><b>Due</b> Tk &P12_DUE.</span>
</div>
```
Sub-region (Static, Template Blank, Condition `:P12_ALLERGIES IS NOT NULL`): `<span class="hms-allergy">⚠ Allergy: &P12_ALLERGIES.</span>`

**Buttons** (Hero region, Position *Next*/*Edit*):
| Button | Icon | Target | Condition / Auth |
|---|---|---|---|
| NEW_VISIT `New OPD Visit` (Hot) | fa-stethoscope | Page 20, `P20_PATIENT_ID=&P12_PATIENT_ID.` | AUTH_OPD_ADD |
| ADMIT `Admit` | fa-bed | Page 40, `P40_PATIENT_ID` | `:P12_ADMISSION IS NULL` + AUTH_IPD_ADD |
| LAB `Lab Order` | fa-flask | Page 50, `P50_PATIENT_ID` | AUTH_LAB_ADD |
| EDIT `Edit` | fa-pencil | Page 10, `P10_PATIENT_ID` | AUTH_PATIENT_EDIT |
| STATEMENT | fa-file-text-o | Page 72, `P72_PATIENT_ID` | AUTH_BILLING |

### Region 2: Tabs container
Type Static Content ▸ Template **Tabs Container** ▸ Template Options ▸ *Remember Active Tab* ▸ Style Simple.
Sub-regions (Parent = Tabs container):

| Tab (sub-region title) | Type | Source | Notes |
|---|---|---|---|
| OPD Visits | Classic Report | `SELECT VISIT_NO, VISIT_DATE, DOCTOR_NAME, DEPT_NAME, VISIT_TYPE, VISIT_STATUS, NET_FEE FROM VW_OPD_DASHBOARD WHERE VISIT_ID IN (SELECT VISIT_ID FROM HMS_OPD_VISIT WHERE PATIENT_ID=:P12_PATIENT_ID) ORDER BY VISIT_DATE DESC` | status badge; VISIT_NO link → 22 (doctor) ba 23 (print) |
| Admissions | Classic Report | `SELECT a.ADMISSION_NO, a.ADMISSION_DATE, a.DISCHARGE_DATE, w.WARD_NAME, b.BED_NO, a.ADMISSION_STATUS, a.ADMISSION_ID FROM HMS_IPD_ADMISSION a LEFT JOIN HMS_WARD w ON w.WARD_ID=a.WARD_ID LEFT JOIN HMS_BED b ON b.BED_ID=a.BED_ID WHERE a.PATIENT_ID=:P12_PATIENT_ID ORDER BY a.ADMISSION_DATE DESC` | link → 43 |
| Lab Tests | Classic Report | `SELECT o.ORDER_NO, o.ORDER_DATE, d.SERVICE_NAME, d.ITEM_STATUS, d.ORDER_DTL_ID FROM HMS_INVESTIGATION_ORDER o JOIN HMS_INVESTIGATION_ORDER_DTL d ON d.ORDER_ID=o.ORDER_ID WHERE o.PATIENT_ID=:P12_PATIENT_ID ORDER BY o.ORDER_DATE DESC` | VERIFIED hole link → 53 report |
| Bills | Classic Report | `SELECT BILL_NO, BILL_DATE, BILL_TYPE, NET_AMOUNT, PAID_AMOUNT, DUE_AMOUNT, BILL_STATUS, BILL_ID FROM VW_BILL_LIST WHERE PATIENT_ID=:P12_PATIENT_ID ORDER BY BILL_DATE DESC` | amount format mask; link → 71 |
| Allergy | **Interactive Grid** | Table `HMS_PATIENT_ALLERGY` ▸ Where `PATIENT_ID = :P12_PATIENT_ID` | Attributes ▸ Edit **Enabled** (Add/Update/Delete) · Column PATIENT_ID ▸ Hidden, Default *Item* P12_PATIENT_ID · ALLERGY_TYPE Select (Static `Drug;DRUG,Food;FOOD,Environment;ENVIRONMENT,Other;OTHER`) · SEVERITY Select (`MILD,MODERATE,SEVERE`) · NOTED_DATE default SYSDATE |

Protiti Classic Report: Template **Standard**, Pagination 10, "No data found" text set.

✅ Test: 11 theke card click → hero te info · allergy add → hero te lal warning · button gula (target page na thakle pore).

## Sprint 2 checklist
- [ ] 11 search + cards · 10 register (MRN auto) + edit + duplicate · 12 profile tabs
- [ ] `SELECT * FROM HMS_AUDIT_TRAIL ORDER BY AUDIT_ID DESC` e entry
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Page 12 er button (OPD/Admit/Lab) click e error | Oi page gula pore banabo (Sprint 4–7) — thik ache |
| Save e ORA-20001 | Required field (naam, gender, phone) khali |
| Duplicate popup ashe na | hms.js upload + Ajax process naam `CHECK_DUPLICATE` hubohu |
