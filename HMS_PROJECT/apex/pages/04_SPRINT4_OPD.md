# SPRINT 4 — Appointment + OPD (Page 30, 31, 20, 21, 211, 3, 22, 23)

🎯 **Ei sprint e ki hobe:** Appointment → Reception visit + fee → Queue → Doctor consultation → Prescription print.

## Shuru-r age (check)
- [ ] Sprint 3 test data: ≥1 Dept, Doctor (employee link soho), Doctor Schedule (aajker din), Consultation fee
- [ ] DB: `03_apex_views.sql` run (VW_APPOINTMENT_CAL, VW_DOCTOR_QUEUE)
- [ ] Doctor login test er jonno: HMS_USER.EMPLOYEE_ID = doctor er employee + DOCTOR role (ADMIN er employee link nai, tai Page 3 e ADMIN kichu dekhbe na — normal)

**Build order:** 30 → 31 → 20 → 21 → 211 → 3 → 22 → 23 (patient flow onujayi)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Flow: **Appointment (30/31)** → **Reception visit (20)** → **Queue (21/211)** → **Doctor (3 → 22)** → **Print (23)**
Pre-req: Sprint 3 test data (doctor + schedule + dept).

---
## PAGE 30 — Appointment Booking (Modal)
Create Page ▸ **Form** ▸ 30 ▸ Modal ▸ Table `HMS_APPOINTMENT` ▸ PK APPOINTMENT_ID. Width 720. Authorization **AUTH_APPOINTMENT_ADD**.
Delete audit items + OPD_VISIT_ID, CANCEL_REASON (edit e dekhaben).
| Item | Type | Setting |
|---|---|---|
| P30_BRANCH_ID | Hidden | Default G_BRANCH_ID |
| P30_APPOINTMENT_NO | Display Only | `(Auto)` |
| P30_PATIENT_ID | Popup LOV | `SELECT D,R FROM VW_LOV_PATIENT WHERE BRANCH_ID=:G_BRANCH_ID` · Settings ▸ **Manual Entry No** · Search on type |
| P30_PATIENT_NAME | Text | Walk-in/unregistered hole (Required if patient null) |
| P30_MOBILE_NO | Telephone | Required |
| P30_DOCTOR_ID | Popup LOV | `SELECT D,R FROM VW_LOV_DOCTOR WHERE BRANCH_ID=:G_BRANCH_ID` Required |
| P30_APPOINTMENT_DATE | Date Picker | Min `+0d`, Default `SYSDATE` (PL/SQL `TO_CHAR(SYSDATE,'DD-MON-YYYY')`) |
| P30_SLOT_TIME | Select List | **Cascading LOV** Parent: `P30_DOCTOR_ID,P30_APPOINTMENT_DATE` · SQL niche · Display Null `- Select Slot -` |
| P30_BOOKING_SOURCE | Radio (pill) | `Counter;COUNTER,Phone;PHONE,Online;ONLINE,App;APP` · Default COUNTER |
| P30_APPOINTMENT_STATUS | Select | Default BOOKED · Condition edit mode |
| P30_REMARKS | Textarea | |
Slot SQL:
```sql
WITH s AS (
  SELECT START_TIME, SLOT_DURATION_MIN dur, NVL(MAX_SLOTS,30) mx
    FROM HMS_DOCTOR_SCHEDULE
   WHERE DOCTOR_ID = :P30_DOCTOR_ID AND IS_ACTIVE = 'Y'
     AND DAY_OF_WEEK = TO_CHAR(TO_DATE(:P30_APPOINTMENT_DATE,'DD-MON-YYYY'),'FMDAY','NLS_DATE_LANGUAGE=ENGLISH')
     AND ROWNUM = 1),
slots AS (
  SELECT TO_CHAR(TO_DATE(s.START_TIME,'HH24:MI') + (LEVEL-1)*s.dur/1440,'HH24:MI') t
    FROM s CONNECT BY LEVEL <= s.mx)
SELECT t d, t r FROM slots
 WHERE t NOT IN (SELECT SLOT_TIME FROM HMS_APPOINTMENT
                  WHERE DOCTOR_ID = :P30_DOCTOR_ID AND SLOT_TIME IS NOT NULL
                    AND APPOINTMENT_DATE = TO_DATE(:P30_APPOINTMENT_DATE,'DD-MON-YYYY')
                    AND APPOINTMENT_STATUS NOT IN ('CANCELLED')
                    AND APPOINTMENT_ID <> NVL(:P30_APPOINTMENT_ID,-1))
 ORDER BY t
```
DA: P30_PATIENT_ID change → Set Value SQL `SELECT PHONE_PRIMARY FROM HMS_PATIENT WHERE PATIENT_ID=:P30_PATIENT_ID` → P30_MOBILE_NO.
Validation: `:P30_PATIENT_ID IS NOT NULL OR :P30_PATIENT_NAME IS NOT NULL`.
**[Process] Set Number** (before ARP, CREATE):
```plsql
:P30_APPOINTMENT_NO := FN_GET_NEXT_NO(:G_BRANCH_ID,'APPOINTMENT');
SELECT NVL(MAX(SERIAL_NO),0)+1 INTO :P30_SERIAL_NO FROM HMS_APPOINTMENT
 WHERE DOCTOR_ID=:P30_DOCTOR_ID AND APPOINTMENT_DATE=TO_DATE(:P30_APPOINTMENT_DATE,'DD-MON-YYYY');
IF :P30_PATIENT_NAME IS NULL THEN :P30_PATIENT_NAME := PKG_PATIENT.get_full_name(:P30_PATIENT_ID); END IF;
```
(P30_SERIAL_NO hidden item rakhun.) Then ARP → Close Dialog. Success `Appointment &P30_APPOINTMENT_NO. booked (Serial &P30_SERIAL_NO.)`.

