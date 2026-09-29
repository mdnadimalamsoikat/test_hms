/* =====================================================================
 File   : backup/01_enable_archivelog.sql
 Run As : SYS AS SYSDBA  (ORCL Non-CDB)   -- EKBAR-i chalate hobe
 Keno   : ARCHIVELOG mode chara RMAN "point-in-time" recovery (jemon
          aj 2:35 PM er obosthay ferot) somvob na. DB 1-2 min bondho thakbe.
===================================================================== */
ARCHIVE LOG LIST
-- "Database log mode: No Archive Mode" dekhale niche cholun

-- Archive log + Fast Recovery Area (D drive e jayga rakhun, min 20G)
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 30G SCOPE=BOTH;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST = 'D:\HMS_BACKUP\FRA' SCOPE=BOTH;
-- (Age D:\HMS_BACKUP\FRA folder ta Windows e baniye nin)

SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Flashback (bhul DELETE/UPDATE hole minute-e ferot) - optional kintu valo
ALTER SYSTEM SET DB_FLASHBACK_RETENTION_TARGET = 1440 SCOPE=BOTH;  -- 24 ghonta
ALTER DATABASE FLASHBACK ON;

ARCHIVE LOG LIST
SELECT LOG_MODE, FLASHBACK_ON FROM V$DATABASE;   -- ARCHIVELOG , YES
