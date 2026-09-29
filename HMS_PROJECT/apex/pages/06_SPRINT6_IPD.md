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
Create Page ▸ **Cards** 41 `Bed Map` ▸ Source:
```sql
SELECT BED_ID, WARD_ID, WARD_NAME, WARD_TYPE, BED_NO, BED_TYPE, DAILY_CHARGE, BED_STATUS, STATUS_CSS,
       ADMISSION_ID, ADMISSION_NO, MRN, PATIENT_NAME,
       CASE BED_STATUS WHEN 'AVAILABLE' THEN 'fa-bed' WHEN 'OCCUPIED' THEN 'fa-user' ELSE 'fa-wrench' END ICO
  FROM VW_BED_MAP WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY WARD_NAME, BED_NO
```
Cards attributes:
| Property | Value |
|---|---|
| Layout | **Float** (choto card pasha-pashi) |
| Title | `&BED_NO.` |
| Subtitle | `&WARD_NAME.` |
| Body | `&PATIENT_NAME.` (Advanced: `<small>&MRN.</small>`) |
| Icon | Icon Class ▸ ICO · Icon Position Top |
| Badge | BED_STATUS |
| Card CSS Classes | `&STATUS_CSS.` (u-success green / u-danger red / u-warning yellow) |
| Action 1 (Full Card) | Link ▸ Page **40** set `P40_BED_ID=&BED_ID.` · Server-side condition ▸ ... Cards action condition not per row → use **Link URL column**: SQL e add `CASE WHEN BED_STATUS='AVAILABLE' THEN APEX_PAGE.GET_URL(p_page=>40,p_items=>'P40_BED_ID',p_values=>BED_ID) WHEN BED_STATUS='OCCUPIED' THEN APEX_PAGE.GET_URL(p_page=>43,p_items=>'P43_ADMISSION_ID',p_values=>ADMISSION_ID) END LINK_URL` → Action Type Full Card ▸ Link ▸ Type **URL** ▸ `&LINK_URL.` |
Faceted? Page e **Region: Filters** (Faceted Search region, filtered region = cards) facets: WARD_NAME, WARD_TYPE, BED_STATUS.
Top summary: Classic report from `VW_BED_OCCUPANCY` (template Badge List): `SELECT WARD_NAME label, AVAILABLE||'/'||TOTAL_BEDS value FROM VW_BED_OCCUPANCY WHERE BRANCH_ID=:G_BRANCH_ID`.
Legend Static: 🟩 Free 🟥 Occupied 🟨 Reserved ⬜ Cleaning. Auto-refresh 60s. Authorization AUTH_IPD.

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
