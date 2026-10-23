# Sprint 4 — Appointment (Page 30 modal form + Page 31 list) — APEX 24.2

> Hospital kaj: phone/counter e doctor er **time slot** book kora. Registered patient **ba** walk-in (nam + mobile) — dutoi cholbe.
> Tables: `HMS_APPOINTMENT`, `HMS_DOCTOR_SCHEDULE` (Sprint 3 e banano), `HMS_PATIENT`.
> **Design decision:** Calendar na — **Classic Report (din onujayi list) + modal form**. Page 30 modal, tai **sorasori Run kora jay na** — Page 31 theke `Book Appointment` diye test korun.
> Date mask sob jaygay **`DD/MM/YYYY`** (purono guide er `DD-MON-YYYY` bad).

## STEP 0 — DB trigger (ekbar)
`database/11_apex_support/08_appointment_trigger.sql` run. `TRG_APPOINTMENT_BI` (BEFORE INSERT):
- `APPOINTMENT_NO` = `FN_GET_NEXT_NO(branch,'APPOINTMENT')` (`APT-YYMMDD-00001`)
- `SERIAL_NO` = oi doctor + oi din er `MAX+1`
- `PATIENT_NAME` = registered patient hole `PKG_PATIENT.get_full_name`
Keno trigger: page e `(Auto)` item + process unreliable (Employee code er moto).
Menu: `UPDATE HMS_APP_MODULE SET APEX_PAGE_NO = 31 WHERE MODULE_CODE='APPOINTMENT'; COMMIT;` (menu **DB theke** ashe — `VW_APEX_MENU`; Shared Components e Target bodlay na). Sign out ▸ login.

## STEP 1 — Page 30 (Create Page ▸ Form ▸ Form)
Page `30` · Name `Appointment` · **Modal Dialog** · no menu entry · Table `HMS_APPOINTMENT` · PK `APPOINTMENT_ID`.
Columns rakhun: APPOINTMENT_ID, BRANCH_ID, PATIENT_ID, PATIENT_NAME, MOBILE_NO, DOCTOR_ID, APPOINTMENT_DATE, SLOT_TIME, BOOKING_SOURCE, REMARKS. **Bad:** APPOINTMENT_NO, SCHEDULE_ID, SERIAL_NO, CANCEL_REASON, OPD_VISIT_ID, IS_ACTIVE, audit 4, **APPOINTMENT_STATUS** (form theke mucho — DB default `BOOKED`; status bodlabe alada button).
Page: Dialog Width `720` · Authorization `AUTH_APPOINTMENT_ADD`.

## STEP 2 — Items
1. **P30_APPOINTMENT_ID** Hidden · PK.
2. **P30_BRANCH_ID** Hidden · Default Item `G_BRANCH_ID`.
3. **P30_PATIENT_ID** Popup LOV `Registered Patient` · `SELECT D, R FROM VW_LOV_PATIENT WHERE BRANCH_ID = :G_BRANCH_ID ORDER BY D` · Null `- Search by MRN, name or phone -` · Manual Entry No · **Required Off** (walk-in) · Span 12.
4. **P30_PATIENT_NAME** Text `Patient Name (walk-in)` · Max 200 · Span 6.
5. **P30_MOBILE_NO** Text `Mobile No` · Required · Span 6.
6. **P30_DOCTOR_ID** Select List `Doctor` · `SELECT D, R FROM VW_LOV_DOCTOR WHERE BRANCH_ID = :G_BRANCH_ID ORDER BY D` · Null `- Select Doctor -` · Required · Span 12.
7. **P30_APPOINTMENT_DATE** Date Picker `Date` · Format Mask `DD/MM/YYYY` · Required · Default PL/SQL Expression `TO_CHAR(SYSDATE,'DD/MM/YYYY')` · **Minimum Date dibenna** (purono booking edit atke jabe) · Span 6.
8. **P30_SLOT_TIME** Select List `Time Slot` · Required · **Cascading LOV Parent** `P30_DOCTOR_ID,P30_APPOINTMENT_DATE` · Page Items to Submit `P30_APPOINTMENT_ID` · Null `- Select Slot -` · Start New Row No · Span 6:
```
SELECT t AS d, t AS r
  FROM (SELECT TO_CHAR(TO_DATE(s.START_TIME,'HH24:MI')
                       + (n.num - 1) * NVL(s.SLOT_DURATION_MIN, 10) / 1440, 'HH24:MI') AS t
          FROM HMS_DOCTOR_SCHEDULE s
          JOIN (SELECT LEVEL AS num FROM DUAL CONNECT BY LEVEL <= 200) n
            ON n.num <= NVL(s.MAX_SLOTS, 200)
         WHERE s.DOCTOR_ID   = :P30_DOCTOR_ID
           AND s.IS_ACTIVE   = 'Y'
           AND s.DAY_OF_WEEK = TO_CHAR(TO_DATE(:P30_APPOINTMENT_DATE,'DD/MM/YYYY'),
                                       'FMDAY', 'NLS_DATE_LANGUAGE=ENGLISH')
           AND TO_DATE(s.START_TIME,'HH24:MI')
               + n.num * NVL(s.SLOT_DURATION_MIN, 10) / 1440
               <= TO_DATE(s.END_TIME,'HH24:MI'))
 WHERE t NOT IN (SELECT a.SLOT_TIME
                   FROM HMS_APPOINTMENT a
                  WHERE a.DOCTOR_ID = :P30_DOCTOR_ID
                    AND a.SLOT_TIME IS NOT NULL
                    AND a.APPOINTMENT_DATE = TO_DATE(:P30_APPOINTMENT_DATE,'DD/MM/YYYY')
                    AND a.APPOINTMENT_STATUS <> 'CANCELLED'
                    AND a.APPOINTMENT_ID <> NVL(:P30_APPOINTMENT_ID, -1))
 ORDER BY t
```
   Schedule nai emon din e list **khali** (bug na). Slot = schedule START_TIME theke `SLOT_DURATION_MIN` por por, `MAX_SLOTS` porjonto, slot shesh `END_TIME` er moddhe; booked slot bad (`CANCELLED` bad jay na).
