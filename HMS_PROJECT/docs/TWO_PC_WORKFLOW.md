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
