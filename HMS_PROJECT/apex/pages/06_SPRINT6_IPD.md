# SPRINT 6 — IPD (Page 41, 40, 42, 421, 43, 44, 45, 451)

🎯 **Ei sprint e ki hobe:** Bed map, admission, inpatient list, chart/medication, discharge.

## Shuru-r age (check)
- [ ] Sprint 3: Ward + Bed data
- [ ] Sprint 5 (IPD bill, advance)
- [ ] DB: `03_apex_views.sql` (VW_BED_MAP)

**Build order:** 41 → 40 → 42 → 421 → 43 → 44 → 45 → 451 (bed na dekhe admission hoy na)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Flow: **Bed Map (41)** → **Admission (40)** → **Inpatients (42)** → **Chart (43) / Medication (44)** → **Discharge (45 → 451)**

---
## PAGE 41 — Bed Map ⭐
**Purpose:** Read-only bed status board. It shows every active bed in the signed-in user's branch and makes Available beds easy to find. Bed admission/status changes happen on later pages, not on this page.

### 1. Verify the views before opening Page Designer
Toad → connect as `HMS_APP` → run this check:
```
SELECT OBJECT_NAME, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME IN ('VW_BED_MAP', 'VW_BED_OCCUPANCY')
 ORDER BY OBJECT_NAME;
```
Both should be `VALID`. `VW_BED_MAP` is created by `database/11_apex_support/03_apex_views.sql`; `VW_BED_OCCUPANCY` is in `database/07_views/create_all_views.sql` (also called by `RUN_ALL.sql`). If a view is missing/invalid, open the corresponding file in Toad as HMS_APP and press **F5 (Execute as Script)**. The bed-map view already excludes inactive beds/wards; the Cards query below filters by `:G_BRANCH_ID`.

### 2. Create or update Page 41
If Page 41 already exists, update it—do not create a duplicate. Otherwise App Builder → App 101 → **Create Page** → **Component** → **Cards**; Page Number `41`, Name `Bed Map`, Data Source `Local Database`, Source Type `SQL Query`. Use the app's database-driven navigation (do not create a duplicate navigation menu).

Select Page 41 in Page Designer → Property Editor → **Security**:
- Authorization Scheme: `AUTH_IPD`
- Page Access Protection: `Arguments Must Have Checksum`

Select the **Bed Map** Cards region → Source → SQL Query:
```
SELECT BED_ID,
       WARD_ID,
       WARD_NAME,
       WARD_TYPE,
       FLOOR_NO,
       BED_NO,
       BED_TYPE,
       DAILY_CHARGE,
       BED_STATUS,
       STATUS_CSS,
       ADMISSION_ID,
       ADMISSION_NO,
       ADMISSION_DATE,
       MRN,
       PATIENT_NAME,
       CASE WHEN BED_STATUS = 'OCCUPIED'
            THEN NVL(PATIENT_NAME, 'Patient details unavailable')
            ELSE 'No patient assigned'
       END AS CARD_BODY,
       WARD_NAME || ' - ' || NVL(WARD_TYPE, 'Ward') ||
         CASE WHEN FLOOR_NO IS NOT NULL THEN ' - Floor ' || FLOOR_NO END
         AS CARD_SUBTITLE,
       CASE WHEN ADMISSION_ID IS NOT NULL
            THEN 'MRN ' || NVL(MRN, 'Not recorded') || ' - ' || ADMISSION_NO
            ELSE 'Bed type ' || NVL(BED_TYPE, 'Not set') ||
                 ' - Daily charge Tk ' ||
                 TO_CHAR(NVL(DAILY_CHARGE, 0), 'FM999G999G990D00')
       END AS CARD_META,
       CASE BED_STATUS
         WHEN 'AVAILABLE' THEN 'fa-bed'
         WHEN 'OCCUPIED'  THEN 'fa-user'
         WHEN 'RESERVED'  THEN 'fa-clock-o'
         ELSE 'fa-wrench'
       END AS ICON_CLASS
  FROM VW_BED_MAP
 WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY WARD_NAME, FLOOR_NO, BED_NO
```
This query only reads the existing view; it does not calculate a bill or update a bed. In the Cards region's **Attributes** tab, map the card fields to query columns: Title = `BED_NO`, Subtitle = `CARD_SUBTITLE`, Body = `CARD_BODY`, Secondary Body = `CARD_META`, Badge = `BED_STATUS`, Icon = `ICON_CLASS`, Card CSS Classes = `STATUS_CSS`. Set Layout to **Grid** (not Float), and Cards region → Appearance → CSS Classes = `hms-bed-map`. Keep the bed's status badge visible; the CSS class from the view supplies the status color.

