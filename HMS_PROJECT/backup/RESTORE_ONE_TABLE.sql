/* =====================================================================
 Ek-ta table er bhul DELETE/UPDATE thik kora (DB bondho na kore)
 Run As : HMS_APP
===================================================================== */
-- A) FLASHBACK QUERY: 30 min age data ki chilo dekha
SELECT * FROM HMS_PATIENT AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '30' MINUTE)
WHERE PATIENT_ID = 1001;

-- B) Muche jawa row ferot insert
INSERT INTO HMS_PATIENT
SELECT * FROM HMS_PATIENT AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '30' MINUTE)
WHERE PATIENT_ID = 1001
  AND PATIENT_ID NOT IN (SELECT PATIENT_ID FROM HMS_PATIENT);
COMMIT;

-- C) Puro table ke ager somoye ferot (row movement lagbe)
-- ALTER TABLE HMS_PATIENT ENABLE ROW MOVEMENT;
-- FLASHBACK TABLE HMS_PATIENT TO TIMESTAMP (SYSTIMESTAMP - INTERVAL '30' MINUTE);

-- D) Bhule DROP TABLE korle (Recycle Bin theke)
-- SELECT OBJECT_NAME, ORIGINAL_NAME, DROPTIME FROM USER_RECYCLEBIN;
-- FLASHBACK TABLE HMS_PATIENT TO BEFORE DROP;

-- E) Onek purono (undo te nai) -> dump theke shudhu oi table:
-- impdp HMS_APP/***@localhost:1521/ORCL DIRECTORY=HMS_BACKUP_DIR
--   DUMPFILE=hms_20260920_2330.dmp TABLES=HMS_PATIENT
--   REMAP_TABLE=HMS_PATIENT:HMS_PATIENT_OLD
--   (alada naam e ane, dorkari row copy kore nin)
