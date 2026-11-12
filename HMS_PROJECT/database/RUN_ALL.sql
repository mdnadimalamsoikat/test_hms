/*
================================================================================
 Project : Hospital Management System (HMS) - Oracle 19c
 File    : database/RUN_ALL.sql      <<< MASTER SCRIPT >>>
 Run As  : HMS_APP
 How     : SQL Developer:  @C:\HMS_PROJECT\database\RUN_ALL.sql   (F5 = Run Script)
           SQL*Plus     :  cd C:\HMS_PROJECT\database
                           sqlplus HMS_APP/password@localhost:1521/ORCL @RUN_ALL.sql
 Before  : 00_setup/01_create_tablespaces.sql + 02_create_user.sql (SYS diye) run kora thakte hobe
 Rerun   : age DROP_ALL.sql run korun
================================================================================
*/
SET ECHO OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON
SET DEFINE ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SPOOL RUN_ALL.log

PROMPT ============================================================
PROMPT  HMS Database Setup Starting ...
PROMPT ============================================================

PROMPT [STEP 1/9] Sequences
@@01_sequences/create_all_sequences.sql

PROMPT [STEP 2/9] Tables (module by module)
@@02_tables/01_core_tables.sql
@@02_tables/02_security_tables.sql
@@02_tables/03_patient_tables.sql
@@02_tables/04_service_tables.sql
@@02_tables/05_appointment_tables.sql
@@02_tables/06_opd_tables.sql
@@02_tables/07_ipd_tables.sql
@@02_tables/08_lab_tables.sql
@@02_tables/09_radiology_tables.sql
@@02_tables/10_pharmacy_tables.sql
@@02_tables/11_ot_tables.sql
@@02_tables/12_blood_bank_tables.sql
@@02_tables/13_nursing_tables.sql
@@02_tables/14_diet_tables.sql
@@02_tables/15_insurance_tables.sql
@@02_tables/16_billing_accounts_tables.sql
@@02_tables/17_inventory_tables.sql
@@02_tables/18_hr_tables.sql
@@02_tables/19_emergency_tables.sql
@@02_tables/20_mortuary_tables.sql
@@02_tables/21_audit_tables.sql
@@02_tables/99_late_foreign_keys.sql

PROMPT [STEP 3/9] Indexes
@@03_indexes/create_all_indexes.sql

-- PL/SQL compile error e script thambe na; sheshe invalid list dekhano hobe
WHENEVER SQLERROR CONTINUE

PROMPT [STEP 4/9] Functions
@@04_functions/create_all_functions.sql

PROMPT [STEP 5/9] Packages (order important)
@@05_packages/PKG_BILLING.sql
@@05_packages/PKG_PATIENT.sql
@@05_packages/PKG_OPD.sql
@@05_packages/PKG_IPD.sql
@@05_packages/PKG_PHARMACY.sql
@@05_packages/PKG_AUTH.sql

PROMPT [STEP 6/9] Triggers
@@06_triggers/TRG_AUDIT_COLUMNS.sql
@@06_triggers/TRG_ADMISSION_BED_STATUS.sql
@@06_triggers/TRG_PHARMA_SALE_STOCK.sql
@@06_triggers/TRG_AUDIT_PATIENT.sql
@@06_triggers/TRG_BILLING_CANCEL_CHECK.sql
@@06_triggers/TRG_AUTO_CODES.sql

PROMPT [STEP 7/9] Views
@@07_views/create_all_views.sql

PROMPT [STEP 8/9] Master data
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
@@08_master_data/01_insert_core_master.sql
@@08_master_data/02_insert_lookup_data.sql
@@08_master_data/03_insert_services.sql
@@08_master_data/04_insert_security_accounts.sql
WHENEVER SQLERROR CONTINUE

PROMPT [STEP 9/9] Grants + recompile
@@09_grants/grant_permissions.sql
EXEC DBMS_UTILITY.COMPILE_SCHEMA(SCHEMA => USER, COMPILE_ALL => FALSE);

@@VERIFY.sql

PROMPT ============================================================
PROMPT  HMS Database Setup COMPLETE. Log: RUN_ALL.log
PROMPT  APEX login: ADMIN / Admin@12345  (change korun!)
PROMPT ============================================================
SPOOL OFF