## PAGE 31 — Appointment Calendar / List
Create Page ▸ **Calendar** ▸ 31 ▸ Source `VW_APPOINTMENT_CAL` + where `BRANCH_ID=:G_BRANCH_ID AND (:P31_DOCTOR_ID IS NULL OR DOCTOR_ID=:P31_DOCTOR_ID)`.
| Calendar attribute | Value |
|---|---|
| Display Column | `PATIENT_NAME` (ba SQL e `SLOT_TIME||' '||PATIENT_NAME title`) |
| Start Date | START_DT · End: blank |
| CSS Class | SQL column `CASE APPOINTMENT_STATUS WHEN 'CANCELLED' THEN 'apex-cal-red' WHEN 'ARRIVED' THEN 'apex-cal-green' WHEN 'COMPLETED' THEN 'apex-cal-gray' ELSE 'apex-cal-blue' END css` |
| View/Edit Link | Page 30 `P30_APPOINTMENT_ID=&APPOINTMENT_ID.` |
| Create Link | Page 30 |
| Views | Month, Week, Day, **List** ON · Default **Week** |
| Start/End time | 08:00 – 22:00 |
Item `P31_DOCTOR_ID` (Select, VW_LOV_DOCTOR, Display Null `All Doctors`) upore; DA change → refresh calendar (Items to submit set in region *Page Items to Submit*).
Button `Book Appointment` (Hot) → 30.
**Arrived** action: 30 er edit e button `CHECK_IN` → Redirect Page 20 with `P20_PATIENT_ID`, `P20_DOCTOR_ID`, `P20_APPOINTMENT_ID`.

---
## PAGE 20 — New OPD Visit (Reception) ⭐
Create Page ▸ **Blank** ▸ 20 `OPD Visit` ▸ Normal. Authorization **AUTH_OPD_ADD**.

### Regions (grid)
| Region | Type | Span | Template |
|---|---|---|---|
| Patient | Static Content | 12 | Standard |
| Visit Details | Static | 8 | Standard |
| Fee Summary | Static (Static ID `fee_card`) | 4 (New Row No) | **Cards**? → use Standard + CSS class `hms-kpi blue` (Appearance ▸ CSS Classes) |

