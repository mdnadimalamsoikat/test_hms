# Sprint 3 — Doctor Schedule (Page 911 + modal Page 912) — APEX 24.2

> Age: Doctor Info kaj kore ✅ (Is Doctor? ON ▸ Save). Schedule shudhu **save kora doctor** er jonno — Employee Save kore **abar Edit (pencil)** khule schedule din.
> **Design decision:** Interactive Grid **bad**. Weekly Schedule = **Classic Report (list) + Add/Edit modal form (Page 912)**. Karon: ekbar e ekta schedule, validation spasto, vul kom, UI poriskar.

## Specialization / Qualification (Step 3 er sathe ekta unnoti)
- **P911_QUALIFICATION** — Text Field thik ache (MBBS, FCPS ...).
- **P911_SPECIALIZATION** — **Text Field with Autocomplete** (type korle suggestion, list theke select o kora jay; "Medicine"/"medicine" alada hoy na):
  Type **Text Field with Autocomplete** · LOV Type **SQL Query** (**ek column** — `d`/`r` na; Combobox dile *Manual Entries Item* error ashe) · Settings ▸ Search Type **Contains & Ignore Case**:
  ```sql
  SELECT SPEC FROM (
    SELECT 'Medicine' SPEC FROM DUAL UNION SELECT 'Surgery' FROM DUAL UNION SELECT 'Gynecology & Obstetrics' FROM DUAL
    UNION SELECT 'Pediatrics' FROM DUAL UNION SELECT 'Orthopedics' FROM DUAL UNION SELECT 'Cardiology' FROM DUAL
    UNION SELECT 'Neurology' FROM DUAL UNION SELECT 'ENT' FROM DUAL UNION SELECT 'Eye (Ophthalmology)' FROM DUAL
    UNION SELECT 'Dermatology' FROM DUAL UNION SELECT 'Urology' FROM DUAL UNION SELECT 'Radiology' FROM DUAL
    UNION SELECT 'Anesthesiology' FROM DUAL UNION SELECT 'Pathology' FROM DUAL
    UNION SELECT SPECIALIZATION FROM HMS_DOCTOR WHERE SPECIALIZATION IS NOT NULL)
   ORDER BY 1
  ```
  (Notun specialization type korle porer bar list e ashe. Item na pele sadharon Text Field rakhun.)


## Design
- Page 911 e **Weekly Schedule** = Classic Report (Day · Time · Slot · Max · Room · Status badge · Edit icon) + **Add Schedule** button.
- Add/Edit ▸ **Page 912** (Modal, `HMS_DOCTOR_SCHEDULE`). Save ▸ modal bondho ▸ Dialog Closed DA ▸ list Refresh.
- Delete nai — **Active switch Off** (purono appointment history thik thake).
- Validation: **To > From** ar **ek doctor, ek din e time overlap nai**.

## STEP 1 — Page 912 toiri (Create Page ▸ Form ▸ Form)
Page `912` · Name `Doctor Schedule` · Mode **Modal Dialog** · No navigation entry · Table `HMS_DOCTOR_SCHEDULE` · PK `SCHEDULE_ID`.
Columns rakhun: SCHEDULE_ID, DOCTOR_ID, BRANCH_ID, DAY_OF_WEEK, START_TIME, END_TIME, SLOT_DURATION_MIN, MAX_SLOTS, ROOM_NO, IS_ACTIVE. **Audit 4 column bad** (CREATED_BY/DATE, UPDATED_BY/DATE).
Page property: Dialog Width `640` · Authorization `AUTH_SETUP_EDIT`.