### 3. Put ward occupancy above the bed cards
Create or keep a **Classic Report** named `Bed Occupancy by Ward`; no Interactive Grid. Its Source → SQL Query is:
```
SELECT WARD_NAME,
       TOTAL_BEDS,
       AVAILABLE,
       OCCUPIED,
       RESERVED,
       NOT_READY,
       OCCUPANCY_PCT
  FROM VW_BED_OCCUPANCY
 WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY WARD_NAME
```
Use headings `Ward`, `Total Beds`, `Available`, `Occupied`, `Reserved`, `Cleaning / Maintenance`, `Occupancy %`. Region → Appearance → CSS Classes = `hms-wide hms-bed-occupancy`; keep it full width. In Page Designer's Rendering tree, drag `Bed Occupancy by Ward` **above** `Bed Map` so the counts appear before the cards, not at the bottom of a long map.

Add a Static Content region named `Bed Status Note` above the Cards region. Source:
```
<div class="hms-note hms-note--info">
  <i class="fa fa-info-circle" aria-hidden="true"></i>
  <div>
    <span class="hms-note-title">Bed Status</span>
    <span>Available beds are ready for admission. Occupied, reserved, cleaning, and maintenance beds are not available.</span>
  </div>
</div>
```
The note and all card text are English. Do not add an insert/update process or editable page item to Page 41.

### 4. Test Page 41
Run as an IPD user and verify:
1. Only beds from the user's `G_BRANCH_ID` appear; no inactive bed/ward appears.
2. Available / Occupied / Reserved / Cleaning or Maintenance badges match the counts in `Bed Occupancy by Ward`.
3. Occupied cards show the patient name and MRN/admission number; unoccupied cards say `No patient assigned` and show the bed type/charge.
4. The page is read-only. The current build order is `41 → 40 → 42 → 421 → 43 → 44 → 45 → 451`; add the Available → Page 40 and Occupied → Page 43 card links only after those target pages exist. Reserved/cleaning/maintenance beds must not open admission.

If every card says `AVAILABLE`, check the occupancy report first. When `OCCUPIED = 0` for every ward, that is the database state—not a Cards styling error.
---
## PAGE 40 — Admission
Blank 40 `Admission` ▸ Authorization AUTH_IPD_ADD.
Regions: **Patient** (12) · **Admission Details** (8) · **Bed & Advance** (4).
| Item | Type | Setting |
|---|---|---|
| P40_PATIENT_ID | Popup | VW_LOV_PATIENT Required · DA → P40_PATIENT_INFO (same as page 20) |
| P40_OPD_VISIT_ID | Hidden | from page 22 |
| P40_DEPT_ID | Select | VW_LOV_DEPARTMENT CLINICAL |
| P40_DOCTOR_ID | Select cascading | VW_LOV_DOCTOR by dept · label `Admitting/Consultant` |
| P40_ADMISSION_TYPE | Radio pill | `Planned;PLANNED,Emergency;EMERGENCY,Transfer;TRANSFER,Day Care;DAY_CARE,Maternity;MATERNITY` |
| P40_REASON | Textarea | Admission reason / provisional dx |
| P40_ATTENDANT_NAME / P40_ATTENDANT_PHONE | Text | Required |
| P40_BED_ID | Popup LOV | `SELECT WARD_NAME||' - Bed '||BED_NO||' ('||BED_TYPE||', Tk '||DAILY_CHARGE||'/day)' d, BED_ID r FROM VW_BED_MAP WHERE BRANCH_ID=:G_BRANCH_ID AND BED_STATUS='AVAILABLE' ORDER BY 1` Required |
| P40_ADVANCE | Number | Default 0 (System config e minimum advance thakle validation) |
| P40_PAYMENT_MODE | Select | LOOKUP PAYMENT_MODE |
Process ADMIT (button `Admit Patient`, Hot, confirm "Bed &P40_BED_ID. allocate hobe"):
```plsql
DECLARE l_no VARCHAR2(30);
BEGIN
  :P40_ADMISSION_ID := PKG_IPD.admit_patient(:G_BRANCH_ID, :P40_PATIENT_ID, :P40_DOCTOR_ID, :P40_DEPT_ID, :P40_BED_ID,
        :P40_ADMISSION_TYPE, :P40_REASON, :P40_OPD_VISIT_ID, :P40_ATTENDANT_NAME, :P40_ATTENDANT_PHONE,
        NVL(:P40_ADVANCE,0), :P40_PAYMENT_MODE, l_no);
  :P40_ADMISSION_NO := l_no;
END;
```
Success `Admitted: &P40_ADMISSION_NO.` → Branch Page 43 (`P43_ADMISSION_ID`).
Validation: patient already admitted? → No Rows Returned `SELECT 1 FROM HMS_IPD_ADMISSION WHERE PATIENT_ID=:P40_PATIENT_ID AND ADMISSION_STATUS='ADMITTED'` "Ei patient already admitted".

