/*
================================================================================
 File    : database/08_master_data/04_insert_security_accounts.sql
 Run As  : HMS_APP   (packages compile hobar PORE run korte hobe - PKG_AUTH lage)
 Purpose : Roles, App modules (menu), Admin user, Chart of Accounts
 LOGIN   : Username = ADMIN   Password = Admin@12345   (1st login e change korun!)
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Inserting roles / modules / admin user / COA ...

INSERT INTO HMS_ROLE (ROLE_CODE, ROLE_NAME)
SELECT 'SUPER_ADMIN','Super Administrator' FROM DUAL UNION ALL
SELECT 'ADMIN','Hospital Admin' FROM DUAL UNION ALL
SELECT 'DOCTOR','Doctor' FROM DUAL UNION ALL
SELECT 'NURSE','Nurse' FROM DUAL UNION ALL
SELECT 'RECEPTION','Receptionist / Front Desk' FROM DUAL UNION ALL
SELECT 'CASHIER','Cashier / Billing' FROM DUAL UNION ALL
SELECT 'LAB','Lab Technologist' FROM DUAL UNION ALL
SELECT 'RADIOLOGY','Radiology Staff' FROM DUAL UNION ALL
SELECT 'PHARMACIST','Pharmacist' FROM DUAL UNION ALL
SELECT 'ACCOUNTS','Accounts' FROM DUAL UNION ALL
SELECT 'HR','HR Officer' FROM DUAL UNION ALL
SELECT 'STORE','Store Keeper' FROM DUAL;

INSERT INTO HMS_APP_MODULE (MODULE_CODE, MODULE_NAME, DISPLAY_ORDER, ICON_CLASS)
SELECT 'DASHBOARD','Dashboard',1,'fa-dashboard' FROM DUAL UNION ALL
SELECT 'PATIENT','Patient Registration',2,'fa-user-plus' FROM DUAL UNION ALL
SELECT 'APPOINTMENT','Appointment',3,'fa-calendar' FROM DUAL UNION ALL
SELECT 'OPD','OPD',4,'fa-stethoscope' FROM DUAL UNION ALL
SELECT 'IPD','IPD / Admission',5,'fa-bed' FROM DUAL UNION ALL
SELECT 'EMERGENCY','Emergency',6,'fa-ambulance' FROM DUAL UNION ALL
SELECT 'LAB','Laboratory',7,'fa-flask' FROM DUAL UNION ALL
SELECT 'RADIOLOGY','Radiology',8,'fa-x-ray' FROM DUAL UNION ALL
SELECT 'PHARMACY','Pharmacy',9,'fa-medkit' FROM DUAL UNION ALL
SELECT 'OT','Operation Theatre',10,'fa-scissors' FROM DUAL UNION ALL
SELECT 'BLOOD_BANK','Blood Bank',11,'fa-tint' FROM DUAL UNION ALL
SELECT 'NURSING','Nursing',12,'fa-user-md' FROM DUAL UNION ALL
SELECT 'DIET','Diet & Kitchen',13,'fa-cutlery' FROM DUAL UNION ALL
SELECT 'BILLING','Billing & Cash',14,'fa-money' FROM DUAL UNION ALL
SELECT 'ACCOUNTS','Accounts',15,'fa-book' FROM DUAL UNION ALL
SELECT 'INVENTORY','Inventory',16,'fa-cubes' FROM DUAL UNION ALL
SELECT 'HR','HR & Payroll',17,'fa-users' FROM DUAL UNION ALL
SELECT 'INSURANCE','Insurance / Corporate',18,'fa-shield' FROM DUAL UNION ALL
SELECT 'MORTUARY','Mortuary',19,'fa-archive' FROM DUAL UNION ALL
SELECT 'REPORTS','Reports',20,'fa-bar-chart' FROM DUAL UNION ALL
SELECT 'SETUP','Setup / Master',21,'fa-cog' FROM DUAL UNION ALL
SELECT 'SECURITY','User & Security',22,'fa-lock' FROM DUAL;

-- SUPER_ADMIN -> sob module full permission
INSERT INTO HMS_ROLE_PERMISSION (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_EDIT, CAN_DELETE, CAN_PRINT, CAN_APPROVE)
SELECT r.ROLE_ID, m.MODULE_ID, 'Y','Y','Y','Y','Y','Y'
  FROM HMS_ROLE r CROSS JOIN HMS_APP_MODULE m
 WHERE r.ROLE_CODE = 'SUPER_ADMIN';

-- Sample: RECEPTION role
INSERT INTO HMS_ROLE_PERMISSION (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_EDIT, CAN_PRINT)
SELECT r.ROLE_ID, m.MODULE_ID, 'Y','Y','Y','Y'
  FROM HMS_ROLE r, HMS_APP_MODULE m
 WHERE r.ROLE_CODE = 'RECEPTION'
   AND m.MODULE_CODE IN ('DASHBOARD','PATIENT','APPOINTMENT','OPD');

-- Admin user --------------------------------------------------------------------
DECLARE
    l_id NUMBER;
    l_branch NUMBER;
BEGIN
    SELECT BRANCH_ID INTO l_branch FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ';
    l_id := PKG_AUTH.create_user('ADMIN', 'Admin@12345', l_branch, NULL, 'SUPER_ADMIN');
END;
/

-- Chart of Accounts (basic) -----------------------------------------------------
INSERT INTO HMS_CHART_OF_ACCOUNTS (ACCOUNT_CODE, ACCOUNT_NAME, ACCOUNT_TYPE, ACCOUNT_LEVEL, IS_POSTING)
SELECT '1000','Assets','ASSET',1,'N' FROM DUAL UNION ALL
SELECT '2000','Liabilities','LIABILITY',1,'N' FROM DUAL UNION ALL
SELECT '3000','Equity','EQUITY',1,'N' FROM DUAL UNION ALL
SELECT '4000','Income','INCOME',1,'N' FROM DUAL UNION ALL
SELECT '5000','Expenses','EXPENSE',1,'N' FROM DUAL;

INSERT INTO HMS_CHART_OF_ACCOUNTS (ACCOUNT_CODE, ACCOUNT_NAME, ACCOUNT_TYPE, PARENT_COA_ID, ACCOUNT_LEVEL)
SELECT x.C, x.N, p.ACCOUNT_TYPE, p.COA_ID, 2
  FROM HMS_CHART_OF_ACCOUNTS p
  JOIN (SELECT '1000' P, '1101' C, 'Cash in Hand' N FROM DUAL UNION ALL
        SELECT '1000', '1102', 'Cash at Bank' FROM DUAL UNION ALL
        SELECT '1000', '1103', 'Mobile Banking (bKash/Nagad)' FROM DUAL UNION ALL
        SELECT '1000', '1201', 'Patient Receivable' FROM DUAL UNION ALL
        SELECT '1000', '1202', 'Insurance / Corporate Receivable' FROM DUAL UNION ALL
        SELECT '1000', '1301', 'Medicine Inventory' FROM DUAL UNION ALL
        SELECT '2000', '2101', 'Supplier Payable' FROM DUAL UNION ALL
        SELECT '2000', '2102', 'Patient Advance' FROM DUAL UNION ALL
        SELECT '2000', '2103', 'Doctor Payable' FROM DUAL UNION ALL
        SELECT '2000', '2104', 'VAT Payable' FROM DUAL UNION ALL
        SELECT '4000', '4101', 'OPD Consultation Income' FROM DUAL UNION ALL
        SELECT '4000', '4102', 'IPD Income' FROM DUAL UNION ALL
        SELECT '4000', '4103', 'Lab & Diagnostic Income' FROM DUAL UNION ALL
        SELECT '4000', '4104', 'Pharmacy Sales' FROM DUAL UNION ALL
        SELECT '4000', '4105', 'OT Income' FROM DUAL UNION ALL
        SELECT '5000', '5101', 'Salary & Wages' FROM DUAL UNION ALL
        SELECT '5000', '5102', 'Medicine Purchase (COGS)' FROM DUAL UNION ALL
        SELECT '5000', '5103', 'Doctor Commission' FROM DUAL UNION ALL
        SELECT '5000', '5104', 'Utility Expense' FROM DUAL UNION ALL
        SELECT '5000', '5105', 'Discount Allowed' FROM DUAL) x
    ON x.P = p.ACCOUNT_CODE;

COMMIT;
