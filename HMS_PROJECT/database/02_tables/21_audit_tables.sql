/*
================================================================================
 Project   : Hospital Management System (HMS)
 Database  : Oracle 19c
 File      : 21_audit_tables.sql
 Purpose   : Tables - AUDIT & SECURITY LOG
 Run As    : HMS_APP
 Generated : 2026-09-26
================================================================================
*/
SET DEFINE OFF

PROMPT >>> Creating tables : AUDIT & SECURITY LOG

-- ----------------------------------------------------------------------------
-- HMS_AUDIT_TRAIL
-- ----------------------------------------------------------------------------
CREATE TABLE HMS_AUDIT_TRAIL (
    AUDIT_ID               NUMBER DEFAULT SEQ_AUDIT_TRAIL.NEXTVAL NOT NULL,
    TABLE_NAME             VARCHAR2(100) NOT NULL,
    RECORD_ID              NUMBER,
    ACTION_TYPE            VARCHAR2(10) NOT NULL CHECK (ACTION_TYPE IN ('INSERT','UPDATE','DELETE')),
    COLUMN_NAME            VARCHAR2(100),
    OLD_VALUE              VARCHAR2(4000),
    NEW_VALUE              VARCHAR2(4000),
    ACTION_BY              VARCHAR2(100),
    ACTION_TIME            TIMESTAMP DEFAULT SYSTIMESTAMP,
    IP_ADDRESS             VARCHAR2(50),
    MODULE_NAME            VARCHAR2(100),
    CREATED_BY             VARCHAR2(100) DEFAULT NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER),
    CREATED_DATE           TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    UPDATED_BY             VARCHAR2(100),
    UPDATED_DATE           TIMESTAMP,
    CONSTRAINT PK_AUDIT_TRAIL PRIMARY KEY (AUDIT_ID) USING INDEX TABLESPACE HMS_INDEX
)
TABLESPACE HMS_DATA;

-- ----------------------------------------------------------------------------
-- HMS_ERROR_LOG
-- ----------------------------------------------------------------------------
CREATE TABLE HMS_ERROR_LOG (
    ERROR_ID               NUMBER DEFAULT SEQ_ERROR_LOG.NEXTVAL NOT NULL,
    ERROR_CODE             NUMBER,
    ERROR_MSG              VARCHAR2(4000),
    ERROR_BACKTRACE        VARCHAR2(4000),
    PROGRAM_NAME           VARCHAR2(200),
    PARAMS                 VARCHAR2(4000),
    LOGGED_BY              VARCHAR2(100),
    LOGGED_TIME            TIMESTAMP DEFAULT SYSTIMESTAMP,
    CREATED_BY             VARCHAR2(100) DEFAULT NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER),
    CREATED_DATE           TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    UPDATED_BY             VARCHAR2(100),
    UPDATED_DATE           TIMESTAMP,
    CONSTRAINT PK_ERROR_LOG PRIMARY KEY (ERROR_ID) USING INDEX TABLESPACE HMS_INDEX
)
TABLESPACE HMS_DATA;

