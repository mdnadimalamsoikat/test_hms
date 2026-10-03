# Sprint 3 — Doctor Schedule (Page 911 e Interactive Grid) — APEX 24.2

> Age: Doctor Info kaj kore ✅ (Is Doctor? ON ▸ Save). Schedule shudhu **save kora doctor** er jonno — tai Employee Save kore **abar Edit (pencil)** khule schedule din.

## Specialization / Qualification (Step 3 er sathe ekta unnoti)
- **P911_QUALIFICATION** — Text Field thik ache (MBBS, FCPS ...).
- **P911_SPECIALIZATION** — **Combobox** (type korteo parben, list theke select o) — jate "Medicine" / "medicine" / "Medcine" alada na hoy:
  Type **Combobox** · LOV Type **SQL Query**:
  ```sql
  SELECT SPEC d, SPEC r FROM (
    SELECT 'Medicine' SPEC FROM DUAL UNION SELECT 'Surgery' FROM DUAL UNION SELECT 'Gynecology & Obstetrics' FROM DUAL
    UNION SELECT 'Pediatrics' FROM DUAL UNION SELECT 'Orthopedics' FROM DUAL UNION SELECT 'Cardiology' FROM DUAL
    UNION SELECT 'Neurology' FROM DUAL UNION SELECT 'ENT' FROM DUAL UNION SELECT 'Eye (Ophthalmology)' FROM DUAL
    UNION SELECT 'Dermatology' FROM DUAL UNION SELECT 'Urology' FROM DUAL UNION SELECT 'Radiology' FROM DUAL
    UNION SELECT 'Anesthesiology' FROM DUAL UNION SELECT 'Pathology' FROM DUAL
    UNION SELECT SPECIALIZATION FROM HMS_DOCTOR WHERE SPECIALIZATION IS NOT NULL)
   ORDER BY 1
  ```
  (Notun specialization type korle porer bar list e ashe.) Combobox na pele **Text Field with Autocomplete** ba Select List.

## STEP 1 — Schedule region (Region `Doctor Info` er bhitore)
Create Region ▸ **Parent Region = Doctor Info** · Title `Weekly Schedule` · Type **Interactive Grid** · Source ▸ Type **SQL Query**:
```sql
SELECT SCHEDULE_ID, DOCTOR_ID, BRANCH_ID, DAY_OF_WEEK, START_TIME, END_TIME,
       SLOT_DURATION_MIN, MAX_SLOTS, ROOM_NO, IS_ACTIVE
  FROM HMS_DOCTOR_SCHEDULE
 WHERE DOCTOR_ID = (SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID)
```
- **Page Items to Submit** = `P911_EMPLOYEE_ID`
- Static ID `doc_schedule`
- **Server-side Condition ▸ Type = Rows returned** (ba *Exists*):
  `SELECT 1 FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID AND IS_ACTIVE = 'Y'`
- Attributes ▸ **Edit ▸ Enabled** ✅ · Allowed Operations: **Add Row** ✅ · **Update Row** ✅ · Delete Row ❌ (inactive switch use korun) · Toolbar e *Save* thakbe.

## STEP 2 — Info message (doctor save er age)
Create Region ▸ Title `Schedule` · Type **Static Content** · Parent `Doctor Info` · Text: `Schedule dite hole age doctor Save korun, tarpor abar Edit (pencil) khulun.` · **Server-side Condition ▸ Type = No rows returned**: `SELECT 1 FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID AND IS_ACTIVE='Y'`.

## STEP 3 — IG column (region `Weekly Schedule` ▸ Columns)
| Column | Setting |
|---|---|
| SCHEDULE_ID | Type **Hidden** · Source ▸ **Primary Key Yes** |
| DOCTOR_ID | Type **Hidden** · Default ▸ Type **SQL Query (return single value)** ▸ `SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID` |
| BRANCH_ID | Type **Hidden** · Default ▸ Type **Item** ▸ `G_BRANCH_ID` |
| DAY_OF_WEEK | Type **Select List** · Heading `Day` · LOV Static: `Saturday→SATURDAY, Sunday→SUNDAY, Monday→MONDAY, Tuesday→TUESDAY, Wednesday→WEDNESDAY, Thursday→THURSDAY, Friday→FRIDAY` · Value Required ✅ |
| START_TIME | Type **Select List** · Heading `From` · Value Required ✅ · LOV SQL (niche) |
| END_TIME | Type **Select List** · Heading `To` · Value Required ✅ · same LOV SQL |
| SLOT_DURATION_MIN | Type **Number Field** · Heading `Slot (min)` · Default Static `10` · Min 5 |
| MAX_SLOTS | Number Field · Heading `Max Patients` |
| ROOM_NO | Text Field · Heading `Room` |
| IS_ACTIVE | Type **Switch** · Heading `Active` · On `Y` / Off `N` · Default Static `Y` |

Time LOV SQL (START_TIME o END_TIME dutoi e — HH24:MI format, DB er sathe mile):
```sql
SELECT TO_CHAR(TRUNC(SYSDATE) + (LEVEL-1)/48, 'HH24:MI') d,
       TO_CHAR(TRUNC(SYSDATE) + (LEVEL-1)/48, 'HH24:MI') r
  FROM DUAL CONNECT BY LEVEL <= 48
```
(Display Extra Values Off · Null Display `- Time -`.) Select list howay type-er vul (`9am`, `17.30`) hobe na.

## STEP 4 — Validation (To > From)
Processing ▸ Validating ▸ Create Validation:
- Name `End after start` · **Editable Region = Weekly Schedule** · Type **Expression (PL/SQL)** · `:END_TIME > :START_TIME` · Error `"To" shomoy "From" er pore hote hobe`.

## STEP 5 — Process sequence (khub important)
Processing ▸ wizard er toiri **`Weekly Schedule - Save Interactive Grid Data`** process: **Sequence = Save Doctor er pore** (jemon 40). Sequence order:
`Process form Employee (10-20)` → `Save Doctor (30)` → `Weekly Schedule - Save IG (40)`.
Server-side Condition ▸ **Expression** `:REQUEST IN ('CREATE','SAVE')` (nijeri Save e).

## STEP 6 — ✅ Test
1. Page 91 ▸ pencil (doctor) ▸ **Doctor Info** ▸ niche **Weekly Schedule** grid.
2. **Add Row**: Saturday · 09:00 – 13:00 · Slot 10 · Max 20 · Room 101. Arekta: Monday 17:00–20:00.
3. **Save** (form er Save button) ▸ Abar khulun ▸ 2 row thakbe.
4. `SELECT DOCTOR_ID, DAY_OF_WEEK, START_TIME, END_TIME, SLOT_DURATION_MIN FROM HMS_DOCTOR_SCHEDULE;`
5. To < From dile error.
6. Notun employee e Is Doctor ON ▸ Save ▸ schedule-er jaygay message `Schedule dite hole age doctor Save korun...`

## Problem hole
| Problem | Fix |
|---|---|
| Grid e Add Row korle ORA-01400 DOCTOR_ID | Column DOCTOR_ID Default ▸ SQL Query (single value) ar Page Items to Submit `P911_EMPLOYEE_ID` |
| Grid ORA-01400 SCHEDULE_ID/CREATED_DATE | `07_default_on_null_ids.sql` |
| Grid Save hoy na | IG process Sequence `Save Doctor` er pore, Condition `:REQUEST IN ('CREATE','SAVE')` |
| ORA-02290 (DAY_OF_WEEK) | Return value UPPER (`SATURDAY`) |
| Schedule region dekha jay na | Doctor ke Save kora lagbe, region Condition tai |
