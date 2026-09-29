/*
================================================================================
 File    : database/08_master_data/01_insert_core_master.sql
 Run As  : HMS_APP
 Purpose : Branch, Department, Designation, Number series, System config, Shift
 NOTE    : ID hardcode kora hoyni (sequence start value alada hote pare) -
           sob jaygay CODE diye subquery.
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Inserting core master data ...

-- Branch --------------------------------------------------------------------
INSERT INTO HMS_BRANCH (BRANCH_CODE, BRANCH_NAME, ADDRESS_LINE1, CITY, DISTRICT, DIVISION, PHONE, EMAIL, IS_HEAD_OFFICE)
VALUES ('HQ', 'Main Hospital', 'House 1, Road 1', 'Dhaka', 'Dhaka', 'Dhaka', '+8802-0000000', 'info@hospital.com', 'Y');

-- Designation ---------------------------------------------------------------
INSERT INTO HMS_DESIGNATION (DESIGNATION_CODE, DESIGNATION_NAME, DESIGNATION_LEVEL)
SELECT 'MD', 'Managing Director', 1 FROM DUAL UNION ALL
SELECT 'DIR', 'Director', 2 FROM DUAL UNION ALL
SELECT 'PROF', 'Professor', 3 FROM DUAL UNION ALL
SELECT 'ASSO_PROF', 'Associate Professor', 4 FROM DUAL UNION ALL
SELECT 'ASST_PROF', 'Assistant Professor', 5 FROM DUAL UNION ALL
SELECT 'CONSULTANT', 'Consultant', 5 FROM DUAL UNION ALL
SELECT 'RMO', 'Resident Medical Officer', 6 FROM DUAL UNION ALL
SELECT 'MO', 'Medical Officer', 7 FROM DUAL UNION ALL
SELECT 'NURSE_SUP', 'Nursing Supervisor', 7 FROM DUAL UNION ALL
SELECT 'STAFF_NURSE', 'Staff Nurse', 8 FROM DUAL UNION ALL
SELECT 'LAB_TECH', 'Lab Technologist', 8 FROM DUAL UNION ALL
SELECT 'PHARMACIST', 'Pharmacist', 8 FROM DUAL UNION ALL
SELECT 'ACCOUNTANT', 'Accountant', 8 FROM DUAL UNION ALL
SELECT 'EXEC', 'Executive', 8 FROM DUAL UNION ALL
SELECT 'RECEPTION', 'Receptionist', 9 FROM DUAL UNION ALL
SELECT 'CASHIER', 'Cashier', 9 FROM DUAL UNION ALL
SELECT 'WARD_BOY', 'Ward Boy', 10 FROM DUAL UNION ALL
SELECT 'DRIVER', 'Driver', 10 FROM DUAL;

-- Department ----------------------------------------------------------------
INSERT INTO HMS_DEPARTMENT (BRANCH_ID, DEPT_CODE, DEPT_NAME, DEPT_TYPE)
SELECT b.BRANCH_ID, x.CODE, x.NAME, x.TYP
  FROM HMS_BRANCH b,
       (SELECT 'MED'   CODE, 'Medicine'                 NAME, 'CLINICAL'     TYP FROM DUAL UNION ALL
        SELECT 'SURG',  'General Surgery',              'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'GYN',   'Gynae & Obstetrics',           'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'PED',   'Pediatrics',                   'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'ORTHO', 'Orthopedics',                  'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'CARD',  'Cardiology',                   'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'NEURO', 'Neurology',                    'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'ENT',   'ENT',                          'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'EYE',   'Ophthalmology',                'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'DERM',  'Dermatology',                  'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'ER',    'Emergency',                    'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'ICU',   'Intensive Care Unit',          'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'ANES',  'Anesthesiology',               'CLINICAL'      FROM DUAL UNION ALL
        SELECT 'PATH',  'Pathology',                    'LAB'           FROM DUAL UNION ALL
        SELECT 'RAD',   'Radiology & Imaging',          'DIAGNOSTIC'    FROM DUAL UNION ALL
        SELECT 'PHAR',  'Pharmacy',                     'PHARMACY'      FROM DUAL UNION ALL
        SELECT 'NURS',  'Nursing',                      'SUPPORT'       FROM DUAL UNION ALL
        SELECT 'ADMIN', 'Administration',               'ADMIN'         FROM DUAL UNION ALL
        SELECT 'ACC',   'Accounts & Finance',           'ADMIN'         FROM DUAL UNION ALL
        SELECT 'HR',    'Human Resources',              'ADMIN'         FROM DUAL UNION ALL
        SELECT 'IT',    'IT',                           'ADMIN'         FROM DUAL UNION ALL
        SELECT 'STORE', 'Store & Inventory',            'SUPPORT'       FROM DUAL UNION ALL
        SELECT 'KITCH', 'Diet & Kitchen',               'SUPPORT'       FROM DUAL UNION ALL
        SELECT 'OPD',   'OPD Front Desk',               'SUPPORT'       FROM DUAL) x
 WHERE b.BRANCH_CODE = 'HQ';

-- Number series (document numbering) ----------------------------------------
INSERT INTO HMS_NUMBER_SERIES (BRANCH_ID, SERIES_TYPE, PREFIX, PAD_LENGTH, RESET_CYCLE)
SELECT b.BRANCH_ID, x.T, x.P, x.L, x.R
  FROM HMS_BRANCH b,
       (SELECT 'MRN' T,          'MRN-'  P, 7 L, 'NEVER'  R FROM DUAL UNION ALL
        SELECT 'OPD',            'OPD-',    5,   'DAILY'    FROM DUAL UNION ALL
        SELECT 'IPD',            'IPD-',    5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'ER',             'ER-',     5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'APPOINTMENT',    'APT-',    5,   'DAILY'    FROM DUAL UNION ALL
        SELECT 'BILL',           'BIL-',    6,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'RECEIPT',        'RCT-',    6,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'ADVANCE',        'ADV-',    6,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'LAB_ORDER',      'LAB-',    5,   'DAILY'    FROM DUAL UNION ALL
        SELECT 'SAMPLE',         'S',       5,   'DAILY'    FROM DUAL UNION ALL
        SELECT 'PHARMA_SALE',    'PHS-',    6,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'PHARMA_RETURN',  'PHR-',    5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'PO',             'PO-',     5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'GRN',            'GRN-',    5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'OT_BOOKING',     'OT-',     5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'BLOOD_REQ',      'BR-',     5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'INDENT',         'IND-',    5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'VOUCHER',        'JV-',     6,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'CLAIM',          'CLM-',    5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'AMB_TRIP',       'AMB-',    5,   'YEARLY'   FROM DUAL UNION ALL
        SELECT 'EMPLOYEE',       'EMP-',    5,   'NEVER'    FROM DUAL) x
 WHERE b.BRANCH_CODE = 'HQ';

-- System config ---------------------------------------------------------------
INSERT INTO HMS_SYSTEM_CONFIG (BRANCH_ID, CONFIG_KEY, CONFIG_VALUE, CONFIG_DESC)
SELECT b.BRANCH_ID, x.K, x.V, x.D
  FROM HMS_BRANCH b,
       (SELECT 'HOSPITAL_NAME' K, 'Main Hospital' V, 'Report header e dekhabe' D FROM DUAL UNION ALL
        SELECT 'CURRENCY',          'BDT',   'Currency'                         FROM DUAL UNION ALL
        SELECT 'VAT_PERCENT',       '0',     'Default VAT %'                    FROM DUAL UNION ALL
        SELECT 'MAX_DISCOUNT_PCT',  '20',    'Approval chara max discount %'    FROM DUAL UNION ALL
        SELECT 'IPD_MIN_ADVANCE',   '5000',  'IPD admission minimum advance'    FROM DUAL UNION ALL
        SELECT 'ALLOW_DISCHARGE_WITH_DUE', 'N', 'Due thakle discharge allow?'   FROM DUAL UNION ALL
        SELECT 'SMS_ENABLED',       'N',     'SMS gateway enable'               FROM DUAL) x
 WHERE b.BRANCH_CODE = 'HQ';

-- Shift -----------------------------------------------------------------------
INSERT INTO HMS_SHIFT_MASTER (BRANCH_ID, SHIFT_CODE, SHIFT_NAME, START_TIME, END_TIME)
SELECT b.BRANCH_ID, x.C, x.N, x.S, x.E
  FROM HMS_BRANCH b,
       (SELECT 'MORNING' C, 'Morning Shift' N, '08:00' S, '14:00' E FROM DUAL UNION ALL
        SELECT 'EVENING',   'Evening Shift',   '14:00',   '20:00'   FROM DUAL UNION ALL
        SELECT 'NIGHT',     'Night Shift',     '20:00',   '08:00'   FROM DUAL UNION ALL
        SELECT 'GENERAL',   'General (Office)','09:00',   '17:00'   FROM DUAL) x
 WHERE b.BRANCH_CODE = 'HQ';

-- Leave type ----------------------------------------------------------------
INSERT INTO HMS_LEAVE_TYPE (LEAVE_CODE, LEAVE_NAME, DAYS_PER_YEAR, IS_PAID, CARRY_FORWARD)
SELECT 'CL', 'Casual Leave', 10, 'Y', 'N' FROM DUAL UNION ALL
SELECT 'SL', 'Sick Leave', 14, 'Y', 'N' FROM DUAL UNION ALL
SELECT 'EL', 'Earned Leave', 18, 'Y', 'Y' FROM DUAL UNION ALL
SELECT 'ML', 'Maternity Leave', 112, 'Y', 'N' FROM DUAL UNION ALL
SELECT 'LWP', 'Leave Without Pay', NULL, 'N', 'N' FROM DUAL;

COMMIT;
