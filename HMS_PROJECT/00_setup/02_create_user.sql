/*
================================================================================
 File    : 00_setup/02_create_user.sql
 Run As  : SYS AS SYSDBA  (ORCL Non-CDB)
 Purpose : HMS_APP schema (sob table/package ei schema te thakbe)
================================================================================
 Password ta change kore nin!
*/
PROMPT >>> Creating schema HMS_APP
CREATE USER HMS_APP IDENTIFIED BY "Hms#Strong2026"
  DEFAULT TABLESPACE HMS_DATA
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON HMS_DATA
  QUOTA UNLIMITED ON HMS_INDEX
  QUOTA UNLIMITED ON HMS_LOB;

PROMPT >>> Granting system privileges
GRANT CREATE SESSION        TO HMS_APP;
GRANT CREATE TABLE          TO HMS_APP;
GRANT CREATE VIEW           TO HMS_APP;
GRANT CREATE MATERIALIZED VIEW TO HMS_APP;
GRANT CREATE SEQUENCE       TO HMS_APP;
GRANT CREATE PROCEDURE      TO HMS_APP;
GRANT CREATE TRIGGER        TO HMS_APP;
GRANT CREATE TYPE           TO HMS_APP;
GRANT CREATE SYNONYM        TO HMS_APP;
GRANT CREATE JOB            TO HMS_APP;
GRANT CREATE ROLE           TO HMS_APP;
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO HMS_APP;   -- password hash
GRANT EXECUTE ON SYS.DBMS_LOCK   TO HMS_APP;

-- Report user (read only) - optional
CREATE ROLE HMS_READONLY_ROLE;
CREATE ROLE HMS_APP_USER_ROLE;

SELECT USERNAME, ACCOUNT_STATUS, DEFAULT_TABLESPACE FROM DBA_USERS WHERE USERNAME = 'HMS_APP';