## STEP 2 — Page 912 items
0. **P912_EMPLOYEE_ID** (notun) — Hidden · Source Type **Null** (Page 911 theke ashe, doctor chenar jonno).
1. **P912_SCHEDULE_ID** — Hidden · Primary Key Yes.
2. **P912_DOCTOR_ID** — Hidden · Source DOCTOR_ID · **Default ▸ SQL Query (single value)**: `SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P912_EMPLOYEE_ID`
3. **P912_BRANCH_ID** — Hidden · Default Type **Item** ▸ `G_BRANCH_ID`.
4. **P912_DAY_OF_WEEK** — Select List · Label `Day` · LOV Static `Saturday→SATURDAY … Friday→FRIDAY` (return UPPER) · Display Null `- Select Day -` · Value Required · Span 6.
5. **P912_START_TIME** — Select List · Label `From` · Value Required · Span 6 · LOV SQL (HH24:MI, adha ghonta por por):
```
SELECT TO_CHAR(TRUNC(SYSDATE) + (LEVEL-1)/48, 'HH24:MI') d,
       TO_CHAR(TRUNC(SYSDATE) + (LEVEL-1)/48, 'HH24:MI') r
  FROM DUAL CONNECT BY LEVEL <= 48
```
6. **P912_END_TIME** — Select List · Label `To` · same LOV · Value Required · Start New Row **No** · Span 6.
7. **P912_SLOT_DURATION_MIN** — Number Field · `Slot (min)` · Default Static `10` · Min 5 · Span 4.
8. **P912_MAX_SLOTS** — Number Field · `Max Patients` · Min 1 · Span 4.
9. **P912_ROOM_NO** — Text Field · `Room` · Span 4.
10. **P912_IS_ACTIVE** — Switch · `Active` · On `Y`/Off `N` · Default `Y` · Span 4.
Sob item Template `Optional - Floating`.

## STEP 3 — Page 912 buttons, validation, message
**Buttons:** DELETE button **muchhe din**. CREATE ar SAVE er Label `Save Schedule`.

**Validation 1 — `End after start`:** Type **Expression** · Language **PL/SQL** · `:P912_END_TIME > :P912_START_TIME` · Error `"To" time must be later than "From" time.` · Display `Inline with Field and in Notification` · Associated Item `P912_END_TIME` · Server-side Condition **Request is contained in Value** `CREATE,SAVE`.
(HH24:MI text er order = somoy er order, tai `>` thik.)

**Validation 2 — `No overlapping schedule`:** Type **NOT Exists (SQL query returns no rows)** · Associated Item `P912_START_TIME` · same Condition · Error `This doctor already has an active schedule that overlaps this time on the same day.`
```
SELECT 1
  FROM HMS_DOCTOR_SCHEDULE
 WHERE DOCTOR_ID    = :P912_DOCTOR_ID
   AND DAY_OF_WEEK  = :P912_DAY_OF_WEEK
   AND IS_ACTIVE    = 'Y'
   AND :P912_IS_ACTIVE = 'Y'
   AND SCHEDULE_ID <> NVL(:P912_SCHEDULE_ID, -1)
   AND START_TIME   < :P912_END_TIME
   AND END_TIME     > :P912_START_TIME
```
Overlap niyom: purono shuru < notun shesh **ebong** purono shesh > notun shuru. (09:00–13:00 ar 13:00–17:00 overlap noy.)

**Success message:** ARP `Process form Doctor Schedule` er Success Message **khali** · Condition `CREATE,SAVE`. Er pore (Close Dialog er age) Execute Code process `Success message`:
```
apex_application.g_print_success_message :=
  '<span class="fa fa-check-circle"></span> Doctor schedule saved.';
```
Close Dialog = sobar shesh.

## STEP 4 — Page 911: Weekly Schedule list (Classic Report)
`Doctor Info` ▸ Create Sub Region · Title `Weekly Schedule` · Type **Classic Report** · Static ID `doc_schedule_list` · Template Standard · Parent Region `Doctor Info` · Page Items to Submit `P911_EMPLOYEE_ID` · Pagination **No Pagination (Show All Rows)** · When No Data Found `No schedule added yet. Click "Add Schedule" to create one.`
Server-side Condition **Rows returned**: `SELECT 1 FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID AND IS_ACTIVE = 'Y'`
```
SELECT s.SCHEDULE_ID,
       INITCAP(s.DAY_OF_WEEK)                AS DAY_NAME,
       s.START_TIME || ' - ' || s.END_TIME   AS TIME_RANGE,
       s.SLOT_DURATION_MIN,
       s.MAX_SLOTS,
       s.ROOM_NO,
       CASE s.IS_ACTIVE
         WHEN 'Y' THEN '<span class="hms-badge hms-st-Y">Active</span>'
         ELSE          '<span class="hms-badge hms-st-N">Inactive</span>'
       END                                   AS STATUS_BADGE
  FROM HMS_DOCTOR_SCHEDULE s
 WHERE s.DOCTOR_ID = (SELECT d.DOCTOR_ID FROM HMS_DOCTOR d
                       WHERE d.EMPLOYEE_ID = :P911_EMPLOYEE_ID)
 ORDER BY DECODE(s.DAY_OF_WEEK,'SATURDAY',1,'SUNDAY',2,'MONDAY',3,
                 'TUESDAY',4,'WEDNESDAY',5,'THURSDAY',6,7), s.START_TIME
```
**Columns:** SCHEDULE_ID = Type **Link** · Heading (ek space) · Target Page `912` · Set Items `P912_SCHEDULE_ID`=`#SCHEDULE_ID#` ar `P912_EMPLOYEE_ID`=`&P911_EMPLOYEE_ID.` · Clear Cache `912` · Link Text `<span class="fa fa-edit" aria-label="Edit"></span>`. Headings: Day · Time · Slot (min) · Max Patients · Room · Status. **STATUS_BADGE Escape special characters = Off**.
**Button `ADD_SCHEDULE`** (region er bhitore, Position Right of Title / Create): Label `Add Schedule` · Hot · Icon `fa-plus` · Action **Redirect to Page in this Application** · Page `912` · Set Items `P912_EMPLOYEE_ID`=`&P911_EMPLOYEE_ID.` · Clear Cache `912`.
**Dynamic Action:** Name `Refresh schedule list` · Event **Dialog Closed** · jQuery Selector `body` · True: **Refresh** ▸ Region `Weekly Schedule`.