### Items
| Item | Region | Type | Setting |
|---|---|---|---|
| P20_PATIENT_ID | Patient | Popup LOV | VW_LOV_PATIENT, Required, Span 8 |
| P20_NEW_PATIENT (button, not item) | Patient | Button `+ New Patient` → Page 10 (modal na; return e patient set korte 10 er branch e `P20_PATIENT_ID`) |
| P20_PATIENT_INFO | Patient | Display Only | Format HTML · computed by DA (niche) |
| P20_DEPT_ID | Visit | Select | `SELECT D,R FROM VW_LOV_DEPARTMENT WHERE BRANCH_ID=:G_BRANCH_ID AND DEPT_TYPE='CLINICAL' ORDER BY 1` |
| P20_DOCTOR_ID | Visit | Select (Cascading parent P20_DEPT_ID) | `SELECT D,R FROM VW_LOV_DOCTOR WHERE (:P20_DEPT_ID IS NULL OR DEPT_ID=:P20_DEPT_ID) AND BRANCH_ID=:G_BRANCH_ID` Required |
| P20_APPOINTMENT_ID | Visit | Hidden | from 31 |
| P20_VISIT_TYPE_INFO | Visit | Display Only | "New / Follow-up (free till …)" — DA |
| P20_DISCOUNT | Fee | Number | Default 0, Authorization AUTH_BILLING_APPROVE (na thakle read-only) |
| P20_FEE | Fee | Display Only | label `Consultation Fee (Tk)` |
| P20_NET | Fee | Display Only | big font: Appearance ▸ CSS Classes `u-bold` |
| P20_PAY_NOW | Fee | Switch | Default Y |
| P20_PAYMENT_MODE | Fee | Select | LOOKUP 'PAYMENT_MODE' default CASH · Show when PAY_NOW=Y (DA Show/Hide) |
| P20_TXN_REF | Fee | Text | Show when mode <> CASH |
| P20_VISIT_ID / P20_VISIT_NO / P20_BILL_ID | – | Hidden | |

### DAs
1. **Patient Info** – Change P20_PATIENT_ID → Set Value (SQL):
```sql
SELECT MRN||' · '||PATIENT_NAME||' · '||GENDER||' · '||AGE||NVL2(ALLERGIES,' · ⚠ '||ALLERGIES,NULL)
  FROM VW_PATIENT_SUMMARY WHERE PATIENT_ID = :P20_PATIENT_ID
```
   Items to Submit P20_PATIENT_ID → Affected P20_PATIENT_INFO
2. **Doctor Fee** – Change P20_DOCTOR_ID → Execute Server-side Code (Items to Submit P20_DOCTOR_ID,P20_PATIENT_ID; Items to Return P20_FEE,P20_VISIT_TYPE_INFO):
```plsql
DECLARE l_last DATE; l_days NUMBER; l_fee NUMBER; l_fu NUMBER;
BEGIN
  SELECT CONSULTATION_FEE, FOLLOWUP_FEE, FOLLOWUP_VALID_DAYS INTO l_fee, l_fu, l_days
    FROM HMS_DOCTOR WHERE DOCTOR_ID = :P20_DOCTOR_ID;
  SELECT MAX(VISIT_DATE) INTO l_last FROM HMS_OPD_VISIT
   WHERE PATIENT_ID = :P20_PATIENT_ID AND DOCTOR_ID = :P20_DOCTOR_ID AND VISIT_STATUS <> 'CANCELLED';
  IF l_last IS NOT NULL AND TRUNC(SYSDATE) - l_last <= NVL(l_days,7) THEN
     :P20_FEE := l_fu; :P20_VISIT_TYPE_INFO := 'Follow-up (last visit '||TO_CHAR(l_last,'DD-Mon')||')';
  ELSE
     :P20_FEE := l_fee; :P20_VISIT_TYPE_INFO := 'New visit';
  END IF;
END;
```
   (Asol fee PKG_OPD nijei hisab kore; eta shudhu display.)
3. **Net** – Change P20_FEE, P20_DISCOUNT → Set Value JS Expression `(parseFloat($v('P20_FEE'))||0) - (parseFloat($v('P20_DISCOUNT'))||0)` → P20_NET
4. Show/Hide P20_PAYMENT_MODE (P20_PAY_NOW = Y), P20_TXN_REF (mode != CASH)

### Button + Process
`[Button] CREATE` label `Create Visit & Token` Hot, fa-ticket, Position Next.
**[Process] Create Visit** (CREATE):
```plsql
DECLARE l_no VARCHAR2(30); l_bill NUMBER; l_rcpt NUMBER; l_due NUMBER;
BEGIN
  :P20_VISIT_ID := PKG_OPD.create_visit(:G_BRANCH_ID, :P20_PATIENT_ID, :P20_DOCTOR_ID, :P20_DEPT_ID,
                                        :P20_APPOINTMENT_ID, NVL(:P20_DISCOUNT,0), l_no, l_bill);
  :P20_VISIT_NO := l_no; :P20_BILL_ID := l_bill;
  IF :P20_PAY_NOW = 'Y' AND l_bill IS NOT NULL THEN
     SELECT DUE_AMOUNT INTO l_due FROM HMS_BILLING WHERE BILL_ID = l_bill;
     IF l_due > 0 THEN
        l_rcpt := PKG_BILLING.receive_payment(l_bill, l_due, :P20_PAYMENT_MODE, :P20_TXN_REF, :G_EMPLOYEE_ID);
     END IF;
  END IF;
END;
```
Success `Visit &P20_VISIT_NO. created.` · Branch → **Page 73** (`P73_BILL_ID=&P20_BILL_ID.`) print token+receipt.
Validation: patient + doctor required (item level).

