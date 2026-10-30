/*
================================================================================
 File    : database/08_master_data/06_seed_roles_modules.sql
 Run As  : HMS_APP   (Toad: Execute as Script = F5; SQL*Plus: @file)
 Purpose : 12 role + 22 module + SUPER_ADMIN/RECEPTION permission seed.
 Safe    : RE-RUNNABLE (jeta already ache seta skip kore). Ek-ta PL/SQL block,
           tai script splitting er jhamela nai (04_insert_security_accounts.sql er
           UNION ALL insert kaj na korle eta use korun).
 ADMIN user : already thakle (HMS_USER e) notun kore banay na; sudhu SUPER_ADMIN role link kore.
================================================================================
*/
SET DEFINE OFF
SET SERVEROUTPUT ON

DECLARE
    PROCEDURE add_role (p_code VARCHAR2, p_name VARCHAR2) IS
    BEGIN
        INSERT INTO HMS_ROLE (ROLE_CODE, ROLE_NAME)
        SELECT p_code, p_name FROM DUAL
         WHERE NOT EXISTS (SELECT 1 FROM HMS_ROLE WHERE ROLE_CODE = p_code);
    END;

    PROCEDURE add_mod (p_code VARCHAR2, p_name VARCHAR2, p_ord NUMBER, p_icon VARCHAR2) IS
    BEGIN
        INSERT INTO HMS_APP_MODULE (MODULE_CODE, MODULE_NAME, DISPLAY_ORDER, ICON_CLASS)
        SELECT p_code, p_name, p_ord, p_icon FROM DUAL
         WHERE NOT EXISTS (SELECT 1 FROM HMS_APP_MODULE WHERE MODULE_CODE = p_code);
    END;
BEGIN
    -- 12 role
    add_role('SUPER_ADMIN','Super Administrator');
    add_role('ADMIN','Hospital Admin');
    add_role('DOCTOR','Doctor');
    add_role('NURSE','Nurse');
    add_role('RECEPTION','Receptionist / Front Desk');
    add_role('CASHIER','Cashier / Billing');
    add_role('LAB','Lab Technologist');
    add_role('RADIOLOGY','Radiology Staff');
    add_role('PHARMACIST','Pharmacist');
    add_role('ACCOUNTS','Accounts');
    add_role('HR','HR Officer');
    add_role('STORE','Store Keeper');

    -- 22 module (menu)
    add_mod('DASHBOARD','Dashboard',1,'fa-dashboard');
    add_mod('PATIENT','Patient Registration',2,'fa-user-plus');
    add_mod('APPOINTMENT','Appointment',3,'fa-calendar');
    add_mod('OPD','OPD',4,'fa-stethoscope');
    add_mod('IPD','IPD / Admission',5,'fa-bed');
    add_mod('EMERGENCY','Emergency',6,'fa-ambulance');
    add_mod('LAB','Laboratory',7,'fa-flask');
    add_mod('RADIOLOGY','Radiology',8,'fa-x-ray');
    add_mod('PHARMACY','Pharmacy',9,'fa-medkit');
    add_mod('OT','Operation Theatre',10,'fa-scissors');
    add_mod('BLOOD_BANK','Blood Bank',11,'fa-tint');
    add_mod('NURSING','Nursing',12,'fa-user-md');
    add_mod('DIET','Diet & Kitchen',13,'fa-cutlery');
    add_mod('BILLING','Billing & Cash',14,'fa-money');
    add_mod('ACCOUNTS','Accounts',15,'fa-book');
    add_mod('INVENTORY','Inventory',16,'fa-cubes');
    add_mod('HR','HR & Payroll',17,'fa-users');
    add_mod('INSURANCE','Insurance / Corporate',18,'fa-shield');
    add_mod('MORTUARY','Mortuary',19,'fa-archive');
    add_mod('REPORTS','Reports',20,'fa-bar-chart');
    add_mod('SETUP','Setup / Master',21,'fa-cog');
    add_mod('SECURITY','User & Security',22,'fa-lock');

    -- SUPER_ADMIN: sob module e full permission
    INSERT INTO HMS_ROLE_PERMISSION (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_EDIT, CAN_DELETE, CAN_PRINT, CAN_APPROVE)
    SELECT r.ROLE_ID, m.MODULE_ID, 'Y','Y','Y','Y','Y','Y'
      FROM HMS_ROLE r CROSS JOIN HMS_APP_MODULE m
     WHERE r.ROLE_CODE = 'SUPER_ADMIN'
       AND NOT EXISTS (SELECT 1 FROM HMS_ROLE_PERMISSION p
                        WHERE p.ROLE_ID = r.ROLE_ID AND p.MODULE_ID = m.MODULE_ID);

    -- RECEPTION: sample (4 module)
    INSERT INTO HMS_ROLE_PERMISSION (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_EDIT, CAN_PRINT)
    SELECT r.ROLE_ID, m.MODULE_ID, 'Y','Y','Y','Y'
      FROM HMS_ROLE r CROSS JOIN HMS_APP_MODULE m
     WHERE r.ROLE_CODE = 'RECEPTION'
       AND m.MODULE_CODE IN ('DASHBOARD','PATIENT','APPOINTMENT','OPD')
       AND NOT EXISTS (SELECT 1 FROM HMS_ROLE_PERMISSION p
                        WHERE p.ROLE_ID = r.ROLE_ID AND p.MODULE_ID = m.MODULE_ID);

    -- ADMIN user ke SUPER_ADMIN role (jodi link na thake)
    INSERT INTO HMS_USER_ROLE (USER_ID, ROLE_ID)
    SELECT u.USER_ID, r.ROLE_ID
      FROM HMS_USER u CROSS JOIN HMS_ROLE r
     WHERE u.USERNAME = 'ADMIN' AND r.ROLE_CODE = 'SUPER_ADMIN'
       AND NOT EXISTS (SELECT 1 FROM HMS_USER_ROLE x
                        WHERE x.USER_ID = u.USER_ID AND x.ROLE_ID = r.ROLE_ID);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Roles seeded. Check: SELECT COUNT(*) FROM HMS_ROLE;  (expected 12)');
END;
/

SELECT (SELECT COUNT(*) FROM HMS_ROLE)            roles,
       (SELECT COUNT(*) FROM HMS_APP_MODULE)      modules,
       (SELECT COUNT(*) FROM HMS_ROLE_PERMISSION) permissions,
       (SELECT COUNT(*) FROM HMS_USER_ROLE)       user_roles
  FROM DUAL;
