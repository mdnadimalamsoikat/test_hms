/* Run As: HMS_APP.  Kon master data file already load hoyeche dekhay.
   Protiti file nijer shesh e COMMIT kore, error hole puro file ROLLBACK -
   tai ekta file hoy PURO load, na hoy EKDOM na. */
SET PAGES 50 LINES 150
COL FILE_NAME FORMAT A40
COL STATUS    FORMAT A45
SELECT '01_insert_core_master.sql' FILE_NAME, COUNT(*) ROWS_,
       CASE WHEN COUNT(*) > 0 THEN 'LOADED - abar chalaben NA' ELSE 'NOT LOADED - chalan' END STATUS
  FROM HMS_BRANCH
UNION ALL
SELECT '02_insert_lookup_data.sql', COUNT(*),
       CASE WHEN COUNT(*) > 0 THEN 'LOADED - abar chalaben NA' ELSE 'NOT LOADED - chalan' END
  FROM HMS_LOOKUP_MASTER
UNION ALL
SELECT '03_insert_services.sql', COUNT(*),
       CASE WHEN COUNT(*) > 0 THEN 'LOADED - abar chalaben NA' ELSE 'NOT LOADED - chalan' END
  FROM HMS_SERVICE_MASTER
UNION ALL
SELECT '04_insert_security_accounts.sql', COUNT(*),
       CASE WHEN COUNT(*) > 0 THEN 'LOADED - abar chalaben NA' ELSE 'NOT LOADED - chalan' END
  FROM HMS_ROLE;
