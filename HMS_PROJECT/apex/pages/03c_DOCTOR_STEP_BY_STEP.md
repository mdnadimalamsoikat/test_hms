# Sprint 3 — Doctor Info (Page 911 e) — Ek ek step (APEX 24.2)

**Staff na Doctor — kothay thik hoy?**
Alada "role" column nai. **Employee ke Doctor banano** = `HMS_DOCTOR` table e oi employee er ekta row thaka.
Tai Employee form e ekta **"Is Doctor?" switch** thakbe — on korle niche **Doctor Info** section ashe, Save e `HMS_DOCTOR` row toiri hoy. Off korle doctor **inactive** hoy (delete na).
Page 91 list er **Role** column (`Doctor` / `Staff`) ei row dekhe nije bole.

> Age: `TRG_AUTO_CODES.sql` run kora (DOCTOR_CODE `DR-EMP-00001` auto) ✅

## STEP 1 — Switch item (Region `Job & Bank` e)
**P911_IS_DOCTOR** — Type **Switch** · Label `Is Doctor?` · Settings ▸ On Value `Y` · Off Value `N` · Default Static `N`
· **Source ▸ Type = Null** (eta table column na) · Layout ▸ Start New Row **Yes** · Sequence: Active er **age** · Template Optional - Floating.

## STEP 2 — Region "Doctor Info"
Create Region ▸ Title `Doctor Info` · Type **Static Content** · Template **Standard** · Sequence: `Job & Bank` er pore · Advanced ▸ **Static ID `doctor_info`**.

## STEP 3 — Doctor items (region `Doctor Info` e)
Sob item: **Source ▸ Type = Null** · Template `Optional - Floating`.
1. **P911_DOCTOR_TYPE** — Select List · Label `Doctor Type` · LOV Static (Display→Return): `Full Time→FULL_TIME`, `Part Time→PART_TIME`, `Visiting→VISITING`, `Consultant→CONSULTANT`, `Resident→RESIDENT` · Display Null `- Select -` · Start New Row Yes · Span 4.
2. **P911_SPECIALIZATION** — Text Field · Label `Specialization` · Max 200 · Start New Row No · Span 4.
3. **P911_BMDC_REG_NO** — Text Field · Label `BMDC Reg No` · Start New Row No · Span 4.
4. **P911_QUALIFICATION** — Text Field · Label `Qualification` (MBBS, FCPS ...) · Max 500 · Start New Row Yes · Span 12.
5. **P911_CONSULTATION_FEE** — **Number Field** · Label `Consultation Fee (Tk)` · Min 0 · Default Static `0` · Start New Row Yes · Span 4.
6. **P911_FOLLOWUP_FEE** — Number Field · Label `Follow-up Fee (Tk)` · Min 0 · Default `0` · Span 4.
7. **P911_FOLLOWUP_VALID_DAYS** — Number Field · Label `Follow-up Valid (days)` · Min 0 · Default `7` · Span 4.

## STEP 4 — Show/Hide Dynamic Action
Dynamic Actions tab (⚡) ▸ **Events** e right-click ▸ Create Dynamic Action:
| Property | Value |
|---|---|
| Name | `Toggle Doctor Info` |
| Event | **Change** |
| Selection Type | Item(s) ▸ Item `P911_IS_DOCTOR` |
| Client-side Condition ▸ Type | **Item = Value** · Item `P911_IS_DOCTOR` · Value `Y` |
| **Fire on Initialization** | **Yes** |

True action: **Show** ▸ Affected Elements ▸ Selection Type **Region** ▸ `Doctor Info`.
**Add False action:** (right-click ▸ *Create False Action*) **Hide** ▸ Region `Doctor Info`.

## STEP 5 — Load process (edit e doctor info dekhano)
Processing / Pre-Rendering: Rendering tree ▸ **Pre-Rendering ▸ After Header** e right-click ▸ Create Process:
- Name `Load Doctor` · Type **Execute Code** · Sequence: *Initialize form Employee* er **pore**
- Server-side Condition ▸ Type **Item is NOT NULL** ▸ Item `P911_EMPLOYEE_ID`
```plsql
BEGIN
  SELECT 'Y', DOCTOR_TYPE, SPECIALIZATION, BMDC_REG_NO, QUALIFICATION,
         CONSULTATION_FEE, FOLLOWUP_FEE, FOLLOWUP_VALID_DAYS
    INTO :P911_IS_DOCTOR, :P911_DOCTOR_TYPE, :P911_SPECIALIZATION, :P911_BMDC_REG_NO,
         :P911_QUALIFICATION, :P911_CONSULTATION_FEE, :P911_FOLLOWUP_FEE, :P911_FOLLOWUP_VALID_DAYS
    FROM HMS_DOCTOR
   WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID AND IS_ACTIVE = 'Y';
EXCEPTION
  WHEN NO_DATA_FOUND THEN :P911_IS_DOCTOR := 'N';
END;
```

