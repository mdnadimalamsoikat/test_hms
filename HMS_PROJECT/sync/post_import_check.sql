/* post_import_check.sql - HMS_APP diye chalan (FULL_RESTORE.bat shesh e call kore) */
SET PAGESIZE 100 LINESIZE 160 FEEDBACK OFF SERVEROUTPUT ON

PROMPT >>> Recompile all objects
EXEC DBMS_UTILITY.COMPILE_SCHEMA('HMS_APP', FALSE);

PROMPT >>> INVALID objects  (kichu asle seta pathan; "no rows selected" = bhalo)
SELECT object_type, object_name FROM user_objects WHERE status = 'INVALID';

PROMPT >>> Must-have objects (13 ta, sob VALID / ENABLED hote hobe)
SELECT o.object_name, o.object_type, o.status
  FROM user_objects o
 WHERE o.object_name IN ('TRG_APPOINTMENT_BI','TRG_EMPLOYEE_CODE_BI','TRG_DOCTOR_CODE_BI',
                         'TRG_BILLING_SYNC_OPD_PAY','FN_OPD_FEE','FN_OPD_IS_FOLLOWUP',
                         'PR_SAVE_OPD_VITALS','PR_SAVE_OPD_CONSULTATION',
                         'VW_OPD_TOKEN_SLIP','VW_DOCTOR_QUEUE','VW_OPD_DASHBOARD',
                         'PKG_OPD','PKG_BILLING')
 ORDER BY o.object_type, o.object_name;

PROMPT >>> Trigger status (HMS_APPOINTMENT)
SELECT trigger_name, status FROM user_triggers WHERE table_name = 'HMS_APPOINTMENT';

PROMPT >>> Row counts
SELECT 'HMS_PATIENT'     AS tbl, COUNT(*) AS cnt FROM hms_patient     UNION ALL
SELECT 'HMS_DOCTOR'      , COUNT(*) FROM hms_doctor      UNION ALL
SELECT 'HMS_OPD_VISIT'   , COUNT(*) FROM hms_opd_visit   UNION ALL
SELECT 'HMS_USER'        , COUNT(*) FROM hms_user        UNION ALL
SELECT 'HMS_ROLE'        , COUNT(*) FROM hms_role        UNION ALL
SELECT 'HMS_NUMBER_SERIES', COUNT(*) FROM hms_number_series;
EXIT