✅ Test: patient select → info · doctor select → fee · Create → HMS_OPD_VISIT row, token, bill, receipt.

---
## PAGE 21 — OPD Queue (Reception)
Create Page ▸ **Interactive Report** 21, source:
```sql
SELECT VISIT_ID, TOKEN_NO, VISIT_NO, MRN, PATIENT_NAME, GENDER, AGE, DOCTOR_NAME, DEPT_NAME,
       VISIT_TYPE, VISIT_STATUS, PAYMENT_STATUS, WAITING_MIN, DOCTOR_ID
  FROM VW_OPD_DASHBOARD
 WHERE VISIT_DATE = TRUNC(SYSDATE) AND BRANCH_ID = :G_BRANCH_ID
```
- Static ID `queue` · VISIT_STATUS / PAYMENT_STATUS badge HTML · Default sort TOKEN_NO
- Highlight: WAITING_MIN > 30 and status WAITING → orange row; PAYMENT_STATUS <> 'PAID' → red cell
- Save default report with Control Break on DOCTOR_NAME (Actions ▸ Format ▸ Control Break)
- Row link column → action menu: *Cancel visit* (Page 212 modal: reason → `UPDATE HMS_OPD_VISIT SET VISIT_STATUS='CANCELLED', REMARKS=:reason` + `PKG_BILLING.cancel_bill`)
- DA Page Load: `setInterval(()=>apex.region('queue').refresh(),30000);`
- Button `New Visit` → 20, `TV Display` → 211 (Target *New Window*)
Authorization AUTH_OPD.

## PAGE 211 — Token TV Display
Create Page ▸ Blank ▸ 211 ▸ Page Template **Minimal (No Navigation)** ▸ Authentication: *Page Requires Authentication* (TV e reception user login rakhe).
Region **Cards**, Static ID `tv`:
```sql
SELECT DOCTOR_NAME, DEPT_NAME,
       MAX(CASE WHEN VISIT_STATUS='IN_CONSULTATION' THEN TOKEN_NO END) NOW_SERVING,
       COUNT(CASE WHEN VISIT_STATUS='WAITING' THEN 1 END) WAITING
  FROM VW_OPD_DASHBOARD
 WHERE VISIT_DATE=TRUNC(SYSDATE) AND BRANCH_ID=:G_BRANCH_ID
 GROUP BY DOCTOR_NAME, DEPT_NAME
```
Cards: Title `Token &NOW_SERVING.` · Subtitle `Dr. &DOCTOR_NAME.` · Body `&DEPT_NAME. · Waiting: &WAITING.` · Grid 3 col · CSS Classes `hms-kpi blue`
Page ▸ CSS Inline: `.hms-kpi .a-CardView-title{font-size:3.5rem} body{background:#0b2e40}`
DA: refresh every 10s. Browser F11 full screen.

---
## PAGE 3 — Doctor Dashboard (My Patients)
Create Page ▸ **Cards** ▸ 3 `My Queue` ▸ source:
Item `P3_DOCTOR_ID` (Select, `SELECT D,R FROM VW_LOV_DOCTOR WHERE BRANCH_ID=:G_BRANCH_ID`, Display Null `My Queue`) — Admin/onno doctor er queue dekhte. Doctor nije khali rakhle nijer queue.
```sql
SELECT VISIT_ID, TOKEN_NO, PATIENT_NAME, MRN, GENDER, AGE, VISIT_STATUS
  FROM VW_DOCTOR_QUEUE
 WHERE BRANCH_ID = :G_BRANCH_ID
   AND DOCTOR_ID = NVL(:P3_DOCTOR_ID, (SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :G_EMPLOYEE_ID))
 ORDER BY TOKEN_NO
```
Region ▸ Page Items to Submit `P3_DOCTOR_ID` · DA change → refresh region.
Cards: Title `#&TOKEN_NO. &PATIENT_NAME.` · Subtitle `&MRN. · &GENDER. · &AGE.` · Badge VISIT_STATUS · Grid 4 col
Action Full Card → **Page 22** set `P22_VISIT_ID=&VISIT_ID.`
Authorization **AUTH_DOCTOR**. Auto refresh 30s. Menu: HMS_APP_MODULE e ekta row add korun (Doctor Dashboard, page 3) ba Dashboard e button.