9. **P30_BOOKING_SOURCE** Radio Group · `Counter→COUNTER, Phone→PHONE, Online→ONLINE, App→APP` · Default `COUNTER` · 4 columns.
10. **P30_REMARKS** Textarea · Max 500 · 2 rows.
Template `Optional - Floating` (radio e `Optional`).

## STEP 3 — DA, Validation, Button, Process
**DA `Fill patient details`:** Change `P30_PATIENT_ID` · Fire on Init **Off** · True 1: **Set Value** SQL `SELECT PKG_PATIENT.get_full_name(:P30_PATIENT_ID) FROM DUAL` → `P30_PATIENT_NAME` · True 2: SQL `SELECT PHONE_PRIMARY FROM HMS_PATIENT WHERE PATIENT_ID = :P30_PATIENT_ID` → `P30_MOBILE_NO` (Items to Submit `P30_PATIENT_ID`).

**Validations** (sob gulo Condition **Request is contained in Value** `CREATE,SAVE`, Display `Inline with Field and in Notification`):
1. `Patient or name` — Expression PL/SQL `:P30_PATIENT_ID IS NOT NULL OR :P30_PATIENT_NAME IS NOT NULL` · `Select a registered patient or enter the walk-in patient name.` · Item `P30_PATIENT_NAME`
2. `Mobile format` — `REGEXP_LIKE(:P30_MOBILE_NO, '^(\+?880)?01[3-9][0-9]{8}$')` · `Enter a valid Bangladeshi mobile number, for example 01712345678.` · Item `P30_MOBILE_NO`
3. `Date not in the past` — `:P30_APPOINTMENT_ID IS NOT NULL OR TO_DATE(:P30_APPOINTMENT_DATE,'DD/MM/YYYY') >= TRUNC(SYSDATE)` · `Appointment date cannot be in the past.` · Item `P30_APPOINTMENT_DATE`
4. `Slot still free` — **NOT Exists (SQL query returns no rows)** · `This slot was just booked by someone else. Please choose another slot.` · Item `P30_SLOT_TIME`:
```
SELECT 1 FROM HMS_APPOINTMENT
 WHERE DOCTOR_ID = :P30_DOCTOR_ID AND SLOT_TIME = :P30_SLOT_TIME
   AND APPOINTMENT_DATE = TO_DATE(:P30_APPOINTMENT_DATE,'DD/MM/YYYY')
   AND APPOINTMENT_STATUS <> 'CANCELLED'
   AND APPOINTMENT_ID <> NVL(:P30_APPOINTMENT_ID,-1)
```
**Buttons:** DELETE muchhe din · CREATE label `Book Appointment` (Hot) · SAVE `Save Changes` (Hot) · CANCEL.
**Processes:** ARP `Process form Appointment` — Success Message **khali**, Condition `CREATE,SAVE`, **Return Primary Key(s) after Insert On**. Tarpor (Close Dialog er age) Execute Code `Success message`, Condition `CREATE,SAVE`:
```
DECLARE
    l_no  HMS_APPOINTMENT.APPOINTMENT_NO%TYPE;
    l_ser HMS_APPOINTMENT.SERIAL_NO%TYPE;
BEGIN
    SELECT APPOINTMENT_NO, SERIAL_NO INTO l_no, l_ser
      FROM HMS_APPOINTMENT WHERE APPOINTMENT_ID = :P30_APPOINTMENT_ID;
    apex_application.g_print_success_message :=
        '<span class="fa fa-check-circle"></span> Appointment '
        || apex_escape.html(l_no) || ' booked. Serial no: ' || l_ser || '.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        apex_application.g_print_success_message :=
            '<span class="fa fa-check-circle"></span> Appointment saved.';
END;
```
Close Dialog sobar shesh.

