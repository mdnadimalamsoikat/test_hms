# 🏥 Hospital Management System (HMS): Database Setup Guide

**Oracle 19c · APEX 24.2 · Schema: `HMS_APP`**
**122 ta table · 21 ta module · 6 ta package · 130+ ta trigger · 8 ta view**

> Apnar PDF plan (136 page chat) analyze kore ei project banano hoyeche. Final decision gula follow kora hoyeche:
> **SEQUENCE + `DEFAULT seq.NEXTVAL`** (IDENTITY na), alada **Tablespace** (DATA / INDEX / LOB),
> **Git + SQL script** approach, **RUN_ALL.sql** master script, **APEX export/import**.

---

## 📁 Folder Structure

```
C:\HMS_PROJECT\
│
├── 00_setup\                      ← SYS diye run (1 bar)
│   ├── 01_create_tablespaces.sql     HMS_DATA, HMS_INDEX, HMS_LOB
│   ├── 02_create_user.sql            HMS_APP schema + privileges
│   └── 03_apex_workspace_note.sql    APEX workspace (optional)
│
├── database\                      ← HMS_APP diye run
│   ├── RUN_ALL.sql      ⭐ MASTER SCRIPT (nicher sob eksathe chalay)
│   ├── VERIFY.sql          install check
│   ├── DROP_ALL.sql        ⚠ sob delete (dev only)
│   ├── 01_sequences\       122 sequence (START WITH configurable)
│   ├── 02_tables\          21 module file + late FK
│   ├── 03_indexes\         256 FK index + search index
│   ├── 04_functions\       FN_GET_NEXT_NO, FN_CALCULATE_AGE ...
│   ├── 05_packages\        PKG_BILLING, PKG_PATIENT, PKG_OPD, PKG_IPD, PKG_PHARMACY, PKG_AUTH
│   ├── 06_triggers\        audit columns, bed status, stock, patient audit
│   ├── 07_views\           dashboard / report views
│   ├── 08_master_data\     department, services, beds, lookup, admin user
│   ├── 09_grants\
│   └── 10_test\            end-to-end test script
│
├── apex\                  ← APEX app export (f100.sql)
├── docs\TABLE_LIST.md     ← sob table er list
└── _generator\            ← table definition (python) → .sql generate
```

---

## ✅ STEP-BY-STEP: ki ki korte hobe

### STEP 0: Environment check (5 min)
SQL Developer e **SYS as SYSDBA** diye connect kore:
```sql
SELECT BANNER FROM V$VERSION;          -- 19c confirm
SELECT NAME, CDB FROM V$DATABASE;      -- ORCL, NO  (Non-CDB, PDB nai)
SELECT NAME FROM V$DATAFILE;           -- D:\APP\ORADATA\ORCL\...
SELECT NAME FROM V$DATAFILE;           -- datafile path dekhun
```

### STEP 1: Tablespace create (SYS)
1. `00_setup/01_create_tablespaces.sql` open korun
2. `DEFINE DATA_PATH = 'D:\APP\ORADATA\ORCL'` (already set)
3. **F5** (Run Script)
4. Result e 3 ta tablespace `ONLINE` dekhabe

### STEP 2: User/Schema create (SYS)
1. `00_setup/02_create_user.sql` e password change korun
2. **F5**
3. SQL Developer e **new connection** banan:
   `User: HMS_APP | Host: localhost | Port: 1521 | SID: ORCL`

### STEP 3: Sequence start value thik korun (2 PC hole)
`database/01_sequences/create_all_sequences.sql` e:
```sql
DEFINE START_VALUE = 1          -- PC-1
DEFINE START_VALUE = 1000001    -- PC-2 (test data ID clash hobe na)
```
Production e = `1`.

### STEP 4: ⭐ RUN_ALL (HMS_APP diye)
SQL Developer e **HMS_APP connection** theke:
```sql
@C:\HMS_PROJECT\database\RUN_ALL.sql
```
Ba command line e:
```bash
cd C:\HMS_PROJECT\database
sqlplus HMS_APP/password@localhost:1521/ORCL @RUN_ALL.sql
```
Ei ek command e order onujayi sob hoy:

| # | Ki hoy | Count |
|---|---|---|
| 1 | Sequences | 123 |
| 2 | Tables (module by module) | 122 |
| 3 | Indexes | ~285 |
| 4 | Functions | 9 |
| 5 | Packages | 6 |
| 6 | Triggers | 126 |
| 7 | Views | 8 |
| 8 | Master data | branch, 24 dept, 26 service, 36 bed, lookups, admin |
| 9 | Grants + recompile + VERIFY | |

Log file: `database/RUN_ALL.log`

### STEP 5: Verify
Sheshe `VERIFY.sql` auto chole. Check korun:
- **INVALID objects**: list **khali** thakte hobe
- **Compile errors**: khali thakte hobe
- Error thakle: `RUN_ALL.log` dekhun → file fix → `DROP_ALL.sql` → abar `RUN_ALL.sql`

### STEP 6: End-to-end test
```sql
@C:\HMS_PROJECT\database\10_test\01_sample_flow_test.sql
```
Expected output:
```
1. Doctor created       : ...
2. Patient registered   : MRN-0000001
3. OPD visit            : OPD-260926-00001, bill .., due 0
4. Admitted             : IPD-2026-00001, available beds now 35
5. Pharmacy stock left  : 90 (expected 90)
6. Discharged. IPD due  : 0
   Bed status now       : CLEANING (expected CLEANING)
```
(Test sheshe ROLLBACK hoy, tai kono data thakbe na.)

### STEP 7: APEX setup
1. APEX Admin → **Create Workspace** `HMS` → existing schema **HMS_APP** (ba `00_setup/03_...sql`)
2. Workspace e login → **App Builder → Create App**
3. **Authentication**: Shared Components → Authentication Schemes → Create → **Custom**
   → Function: `PKG_AUTH.AUTHENTICATE` → *Make Current*
4. Login: **ADMIN / Admin@12345** (change korun!)
5. Authorization Scheme (PL/SQL Function returning Boolean):
   ```plsql
   RETURN PKG_AUTH.has_permission(:APP_USER, 'OPD', 'VIEW');
   ```

### STEP 8: Git setup
```bash
cd C:\HMS_PROJECT
git init
git add .
git commit -m "Initial HMS database setup - 122 tables, packages, master data"
git remote add origin https://github.com/YOUR_USERNAME/HMS-Project.git
git push -u origin main
```
PC-2 te: `git clone ...` → Step 1 theke 4 (START_VALUE = 1000001).

---

## 🧩 APEX page e package use (example)

**Patient Registration page, Process (PL/SQL):**
```plsql
:P10_PATIENT_ID := PKG_PATIENT.register_patient(
    p_branch_id => :APP_BRANCH_ID, p_first_name => :P10_FIRST_NAME,
    p_last_name => :P10_LAST_NAME, p_gender => :P10_GENDER,
    p_phone => :P10_PHONE, p_dob => :P10_DOB, p_mrn => :P10_MRN);
```
**OPD visit:**
```plsql
:P20_VISIT_ID := PKG_OPD.create_visit(:APP_BRANCH_ID, :P20_PATIENT_ID, :P20_DOCTOR_ID,
                                      :P20_DEPT_ID, p_visit_no => :P20_VISIT_NO, p_bill_id => :P20_BILL_ID);
```
**LOV (dropdown):**
```sql
SELECT LOOKUP_VALUE d, LOOKUP_CODE r FROM HMS_LOOKUP_MASTER
 WHERE LOOKUP_TYPE = 'BLOOD_GROUP' AND IS_ACTIVE = 'Y' ORDER BY DISPLAY_ORDER
```
**Dashboard:** `VW_OPD_DASHBOARD`, `VW_BED_OCCUPANCY`, `VW_DAILY_REVENUE`, `VW_IPD_CURRENT_PATIENTS`,
`VW_PHARMA_STOCK_STATUS`, `VW_LAB_PENDING`, `VW_PATIENT_SUMMARY`, `VW_DOCTOR_DAILY_OPD`

---

## 📐 Design rules (sob table e same)