## STEP 6 — Save process
Processing tab ▸ **Processing** ▸ right-click ▸ Create Process:
- Name `Save Doctor` · Type **Execute Code** · Sequence: wizard er **Process form Employee** er **pore** (jemon 30)
- Server-side Condition ▸ When Button Pressed: **CREATE** o **SAVE** er jonno (duita process banate paren, ba Type *Expression* `:REQUEST IN ('CREATE','SAVE')`)
```plsql
BEGIN
  IF :P911_IS_DOCTOR = 'Y' THEN
    MERGE INTO HMS_DOCTOR d
    USING (SELECT :P911_EMPLOYEE_ID EID FROM DUAL) x
       ON (d.EMPLOYEE_ID = x.EID)
     WHEN MATCHED THEN UPDATE SET
          DOCTOR_TYPE = :P911_DOCTOR_TYPE, SPECIALIZATION = :P911_SPECIALIZATION,
          BMDC_REG_NO = :P911_BMDC_REG_NO, QUALIFICATION = :P911_QUALIFICATION,
          CONSULTATION_FEE = NVL(:P911_CONSULTATION_FEE,0),
          FOLLOWUP_FEE = NVL(:P911_FOLLOWUP_FEE,0),
          FOLLOWUP_VALID_DAYS = NVL(:P911_FOLLOWUP_VALID_DAYS,7), IS_ACTIVE = 'Y'
     WHEN NOT MATCHED THEN INSERT
          (EMPLOYEE_ID, DOCTOR_TYPE, SPECIALIZATION, BMDC_REG_NO, QUALIFICATION,
           CONSULTATION_FEE, FOLLOWUP_FEE, FOLLOWUP_VALID_DAYS)
          VALUES (:P911_EMPLOYEE_ID, :P911_DOCTOR_TYPE, :P911_SPECIALIZATION, :P911_BMDC_REG_NO,
           :P911_QUALIFICATION, NVL(:P911_CONSULTATION_FEE,0), NVL(:P911_FOLLOWUP_FEE,0),
           NVL(:P911_FOLLOWUP_VALID_DAYS,7));
  ELSE
    UPDATE HMS_DOCTOR SET IS_ACTIVE = 'N' WHERE EMPLOYEE_ID = :P911_EMPLOYEE_ID;
  END IF;
END;
```
> DOCTOR_CODE nijei `DR-EMP-0000X` hoy (trigger). Insert e likhte hobe na.
> **Create e `P911_EMPLOYEE_ID` pawar jonno:** Form region (`Employee`) ▸ Settings ▸ **Return Primary Key(s) after Insert = Yes** (24.2 te thake; na pele Page Designer search box e `Return Primary` likhun).

## STEP 7 — Validation
Validating ▸ Create Validation:
- Name `Doctor type required` · Type **Expression (PL/SQL)** · `:P911_IS_DOCTOR = 'N' OR :P911_DOCTOR_TYPE IS NOT NULL` · Error `Please select a Doctor Type.` · Associated Item `P911_DOCTOR_TYPE` · When Button CREATE, SAVE.

## STEP 8 — ✅ Test
1. Page 91 ▸ Pencil (EMP-00001) ▸ **Is Doctor?** ON ▸ **Doctor Info** section ashbe.
2. Type `Consultant` · Specialization `Medicine` · Fee `500` · Follow-up `300` ▸ **Save**.
3. Page 91 e **Role = Doctor** (nil badge). Notun doctor e `DR-EMP-00001`:
   `SELECT DOCTOR_ID, DOCTOR_CODE, EMPLOYEE_ID, SPECIALIZATION FROM HMS_DOCTOR;`
4. Abar khule Is Doctor ON + info bhora.
5. Switch off ▸ Save ▸ Role = Staff.

## Pore (03d): Doctor Schedule — Interactive Grid (Sat–Thu er shomoy, slot)

## Problem hole
| Problem | Fix |
|---|---|
| Doctor Info section hide/show hoy na | DA ▸ Fire on Initialization Yes · True=Show, False=Hide (Region `Doctor Info`) |
| ORA-01400 ...EMPLOYEE_ID in HMS_DOCTOR (Create e) | Form region ▸ *Return Primary Key(s) after Insert = Yes*; Save Doctor process ARP er **pore** |
| ORA-01400 ...DOCTOR_CODE | `06_triggers/TRG_AUTO_CODES.sql` run |
| ORA-02290 (DOCTOR_TYPE) | Return value upper case (`FULL_TIME` ...) |
| ORA-01400 ...DOCTOR_ID/CREATED_DATE | `07_default_on_null_ids.sql` |