---
## PAGE 22 — Consultation (EMR) ⭐⭐
Create Page ▸ Blank ▸ 22 `Consultation` ▸ Normal ▸ Authorization **AUTH_DOCTOR**.

### Pre-Rendering (Before Header) processes
1. **Start**:
```plsql
PKG_OPD.start_consultation(:P22_VISIT_ID);   -- status IN_CONSULTATION
SELECT v.PATIENT_ID, v.DOCTOR_ID INTO :P22_PATIENT_ID, :P22_DOCTOR_ID FROM HMS_OPD_VISIT v WHERE v.VISIT_ID=:P22_VISIT_ID;
BEGIN
  SELECT CONSULTATION_ID INTO :P22_CONSULTATION_ID FROM HMS_OPD_CONSULTATION WHERE VISIT_ID=:P22_VISIT_ID;
EXCEPTION WHEN NO_DATA_FOUND THEN
  INSERT INTO HMS_OPD_CONSULTATION (VISIT_ID, DOCTOR_ID, CONSULTATION_START)
  VALUES (:P22_VISIT_ID, :P22_DOCTOR_ID, SYSTIMESTAMP) RETURNING CONSULTATION_ID INTO :P22_CONSULTATION_ID;
END;
BEGIN
  SELECT PRESCRIPTION_ID INTO :P22_PRESCRIPTION_ID FROM HMS_OPD_PRESCRIPTION WHERE VISIT_ID=:P22_VISIT_ID;
EXCEPTION WHEN NO_DATA_FOUND THEN
  INSERT INTO HMS_OPD_PRESCRIPTION (VISIT_ID, CONSULTATION_ID, PRESCRIPTION_NO, DOCTOR_ID)
  VALUES (:P22_VISIT_ID, :P22_CONSULTATION_ID, 'RX-'||:P22_VISIT_ID, :P22_DOCTOR_ID)
  RETURNING PRESCRIPTION_ID INTO :P22_PRESCRIPTION_ID;
END;
```
   Condition: `:P22_VISIT_ID IS NOT NULL` · Hidden items: P22_VISIT_ID (checksum), P22_PATIENT_ID, P22_DOCTOR_ID, P22_CONSULTATION_ID, P22_PRESCRIPTION_ID
2. **Load consultation** – Form region "Consultation" (niche) er *Initialize Form* process (auto).

### Layout
```
┌ Banner (12) ───────────────────────────────────────────────────────┐
├ Left 4 ──────────────┬ Right 8 (Tabs) ─────────────────────────────┤
│ Vitals (form)        │ [Complaint & Exam] [Prescription] [Tests]   │
│ Previous visits      │ [Advice & Follow-up]                        │
└──────────────────────┴─────────────────────────────────────────────┘
               [Save Draft]  [Complete & Print]
```
### Region: Banner (Static, 12)
Same as page 12 banner — source items via SQL: create Classic Report template *Value Attribute Pairs – Row* ▸
`SELECT MRN, PATIENT_NAME, AGE, GENDER, BLOOD_GROUP, ALLERGIES FROM VW_PATIENT_SUMMARY WHERE PATIENT_ID=:P22_PATIENT_ID` ▸ CSS class `hms-banner`.

### Region: Vitals (Span 4) — Form on `HMS_OPD_VITALS`
Create as **Form region** (region type Form, table HMS_OPD_VITALS, PK VITAL_ID; Initialize where `VISIT_ID=:P22_VISIT_ID`? → Form region needs PK; simpler: **Static region + items + PKG call**):
Items (Number, Span 6 each, Floating): P22_BP_SYS `BP Sys`, P22_BP_DIA `BP Dia`, P22_PULSE, P22_TEMP `Temp °F`, P22_SPO2 `SpO2 %`, P22_WEIGHT `Wt kg`, P22_HEIGHT `Ht cm`, P22_BMI (Display, DA JS `w/((h/100)^2)`)
Load (Pre-Rendering): `SELECT BP_SYSTOLIC,BP_DIASTOLIC,PULSE_RATE,TEMPERATURE_F,SPO2,WEIGHT_KG,HEIGHT_CM INTO :P22_BP_SYS,... FROM HMS_OPD_VITALS WHERE VISIT_ID=:P22_VISIT_ID AND ROWNUM=1` (exception null)
Button `SAVE_VITALS` (small, fa-heartbeat) → DA **Execute Server-side Code** (no submit):
`PKG_OPD.save_vitals(:P22_VISIT_ID,:P22_BP_SYS,:P22_BP_DIA,:P22_PULSE,:P22_TEMP,:P22_SPO2,:P22_WEIGHT,:P22_HEIGHT);` Items to submit all vitals → next action *Show notification* (`apex.message.showPageSuccess('Vitals saved')`).
Nurse jodi age vitals dey (Page 21 theke), eta pre-filled thakbe.