---
## PAGE 42 — Current Inpatients
Interactive Report 42 on `VW_IPD_CURRENT_PATIENTS WHERE BRANCH_ID=:G_BRANCH_ID`
Columns: ADMISSION_NO, ADMISSION_DATE, STAY_DAYS, MRN, PATIENT_NAME, GENDER, WARD_NAME, BED_NO, DOCTOR_NAME, BILL_AMOUNT, PAID_AMOUNT, DUE_AMOUNT, ADVANCE_BALANCE
- DUE_AMOUNT > ADVANCE_BALANCE → red highlight (Actions ▸ Format ▸ Highlight, condition expression)
- Control break WARD_NAME (default saved)
- **Actions column** (24.2): add virtual column `ACTIONS` → Type *Link* with HTML `<button class="t-Button t-Button--small js-menuButton" data-menu="adm_menu_#ADMISSION_ID#">⋮</button>` — simpler: 4 link icon columns:
  | Column (SQL: NULL AS ...) | Icon | Target |
  |---|---|---|
  | CHART | fa-heartbeat | 43 `P43_ADMISSION_ID=#ADMISSION_ID#` |
  | MEDS | fa-medkit | 44 |
  | BILL | fa-money | 71 `P71_BILL_ID` = `PKG_IPD.get_ipd_bill_id(ADMISSION_ID)` (add as SQL column IPD_BILL_ID) |
  | TRANSFER | fa-exchange | 421 |
  | DISCHARGE | fa-sign-out | 45 |
Authorization AUTH_IPD.

## PAGE 421 — Bed Transfer (Modal 520)
Items: P421_ADMISSION_ID (hidden) · P421_CURRENT (Display: current ward/bed) · P421_BED_ID (Popup, available beds) · P421_REASON (Required).
Process `PKG_IPD.transfer_bed(:P421_ADMISSION_ID, :P421_BED_ID, :P421_REASON, :G_EMPLOYEE_ID);` → Close Dialog. Parent refresh.

---
## PAGE 43 — IPD Patient Chart
Blank 43 ▸ Hidden P43_ADMISSION_ID (checksum), P43_PATIENT_ID (load).
**Banner** (Value Attribute Pairs row): `SELECT ADMISSION_NO, PATIENT_NAME, MRN, WARD_NAME||' / '||BED_NO bed, DOCTOR_NAME, STAY_DAYS||' days' stay, DUE_AMOUNT FROM VW_IPD_CURRENT_PATIENTS WHERE ADMISSION_ID=:P43_ADMISSION_ID`
Buttons in banner: Medication (44), Lab Order (50 with admission), Bill (71), Transfer (421), Discharge (45).
**Tabs Container**:
| Tab | Region |
|---|---|
| Doctor Rounds | IG `HMS_IPD_DOCTOR_VISIT WHERE ADMISSION_ID=:P43_ADMISSION_ID ORDER BY VISIT_TIME DESC` — ADMISSION_ID default item, DOCTOR_ID default `(SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID=:G_EMPLOYEE_ID)`, VISIT_TIME default SYSTIMESTAMP, VISIT_TYPE select (ROUTINE/CALL/EMERGENCY/CONSULTANT), PROGRESS_NOTES textarea, INSTRUCTIONS, VISIT_CHARGE (read-only; bill posting chaile IG after-save process e `PKG_BILLING.add_bill_item(PKG_IPD.get_ipd_bill_id(:P43_ADMISSION_ID), NULL,'Doctor visit',1,:VISIT_CHARGE,0,:DOCTOR_ID,'IPD_VISIT',:IPD_VISIT_ID)`) |
| Vitals | Line chart from nursing vitals table (Sprint 10 Nursing) — placeholder |
| Lab Results | Report: orders with ADMISSION_ID = :P43_ADMISSION_ID + link to 53 |
| Medication | Read-only summary of active HMS_IPD_MEDICATION (edit on 44) |
| Charges | Classic: `HMS_BILLING_DTL WHERE BILL_ID = PKG_IPD.get_ipd_bill_id(:P43_ADMISSION_ID)` + button *Post today's bed charge* → `PKG_IPD.post_bed_charges(:P43_ADMISSION_ID);` |