## STEP 4 — Page 31 Appointments (Blank Page, Normal, Authorization `AUTH_APPOINTMENT`)
**Region `Filters`** (Static Content, Standard): `P31_DATE` Date Picker (`DD/MM/YYYY`, Required, Default `TO_CHAR(SYSDATE,'DD/MM/YYYY')`, Span 4) · `P31_DOCTOR_ID` Select (`VW_LOV_DOCTOR`, Null `All Doctors`, Start New Row No, Span 4).
**Region `Appointment List`** (Classic Report, Standard, CSS Class `hms-wide`, Static ID `appt_list`, Items to Submit `P31_DATE,P31_DOCTOR_ID`, Row Ranges 25, No data `No appointments found for this date.`):
```
SELECT c.APPOINTMENT_ID, c.SLOT_TIME, c.SERIAL_NO,
       '<span class="hms-code">' || c.APPOINTMENT_NO || '</span>' AS APPT_NO,
       c.PATIENT_NAME, c.MOBILE, c.DOCTOR_NAME,
       CASE c.APPOINTMENT_STATUS
         WHEN 'BOOKED'    THEN '<span class="hms-badge hms-st-WARN">Booked</span>'
         WHEN 'CONFIRMED' THEN '<span class="hms-badge hms-st-WARN">Confirmed</span>'
         WHEN 'ARRIVED'   THEN '<span class="hms-badge hms-st-Y">Arrived</span>'
         WHEN 'COMPLETED' THEN '<span class="hms-badge hms-st-Y">Completed</span>'
         WHEN 'CANCELLED' THEN '<span class="hms-badge hms-st-LOCK">Cancelled</span>'
         ELSE                  '<span class="hms-badge hms-st-N">No show</span>'
       END AS STATUS_BADGE
  FROM VW_APPOINTMENT_CAL c
 WHERE c.BRANCH_ID = :G_BRANCH_ID
   AND c.APPOINTMENT_DATE = TO_DATE(:P31_DATE, 'DD/MM/YYYY')
   AND (:P31_DOCTOR_ID IS NULL OR c.DOCTOR_ID = :P31_DOCTOR_ID)
 ORDER BY c.SLOT_TIME, c.SERIAL_NO
```
Columns: `APPOINTMENT_ID` Link (Page 30, Set Items `P30_APPOINTMENT_ID`=`#APPOINTMENT_ID#`, Clear Cache 30, Heading ek space, Link Text `<span class="fa fa-edit" aria-label="Edit"></span>`) · `APPT_NO`, `STATUS_BADGE` **Escape Off** · Headings Time/Serial/Appointment No/Patient/Mobile/Doctor/Status.
**Button `BOOK`** (region `Appointment List`, **Position `Edit`** = header er dane upore; `Create` = niche dane; `Right of Title` = titler pashe) · Label `Book Appointment` · Hot · `fa-plus` · Action **Redirect to Page in this Application** · Page 30 · Set Items `P30_APPOINTMENT_DATE`=`&P31_DATE.` ar `P30_DOCTOR_ID`=`&P31_DOCTOR_ID.` · Clear Cache 30.
**DA 1** `Refresh list on filter`: Change `P31_DATE,P31_DOCTOR_ID` ▸ Refresh `Appointment List`. **DA 2** `Refresh list on close`: **Dialog Closed** · jQuery Selector `body` ▸ Refresh `Appointment List`.

## ✅ Test (Page 31 theke)
1. Book ▸ registered patient select ▸ nam + mobile nije bhorbe. Doctor + Date (Doctor er schedule ase emon din) ▸ slot list. Book ▸ `Appointment APT-YYMMDD-00001 booked. Serial no: 1.`
2. Walk-in: Registered Patient khali, nam + mobile ▸ Book.
3. Dutoi khali ▸ error. Same slot abar ▸ list e nai. Ateeter tarikh ▸ error.
4. `SELECT appointment_no, patient_name, doctor_id, appointment_date, slot_time, serial_no, appointment_status FROM hms_appointment ORDER BY appointment_id DESC;`

## Problem hole
| Problem | Fix |
|---|---|
| Page 30 ▶ Run e kaj kore na | Modal — Page 31 er `Book Appointment` diye khulun |
| Slot list khali | Oi doctor er oi **din** e active schedule nai (Sprint 3 e Add Schedule) |
| ORA-01843 | Date item Format Mask `DD/MM/YYYY` ar SQL e `TO_DATE(...,'DD/MM/YYYY')` |
| ORA-01400 APPOINTMENT_NO | `08_appointment_trigger.sql` run hoy ni / item `P30_APPOINTMENT_NO` form e roye geche (mucho) |
| ORA-01400 APPOINTMENT_STATUS | item muchhe din (DB default `BOOKED`) |
| Menu Appointment e Page 30 | `UPDATE HMS_APP_MODULE SET APEX_PAGE_NO=31 WHERE MODULE_CODE='APPOINTMENT'` |
| Button title er gaye | Position `Edit` |