## STEP 5 — Purono Interactive Grid muche din
Test pass hole:
1. Region **Weekly Schedule** (purono IG) — Delete.
2. Processing ▸ Validations ▸ `End after start` (purono, Editable Region = Weekly Schedule) — Delete.
3. Processing ▸ Processes ▸ `Weekly Schedule - Save Interactive Grid Data` — Delete.
4. Notun list region er Title `Weekly Schedule` kora (jodi `(New)` thake).

## STEP 4B — Note (doctor save er age) — designed message
Rendering tree ▸ region **Doctor Info** ▸ right-click ▸ **Create Sub Region**:
| Property | Value |
|---|---|
| Title | `Schedule Note` |
| Type | **Static Content** |
| Appearance ▸ Template | **Blank with Attributes** |
| Server-side Condition ▸ Type | **No rows returned** |
| SQL Query | `SELECT 1 FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID AND IS_ACTIVE = 'Y'` |

**Source ▸ Text** (HTML):
```html
<div class="hms-note hms-note--info">
  <span class="fa fa-info-circle"></span>
  <div>
    <span class="hms-note-title">Save the doctor first</span>
    To add a weekly schedule, click <b>Save</b>, then open this employee again
    using the <span class="fa fa-edit"></span> <b>Edit</b> icon.
  </div>
</div>
```
(Needs `hms.css` + `hms.min.css` v7. Colors: `hms-note--info` blue · `--warn` orange · `--ok` green · `--danger` red.)


## STEP 6 — ✅ Test
1. Employees ▸ doctor ▸ pencil ▸ **Doctor Info** ▸ Weekly Schedule: "No schedule added yet...".
2. **Add Schedule** ▸ Sunday · 09:00–13:00 · Slot 15 · Max 16 · Room 101 ▸ Save ▸ modal bondho, message, list e row.
3. Abar Sunday 11:00–15:00 ▸ **overlap error**. Sunday 13:00–17:00 ▸ save hoy.
4. To < From ▸ error.
5. Edit icon ▸ Active Off ▸ Save ▸ Status **Inactive** badge.
6. `SELECT DOCTOR_ID, DAY_OF_WEEK, START_TIME, END_TIME, SLOT_DURATION_MIN FROM HMS_DOCTOR_SCHEDULE;`
7. Notun employee e Is Doctor ON, Save er age ▸ schedule er jaygay `Save the doctor first` note.

## Problem hole
| Problem | Fix |
|---|---|
| Page 912 save e ORA-01400 DOCTOR_ID | `P912_EMPLOYEE_ID` pass hoy ni — Add button/Edit link Set Items e `&P911_EMPLOYEE_ID.` (trailing dot) |
| ORA-01400 SCHEDULE_ID/CREATED_DATE | `07_default_on_null_ids.sql` v3; audit column page e rakhben na |
| ORA-02290 (DAY_OF_WEEK) | Return value UPPER (`SATURDAY`) |
| Add Schedule e Page 912 e ashe kintu purono value | Button/Link e Clear Cache `912` |
| Save er pore list refresh hoy na | Dialog Closed DA (jQuery Selector `body`) ar Refresh region nam |
| Badge e HTML text dekhay | STATUS_BADGE Escape special characters Off |
| Schedule region dekha jay na | Doctor ke Save kora lagbe (region Condition) |