### Region: Previous Visits (Span 4, below vitals)
Classic Report template **Timeline**? (Content Row) :
```sql
SELECT v.VISIT_DATE, c.PROVISIONAL_DIAGNOSIS, c.ADVICE, v.VISIT_ID
  FROM HMS_OPD_VISIT v LEFT JOIN HMS_OPD_CONSULTATION c ON c.VISIT_ID=v.VISIT_ID
 WHERE v.PATIENT_ID=:P22_PATIENT_ID AND v.VISIT_ID<>:P22_VISIT_ID ORDER BY v.VISIT_DATE DESC FETCH FIRST 5 ROWS ONLY
```
Link → 23 (old prescription view, new window).

### Region: Tabs Container (Span 8, New Row No)
**Tab 1 — Complaint & Exam**: region type **Form**, Table `HMS_OPD_CONSULTATION`, PK CONSULTATION_ID (item P22_CONSULTATION_ID er sathe map: Region ▸ Source ▸ PK item = P22_CONSULTATION_ID)
| Item | Type |
|---|---|
| CHIEF_COMPLAINT | Textarea (3 rows) — Rich? na, plain |
| HISTORY_OF_ILLNESS | Textarea |
| EXAMINATION_NOTES | Textarea |
| PROVISIONAL_DIAGNOSIS | Text |
| ICD_ID | Popup LOV `SELECT ICD_CODE||' - '||ICD_DESCRIPTION d, ICD_ID r FROM HMS_ICD_MASTER WHERE IS_ACTIVE='Y'` |
| FINAL_DIAGNOSIS | Text |
**Tab 2 — Prescription**: **Interactive Grid** on `HMS_OPD_PRESCRIPTION_DTL WHERE PRESCRIPTION_ID = :P22_PRESCRIPTION_ID`, Static ID `rx_ig`, Edit Enabled (Add/Update/Delete)
| Column | Type | Setting |
|---|---|---|
| PRESCRIPTION_DTL_ID | Hidden (PK) | |
| PRESCRIPTION_ID | Hidden | Default ▸ Item P22_PRESCRIPTION_ID |
| ITEM_ID | Popup LOV | `SELECT D,R FROM VW_LOV_MEDICINE` · heading `Medicine` |
| MEDICINE_NAME | Text | *Additional Outputs* of ITEM_ID LOV? → simplest: DA on ITEM_ID change set value SQL `SELECT ITEM_NAME||' '||STRENGTH FROM HMS_PHARMA_ITEM WHERE ITEM_ID=:ITEM_ID` (IG column DA) · free text allowed (outside medicine) |
| DOSAGE | Text | e.g. `1+0+1` placeholder |
| FREQUENCY | Select | LOOKUP 'FREQUENCY' |
| ROUTE | Select | LOOKUP 'ROUTE' |
| DURATION_DAYS | Number | |
| MEAL_INSTRUCTION | Select | Static `Before meal;BEFORE,After meal;AFTER,With meal;WITH,Empty stomach;EMPTY` |
| QUANTITY | Number | |
| INSTRUCTIONS | Text | |
Toolbar: Add Row, Save (IG Save = Automatic Row Processing, wizard adds process "Prescription - Save Interactive Grid Data").
**Template**: "Copy last prescription" button → Server code `INSERT INTO HMS_OPD_PRESCRIPTION_DTL (...) SELECT ... FROM previous prescription` → refresh `rx_ig`.

**Tab 3 — Investigations**:
- `P22_TESTS` **Shuttle** `SELECT D,R FROM VW_LOV_SERVICE WHERE REPORTING_SECTION IS NOT NULL ORDER BY D` (Height 8)
- `P22_PRIORITY` Radio pill `Routine;ROUTINE,Urgent;URGENT,STAT;STAT`
- Button `ORDER_TESTS` → Process (when button):
```plsql
DECLARE l_id NUMBER; l_no VARCHAR2(30);
BEGIN
  l_id := PKG_LAB.create_order(:G_BRANCH_ID, :P22_PATIENT_ID, 'OPD', :P22_VISIT_ID, NULL,
                               :P22_DOCTOR_ID, :P22_PRIORITY, :CHIEF_COMPLAINT_ITEM, l_no);
  PKG_LAB.add_tests(l_id, :P22_TESTS);
  :P22_TESTS := NULL;
END;
```
  (`:CHIEF_COMPLAINT_ITEM` → apnar item naam, e.g. `:P22_CHIEF_COMPLAINT`)