## PAGE 44 — Medication Chart
Blank 44. Region 1 **Medication Orders** IG `HMS_IPD_MEDICATION WHERE ADMISSION_ID=:P44_ADMISSION_ID`:
ITEM_ID (Popup VW_LOV_MEDICINE) → MEDICINE_NAME, DOSAGE, ROUTE (LOOKUP), FREQUENCY (LOOKUP), START_DATE (default today), END_DATE, ORDERED_BY (default employee), ORDER_STATUS (Select ACTIVE/STOPPED/COMPLETED), INSTRUCTIONS. Authorization edit: AUTH_DOCTOR.
Region 2 **Administration (Nurse)** IG master-detail (detail of region 1): `HMS_IPD_MED_ADMINISTRATION` — SCHEDULED_TIME, GIVEN_TIME (default now), GIVEN_BY (default employee), ADMIN_STATUS (GIVEN/MISSED/REFUSED/HELD), NOTES.
Create both via **Create Page ▸ Master Detail ▸ Side by Side**? — admission filter lagbe tai Blank + 2 IG, detail IG ▸ Master Region = region 1.

---
## PAGE 45 — Discharge (Wizard style)
Blank 45 ▸ P45_ADMISSION_ID. Region **Wizard Progress** (Static, List template *Wizard Progress*, list static: Summary → Bill → Confirm) — optional look.
**Region 1 Discharge Summary** — Form region on `HMS_DISCHARGE_SUMMARY` (PK SUMMARY_ID; load where ADMISSION_ID via pre-rendering select SUMMARY_ID into item):
DISCHARGE_TYPE (Select NORMAL/LAMA/REFERRED/DEATH/ABSCONDED/DOR), FINAL_DIAGNOSIS, ICD_ID (popup), TREATMENT_GIVEN (Textarea/Rich Text), PROCEDURES_DONE, CONDITION_AT_DISCHARGE, DISCHARGE_ADVICE, DISCHARGE_MEDICATION (Textarea — "copy from active medication" button: server code `SELECT LISTAGG(MEDICINE_NAME||' '||DOSAGE||' '||FREQUENCY, CHR(10)) ... INTO :P45_DISCHARGE_MEDICATION`), FOLLOWUP_DATE, ADMISSION_ID (hidden default), DISCHARGED_BY (default employee), SUMMARY_STATUS (DRAFT/FINAL).
Button SAVE_SUMMARY (ARP).
**Region 2 Bill Status**: before showing → Pre-Rendering `PKG_IPD.post_bed_charges(:P45_ADMISSION_ID);` then Value pairs: Net, Paid, Advance, **Due**. Button `Go to Bill` → 71.
**Region 3 Confirm**: P45_ALLOW_DUE (Switch, Authorization AUTH_SUPER) · Button DISCHARGE (Hot, Danger confirm "Patient discharge korben?"):
```plsql
PKG_IPD.discharge_patient(:P45_ADMISSION_ID, :P45_DISCHARGE_TYPE, NVL(:P45_ALLOW_DUE,'N'));
UPDATE HMS_DISCHARGE_SUMMARY SET SUMMARY_STATUS='FINAL' WHERE ADMISSION_ID=:P45_ADMISSION_ID;
```
Due thakle package `-20305 Due ache...` → user notification e dekhbe. Success → Branch 451.

## PAGE 451 — Discharge Summary Print
Minimal template, **Dynamic Content** region (PL/SQL Function Body returning a CLOB — Page 23 er moto `w()` + `RETURN l_html`) (page 23 technique): hospital header, patient + admission (date in/out, ward/bed, consultant), final dx, treatment, procedures, condition, **discharge medication** table, advice, follow-up, doctor signature. A4.

## Sprint 6 checklist
- [ ] Bed map color · admit from free bed → bed red
- [ ] Round note, medication, transfer (old bed free, new occupied)
- [ ] Bed charge post → bill · Discharge with due block · print
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Bed map khali | HMS_BED e data/IS_ACTIVE='Y' nai |
| Discharge e ORA-20305 | Due ache — payment nin ba ALLOW_DUE (AUTH_SUPER) |
