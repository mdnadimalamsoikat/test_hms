# Office PC ↔ Home PC: same jaygay theke kaj continue

```
OFFICE PC                         GitHub                        HOME PC
[kaj] → END_OF_DAY.bat ──push──►  script + hms_app.dmp  ──pull──► START_OF_DAY.bat → [kaj]
[kaj] ◄─ START_OF_DAY.bat ◄─pull── (porer din)  ◄──push── END_OF_DAY.bat ◄─ [kaj]
```
Ja jay: SQL script + **puro database (table + data + package)** + **APEX app**.

## Prothom bar setup (DUI PC te)
1. Project folder **same path**: `C:\HMS_PROJECT` (`git clone ... C:\HMS_PROJECT`)
2. Oracle 19c + same **APEX version** + same Oracle setup (PC bhede Non-CDB ba PDB hote pare)
3. `00_setup/01..02` run (tablespace + HMS_APP user)
4. SYS diye: `sync/00_setup_dump_dir.sql`
5. APEX e **same naam er workspace `HMS`** (schema HMS_APP)
6. `sync/config.bat` e oi PC er password / DB service (ORCL) / SQLcl path
7. Sudhu PRIMARY PC (office) te 1 bar `database/RUN_ALL.sql`. Tarpor END_OF_DAY.bat. Home e START_OF_DAY.bat.

## Protidin
| Kokhon | Ki korben |
|---|---|
| Office e kaj shesh | `sync\END_OF_DAY.bat` double-click, "DONE" dekha porjonto wait |
| Bashay kaj shuru | `sync\START_OF_DAY.bat` double-click, "READY" |
| Bashay kaj shesh | `END_OF_DAY.bat` |
| Porer din office e | `START_OF_DAY.bat` |

## ⚠ Golden rules
1. **END chara PC chere uthben na, START chara kaj shuru korben na.**
2. Ek shathe dui PC te kaj korben na. START sob kichu overwrite kore, tai onno PC er unsaved change harabe.
3. Bhule gele: je PC te notun kaj korechen, sekhane age END chalan.
4. Dump >100MB hole GitHub nibe na. Tokhon `sync\dump` folder Google Drive/OneDrive e sync korun, ar `.gitignore` e `sync/dump/` add korun.

## Alternative (sync-er jhamela nai)
- **Remote desktop:** Office PC on rekhe bashay theke AnyDesk / Chrome Remote Desktop diye connect. Ek DB, sync lage na. Internet stable lagbe.
- **Cloud DB:** Oracle Cloud Always Free (Autonomous DB + APEX free). Dui PC theke browser e same DB. Long-term best.

## Home PC te PDB (Pluggable) thakle (office = Non-CDB ORCL)
PDB problem na. Shudhu 4 ta jaygay alada:
1. **SYS connection** PDB service diye korun (SQL Developer: Service name = PDB naam, e.g. `ORCLPDB` / `XEPDB1` / `FREEPDB1`, Role = SYSDBA). Ba `ALTER SESSION SET CONTAINER = <pdb_naam>;` age run korun. Check: `SHOW CON_NAME` = PDB naam, `CDB$ROOT` na.
2. `01_create_tablespaces.sql` e `DATA_PATH` = **PDB er** datafile folder (PDB er moddhe `SELECT NAME FROM V$DATAFILE;`).
3. `02_create_user.sql`, `sync/00_setup_dump_dir.sql` — PDB er **bhitore** run (CDB$ROOT e korle ORA-65096).
4. Connection string e SID na, **PDB service**: `localhost:1521/<pdb_naam>`  (impdp, SQL Developer HMS_APP connection, `sync/config.bat` `DB_SERVICE`).
APEX 24.2 oi **PDB te install** thakte hobe: `SELECT VERSION FROM DBA_REGISTRY WHERE COMP_ID='APEX';` (PDB er bhitor theke).

---

## DB restore / PC bodoler por: object check (must)

Ek PC theke arek PC te DB niye ele kichu trigger/function/view hariye jete pare
(example: `TRG_APPOINTMENT_BI` na thakle Page 30 e `ORA-01400 ... APPOINTMENT_NO`).
Toad (HMS_APP) e chalan - ekhane sob row `VALID` / `ENABLED` hote hobe:

```
SELECT object_name, object_type, status FROM user_objects
 WHERE object_name IN ('TRG_APPOINTMENT_BI','TRG_EMPLOYEE_CODE_BI','TRG_DOCTOR_CODE_BI',
                       'TRG_BILLING_SYNC_OPD_PAY','FN_OPD_FEE','FN_OPD_IS_FOLLOWUP',
                       'VW_OPD_TOKEN_SLIP','VW_DOCTOR_QUEUE','VW_OPD_DASHBOARD')
 ORDER BY object_type, object_name;

SELECT trigger_name, status FROM user_triggers WHERE table_name = 'HMS_APPOINTMENT';
```

Kono object na thakle repo r `database/11_apex_support/` (08, 09, 10, 11 number file)
ebong `database/06_triggers/TRG_AUTO_CODES.sql` Toad e F5 (Run as Script) diye chalan - sob file re-runnable.


---

## FULL RESTORE: HMS_APP user DROP + notun create + dump import (clean slate)

`START_OF_DAY.bat` sudhu **object** muche import kore. Jodi **user shoho puro muchhe** notun kore ante chan
(user e agey theke bhul/ajana object, ba import fail hole), tahole `sync\FULL_RESTORE.bat`.

Ja kore:
1. Confirm chay (YES likhte hobe)
2. `git pull` (thakle)
3. SYS password chay -> `sync\full_reset_user.sql`: HMS_APP er session kill -> `DROP USER HMS_APP CASCADE` -> notun `CREATE USER` + grant + `HMS_DUMP_DIR`
4. `impdp` (`sync\dump\hms_app.dmp`)
5. `apex\f101.sql` import (thakle)
6. `sync\post_import_check.sql`: recompile + INVALID list + 13 ta must-have object + row count

### Ek PC (Home) theke onno PC (Office) e replace korar niyom
1. **Home PC (jekhane latest kaj):** App Builder theke app 101 export -> `C:\HMS_PROJECT\apex\f101.sql` (replace) -> `sync\END_OF_DAY.bat` (expdp + git push). Git na thakle `C:\HMS_PROJECT` folder pendrive e copy.
2. **Office PC:** `git pull` (ba pendrive theke `sync\dump\hms_app.dmp` + `apex\f101.sql` copy). `sync\config.bat` e Office er `DB_SERVICE=localhost:1521/ORCL` + `DB_PASS` thik ache kina dekhun.
3. Toad / SQL tab e HMS_APP **Disconnect**.
4. `sync\FULL_RESTORE.bat` double-click -> `YES` -> SYS password.
5. Shesh e "INVALID objects" = no rows, "13 ta must-have" sob `VALID`/`ENABLED` hote hobe.

Manual korle (Toad e): `sync\full_reset_user.sql` SYS (HMS_SYS) connection e F5 (`&1` pop-up e HMS_APP password), tarpor CMD e:
`impdp HMS_APP/<pass>@localhost:1521/ORCL SCHEMAS=HMS_APP DIRECTORY=HMS_DUMP_DIR DUMPFILE=hms_app.dmp LOGFILE=imp.log`
tarpor `sqlplus HMS_APP/<pass>@localhost:1521/ORCL @sync\post_import_check.sql`.

> Tablespace (HMS_DATA/HMS_INDEX/HMS_LOB) drop hoy na. Office e na thakle age `00_setup/01_create_tablespaces.sql`.
> Ei PC te unsaved kaj thakle FULL_RESTORE e **haray** - age END_OF_DAY.