- Report below: ordered tests for this visit (`HMS_INVESTIGATION_ORDER_DTL` join order WHERE OPD_VISIT_ID=:P22_VISIT_ID) with status.

**Tab 4 — Advice & Follow-up** (same Form region items, different sub-region — form region er item drag korte parben na onno region e? → Items er **Region** property change kore Tab 4 sub-region e rakhun, Source ▸ Form Region = Consultation thakbe):
ADVICE (Textarea 5), FOLLOWUP_DATE (Date, quick picks +7d/+15d/+30d buttons via DA), ADMISSION_ADVISED (Switch), REFERRED_TO_DOCTOR_ID (Popup VW_LOV_DOCTOR).
Button `ADMIT` (Condition ADMISSION_ADVISED=Y) → Page 40 `P40_PATIENT_ID, P40_OPD_VISIT_ID`.

### Footer buttons (Region: Buttons Container, Span 12, bottom)
| Button | Hot | Process |
|---|---|---|
| SAVE (`Save Draft`) | No | Form ARP (Consultation) + IG save auto |
| COMPLETE (`Complete & Print`) | Yes, fa-check | ARP → `UPDATE HMS_OPD_CONSULTATION SET CONSULTATION_END=SYSTIMESTAMP WHERE CONSULTATION_ID=:P22_CONSULTATION_ID; PKG_OPD.complete_visit(:P22_VISIT_ID);` → Branch Page 23 (`P23_VISIT_ID`) |
| NEXT_PATIENT | No | Branch Page 3 |
Form region ARP ▸ Condition request in `SAVE,COMPLETE`.
**IG + form ek sathe save:** Page submit korle IG changes o save hoy (IG process same page e).

✅ Test: doctor login (DOCTOR role user, employee link) → 3 e patient → 22 → vitals, complaint, 3 medicine, 2 test → Complete → 23 print.

