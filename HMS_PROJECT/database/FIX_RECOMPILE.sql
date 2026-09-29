/* Run As: HMS_APP. Fix er pore function + package abar compile */
SET DEFINE OFF
@@04_functions/create_all_functions.sql
@@05_packages/PKG_BILLING.sql
@@05_packages/PKG_PATIENT.sql
@@05_packages/PKG_OPD.sql
@@05_packages/PKG_IPD.sql
@@05_packages/PKG_PHARMACY.sql
@@05_packages/PKG_AUTH.sql
EXEC DBMS_UTILITY.COMPILE_SCHEMA(SCHEMA => USER, COMPILE_ALL => FALSE);
PROMPT ===== INVALID objects (0 row = sob OK) =====
SELECT OBJECT_TYPE, OBJECT_NAME FROM USER_OBJECTS WHERE STATUS = 'INVALID' ORDER BY 1,2;
SELECT NAME, TYPE, LINE, POSITION, SUBSTR(TEXT,1,120) ERR FROM USER_ERRORS ORDER BY NAME, SEQUENCE;
