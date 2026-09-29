# HMS Backup & Recovery Plan (Oracle 19c, ORCL Non-CDB)

## 3 layer backup
| Layer | Tool | Kokhon | Ki bachay |
|---|---|---|---|
| 1. Physical | RMAN (L0 Shukrobar, L1 protidin) + Archivelog | Raat 11:30 auto | Puro DB, disk nosto, point-in-time |
| 2. Logical | Data Pump `expdp` HMS_APP | Raat 11:30 auto | Schema/table ferot, onno PC te newa |
| 3. App | SQLcl `apex export` | Raat 11:30 auto | APEX page/app |
| + Flashback | Flashback Query/Table/DB | Sob somoy (24h) | Bhul DELETE/UPDATE minute-e thik |

Target: **RPO ≈ 0** (archivelog), **RTO < 1 ghonta**.

## Setup (ekbar)
1. Windows e folder: `D:\HMS_BACKUP\{FRA,rman,dump,apex,logs}`
2. SYS: `@backup\01_enable_archivelog.sql` (DB 1-2 min bondho)
3. SYS: `@backup\02_setup_backup_dir.sql`
4. cmd: `rman target / @backup\rman_config.rcv`
5. `backup\config.bat` e password/path
6. Test: `backup\DAILY_BACKUP.bat` hate chalan → "DONE"
7. Admin cmd: `backup\SCHEDULE_TASKS.bat`

## Protidin/Saptahik
- Sokal: `@backup\CHECK_BACKUP_STATUS.sql` → STATUS = COMPLETED
- Robibar: validate auto (`D:\HMS_BACKUP\logs\validate.log`)
- **Mashe 1 bar**: onno PC / test DB te `RESTORE_SCHEMA.bat` diye restore kore dekhun. Test na kora backup = backup na.

## Kon somossay ki korben
| Somossa | Solution |
|---|---|
| Bhule kichu row DELETE/UPDATE | `RESTORE_ONE_TABLE.sql` (Flashback) |
| Bhule DROP TABLE | `FLASHBACK TABLE x TO BEFORE DROP` |
| Kaler kono table er data lagbe | impdp `TABLES=` + `REMAP_TABLE` |
| Puro HMS schema nosto / bhul script | `RESTORE_SCHEMA.bat hms_YYYYMMDD_HHMM.dmp` |
| Datafile/Disk nosto, DB open hoy na | `rman_restore_full.rcv` (REPAIR FAILURE / RESTORE+RECOVER) |
| PC puro nosto | Notun PC te Oracle install → offsite theke RMAN/dump → restore |

## 3-2-1 rule
3 copy, 2 alada media, 1 ta office er baire. `config.bat` e `OFFSITE` (Google Drive/USB) set korun.
**FRA (D drive) ar DB same disk e — disk nosto hole dui-i jabe.** Tai offsite copy baddhotamulok; shomvob hole RMAN backup alada disk/USB e rakhun.
