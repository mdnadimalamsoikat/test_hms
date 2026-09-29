/*
================================================================================
 Project : Hospital Management System (HMS) - Oracle 19c
 File    : 00_setup/01_create_tablespaces.sql
 Run As  : SYS AS SYSDBA  (ORCL = Non-CDB, PDB nai)
 Purpose : Data, Index, LOB tablespace alada rakha (better I/O + backup)
================================================================================
 AGE CHECK KORUN (datafile path ki):
   SELECT NAME FROM V$DATAFILE;
 Tarpor niche DATA_PATH apnar path onujayi change korun.
 Apnar DB: ORCL, CDB = NO, datafile folder = D:\APP\ORADATA\ORCL
*/
SET DEFINE ON
DEFINE DATA_PATH = 'D:\APP\ORADATA\ORCL'

PROMPT >>> Creating tablespace HMS_DATA (tables)
CREATE TABLESPACE HMS_DATA
  DATAFILE '&DATA_PATH\HMS_DATA01.DBF' SIZE 500M
  AUTOEXTEND ON NEXT 100M MAXSIZE 10G
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

PROMPT >>> Creating tablespace HMS_INDEX (indexes)
CREATE TABLESPACE HMS_INDEX
  DATAFILE '&DATA_PATH\HMS_INDEX01.DBF' SIZE 200M
  AUTOEXTEND ON NEXT 50M MAXSIZE 5G
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

PROMPT >>> Creating tablespace HMS_LOB (photo, document, image)
CREATE TABLESPACE HMS_LOB
  DATAFILE '&DATA_PATH\HMS_LOB01.DBF' SIZE 200M
  AUTOEXTEND ON NEXT 100M MAXSIZE 20G
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

-- Verify
SELECT TABLESPACE_NAME, STATUS FROM DBA_TABLESPACES WHERE TABLESPACE_NAME LIKE 'HMS%';
SET DEFINE OFF