| Rule | Detail |
|---|---|
| Naming | Table `HMS_*`, PK `PK_*`, FK `FK_*`, Unique `UK_*`, Index `IX_*`, Seq `SEQ_*`, Trigger `TRG_*` |
| PK | `NUMBER DEFAULT SEQ_xxx.NEXTVAL`, so INSERT e ID dite hoy na |
| Audit column | `IS_ACTIVE, CREATED_BY, CREATED_DATE, UPDATED_BY, UPDATED_DATE` (APEX user auto) |
| Delete | Hard delete na, `IS_ACTIVE = 'N'` (soft delete). Bill delete trigger diye block |
| Y/N flag | `CHAR(1)` + CHECK |
| Money | `NUMBER(12,2)` / `NUMBER(14,2)` |
| Status | `VARCHAR2` + CHECK constraint (valid value fixed) |
| Doc number | `FN_GET_NEXT_NO(branch,'BILL')` → `BIL-2026-000001` (yearly/daily reset, lock-safe) |
| Storage | Table → `HMS_DATA`, Index → `HMS_INDEX`, BLOB/CLOB → `HMS_LOB` (SecureFile) |
| FK index | Sob FK column e index (lock/slow join avoid) |

## 🔗 Main business flow

```
Patient Register (MRN) ─► Appointment ─► OPD Visit (token, follow-up fee auto) ─► Bill ─► Payment
                                              │
                                              ├─► Investigation Order ─► Sample ─► Result ─► Verify
                                              ├─► Prescription ─► Pharmacy Sale (FEFO, stock auto minus)
                                              └─► Admission (bed lock → OCCUPIED, advance)
                                                     ├─► Bed transfer / Doctor visit / Nursing / Diet / OT
                                                     └─► Discharge (bed charge post → advance adjust → due check → bed CLEANING)
```

---

## 🛠 Table change korte chaile (2 option)

**Option A (simple):** Direct `.sql` file edit → `ALTER TABLE` script alada file e rakhun (e.g. `database/11_changes/2026_10_01_add_column.sql`) → Git commit.

**Option B (generator):** `_generator/tables_def.py` edit →
```bash
cd _generator
python generate.py      # 02_tables, 01_sequences, 03_indexes, audit triggers regenerate
```
Generator automatically check kore: reserved word, 30-char limit, FK order, duplicate column.
⚠ Generator chalale `02_tables`/`01_sequences`/`03_indexes`/`TRG_AUDIT_COLUMNS` overwrite hobe, tai oi file gula hate edit korben na.

## ⚠ Common error & fix

| Error | Karon | Fix |
|---|---|---|
| ORA-01950 no privileges on tablespace | Quota nai | Step 2 abar / `ALTER USER HMS_APP QUOTA UNLIMITED ON HMS_DATA` |
| ORA-00955 name already used | Age run hoyechilo | `DROP_ALL.sql` → `RUN_ALL.sql` |
| ORA-01119 / 27040 datafile | Path vul | Step 1 e `DATA_PATH` thik korun |
| PLS-00201 DBMS_CRYPTO | Grant nai | SYS: `GRANT EXECUTE ON DBMS_CRYPTO TO HMS_APP;` |
| ORA-20001 Number series not configured | Master data run hoyni | `08_master_data/01_insert_core_master.sql` |
| `&` diye prompt chay | DEFINE on | File er upore `SET DEFINE OFF` |

## 📅 Next phase (plan onujayi)
1. ✅ **Phase 1:** Tablespace + User + Sequence + Table + Index + Master data (**ei project**)
2. ✅ **Phase 2:** Views, Triggers, Core functions (**ei project**)
3. ✅ **Phase 3:** Core packages: Patient, OPD, IPD, Billing, Pharmacy, Auth (**ei project**)
4. ⏭ **Phase 4:** Baki package (PKG_LAB, PKG_OT, PKG_BLOOD_BANK, PKG_HR, PKG_ACCOUNTS auto-voucher)
5. ⏭ **Phase 5:** APEX pages (Patient → OPD → IPD → Billing → Pharmacy → Lab → Reports)
6. ⏭ **Phase 6:** Reports (bill print, prescription, discharge summary, lab report), UAT, go-live