---
## PAGE 23 — Prescription Print
Create Page ▸ Blank 23 ▸ Page Template **Minimal (No Navigation)** ▸ Authorization AUTH_OPD.
Item P23_VISIT_ID (hidden, checksum).
Region **Rx** ▸ Type **Dynamic Content** ▸ Source: Language **PL/SQL**, **PL/SQL Function Body returning a CLOB** (24.2 te purono *PL/SQL Dynamic Content [Legacy]* use korben na). Code:
```plsql
DECLARE
  CURSOR c_h IS
    SELECT b.BRANCH_NAME, b.ADDRESS_LINE1, b.PHONE, v.VISIT_NO, v.VISIT_DATE,
           p.MRN, TRIM(p.FIRST_NAME||' '||p.LAST_NAME) PNAME, FN_CALCULATE_AGE(p.DATE_OF_BIRTH) AGE, p.GENDER,
           'Dr. '||TRIM(e.FIRST_NAME||' '||e.LAST_NAME) DNAME, d.QUALIFICATION, d.BMDC_REG_NO,
           c.CHIEF_COMPLAINT, c.PROVISIONAL_DIAGNOSIS, c.ADVICE, c.FOLLOWUP_DATE, rx.PRESCRIPTION_ID
      FROM HMS_OPD_VISIT v JOIN HMS_PATIENT p ON p.PATIENT_ID=v.PATIENT_ID
      JOIN HMS_BRANCH b ON b.BRANCH_ID=v.BRANCH_ID
      JOIN HMS_DOCTOR d ON d.DOCTOR_ID=v.DOCTOR_ID JOIN HMS_EMPLOYEE e ON e.EMPLOYEE_ID=d.EMPLOYEE_ID
      LEFT JOIN HMS_OPD_CONSULTATION c ON c.VISIT_ID=v.VISIT_ID
      LEFT JOIN HMS_OPD_PRESCRIPTION rx ON rx.VISIT_ID=v.VISIT_ID
     WHERE v.VISIT_ID = :P23_VISIT_ID;
  h c_h%ROWTYPE;
  l_html CLOB;
  PROCEDURE w(p VARCHAR2) IS BEGIN l_html := l_html || p; END;
  FUNCTION esc(p VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN APEX_ESCAPE.HTML(p); END;
BEGIN
  OPEN c_h; FETCH c_h INTO h; CLOSE c_h;
  w('<div class="rx">');
  w('<div class="rx-head"><h2>'||esc(h.BRANCH_NAME)||'</h2><div>'||esc(h.ADDRESS_LINE1)||' · '||esc(h.PHONE)||'</div></div>');
  w('<div class="rx-doc"><b>'||esc(h.DNAME)||'</b><br>'||esc(h.QUALIFICATION)||'<br>BMDC: '||esc(h.BMDC_REG_NO)||'</div>');
  w('<div class="rx-pat">'||esc(h.PNAME)||' · '||esc(h.AGE)||' · '||esc(h.GENDER)||' · MRN '||esc(h.MRN)
        ||' <span style="float:right">'||TO_CHAR(h.VISIT_DATE,'DD-Mon-YYYY')||' · '||esc(h.VISIT_NO)||'</span></div>');
  w('<div class="rx-body"><div class="rx-left"><b>C/C</b><p>'||esc(h.CHIEF_COMPLAINT)||'</p><b>Dx</b><p>'||esc(h.PROVISIONAL_DIAGNOSIS)||'</p>');
  w('<b>Investigations</b><ul>');
  FOR t IN (SELECT d.SERVICE_NAME FROM HMS_INVESTIGATION_ORDER o JOIN HMS_INVESTIGATION_ORDER_DTL d ON d.ORDER_ID=o.ORDER_ID
             WHERE o.OPD_VISIT_ID=:P23_VISIT_ID) LOOP w('<li>'||esc(t.SERVICE_NAME)||'</li>'); END LOOP;
  w('</ul></div><div class="rx-right"><div class="rx-symbol">℞</div><ol>');
  FOR m IN (SELECT MEDICINE_NAME, DOSAGE, MEAL_INSTRUCTION, DURATION_DAYS, INSTRUCTIONS
              FROM HMS_OPD_PRESCRIPTION_DTL WHERE PRESCRIPTION_ID=h.PRESCRIPTION_ID ORDER BY PRESCRIPTION_DTL_ID) LOOP
    w('<li><b>'||esc(m.MEDICINE_NAME)||'</b><br>'||esc(m.DOSAGE)||' — '||esc(m.MEAL_INSTRUCTION)
          ||' — '||m.DURATION_DAYS||' din '||esc(m.INSTRUCTIONS)||'</li>');
  END LOOP;
  w('</ol><b>Advice</b><p>'||REPLACE(esc(h.ADVICE),CHR(10),'<br>')||'</p>');
  IF h.FOLLOWUP_DATE IS NOT NULL THEN w('<p><b>Follow-up:</b> '||TO_CHAR(h.FOLLOWUP_DATE,'DD-Mon-YYYY')||'</p>'); END IF;
  w('</div></div><div class="rx-sign">Signature</div></div>');
  RETURN l_html;
END;
```
Page ▸ CSS ▸ Inline:
```css
.rx{max-width:800px;margin:auto;background:#fff;padding:24px;font-size:14px}
.rx-head{text-align:center;border-bottom:3px solid #0b6e99;padding-bottom:6px}
.rx-head h2{margin:0;color:#0b6e99}
.rx-doc{margin:8px 0}.rx-pat{border-top:1px solid #ccc;border-bottom:1px solid #ccc;padding:6px 0;margin-bottom:10px}
.rx-body{display:flex;gap:16px;min-height:500px}.rx-left{width:32%;border-right:1px solid #ddd;padding-right:10px}
.rx-right{flex:1}.rx-symbol{font-size:40px;color:#0b6e99}.rx-sign{text-align:right;margin-top:40px;border-top:1px dashed #999;width:200px;margin-left:auto}
@page{size:A4;margin:10mm}
```
Buttons (Region Buttons, hidden in print by hms.css): `PRINT` (Hot, fa-print, DA JS `window.print()`) · `BACK` → Page 3.

## Sprint 4 checklist
- [ ] Appointment book (free slot only) + calendar
- [ ] Visit create → bill + receipt + token
- [ ] Queue + TV
- [ ] Doctor queue → EMR → complete → print
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Slot list khali | Schedule er DAY_OF_WEEK full naam (MONDAY) + aajker din; doctor active |
| Page 3 khali | Login user er EMPLOYEE_ID doctor er sathe link nai |
| Print page e kichu nai | Region type **Dynamic Content** + code shesh e `RETURN l_html;` |
