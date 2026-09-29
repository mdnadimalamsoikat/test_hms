/*
================================================================================
 File    : database/08_master_data/03_insert_services.sql
 Run As  : HMS_APP
 Purpose : Service category, sample services + lab parameters, ward/bed, OT, store
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Inserting services / wards / stores ...

-- Service category ----------------------------------------------------------
INSERT INTO HMS_SERVICE_CATEGORY (CATEGORY_CODE, CATEGORY_NAME, CATEGORY_TYPE, DISPLAY_ORDER)
SELECT 'CONS', 'Consultation',   'CONSULTATION', 1 FROM DUAL UNION ALL
SELECT 'HEMA', 'Hematology',     'LAB',          2 FROM DUAL UNION ALL
SELECT 'BIOC', 'Biochemistry',   'LAB',          3 FROM DUAL UNION ALL
SELECT 'MICRO','Microbiology',   'LAB',          4 FROM DUAL UNION ALL
SELECT 'SERO', 'Serology / Immunology', 'LAB',   5 FROM DUAL UNION ALL
SELECT 'XRAY', 'X-Ray',          'RADIOLOGY',    6 FROM DUAL UNION ALL
SELECT 'USG',  'Ultrasonography','RADIOLOGY',    7 FROM DUAL UNION ALL
SELECT 'CT',   'CT Scan',        'RADIOLOGY',    8 FROM DUAL UNION ALL
SELECT 'CARDIO','Cardiac Test (ECG/Echo)','RADIOLOGY', 9 FROM DUAL UNION ALL
SELECT 'PROC', 'Procedure',      'PROCEDURE',   10 FROM DUAL UNION ALL
SELECT 'BED',  'Bed / Room Charge','BED',       11 FROM DUAL UNION ALL
SELECT 'OT',   'OT Charges',     'OT',          12 FROM DUAL UNION ALL
SELECT 'NURS', 'Nursing Service','NURSING',     13 FROM DUAL UNION ALL
SELECT 'MISC', 'Miscellaneous',  'MISC',        14 FROM DUAL;

-- Services ------------------------------------------------------------------
INSERT INTO HMS_SERVICE_MASTER (CATEGORY_ID, SERVICE_CODE, SERVICE_NAME, BASE_CHARGE, SAMPLE_REQUIRED, SAMPLE_TYPE, REPORTING_SECTION, TURN_AROUND_TIME)
SELECT c.CATEGORY_ID, x.CODE, x.NAME, x.RATE, x.SR, x.ST, x.SEC, x.TAT
  FROM HMS_SERVICE_CATEGORY c
  JOIN (SELECT 'CONS' CAT, 'CONS-OPD' CODE, 'OPD Consultation' NAME, 0 RATE, 'N' SR, NULL ST, NULL SEC, NULL TAT FROM DUAL UNION ALL
        SELECT 'CONS', 'CONS-IPD',  'IPD Doctor Visit',            1000, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'HEMA', 'CBC',       'Complete Blood Count (CBC)',   400, 'Y', 'Blood', 'Hematology',   '4 Hours' FROM DUAL UNION ALL
        SELECT 'HEMA', 'ESR',       'ESR',                          150, 'Y', 'Blood', 'Hematology',   '2 Hours' FROM DUAL UNION ALL
        SELECT 'HEMA', 'BGRP',      'Blood Grouping & Rh',          200, 'Y', 'Blood', 'Hematology',   '1 Hour'  FROM DUAL UNION ALL
        SELECT 'BIOC', 'RBS',       'Random Blood Sugar',           150, 'Y', 'Blood', 'Biochemistry', '1 Hour'  FROM DUAL UNION ALL
        SELECT 'BIOC', 'FBS',       'Fasting Blood Sugar',          150, 'Y', 'Blood', 'Biochemistry', '1 Hour'  FROM DUAL UNION ALL
        SELECT 'BIOC', 'SCR',       'Serum Creatinine',             400, 'Y', 'Blood', 'Biochemistry', '4 Hours' FROM DUAL UNION ALL
        SELECT 'BIOC', 'LIPID',     'Lipid Profile',               1200, 'Y', 'Blood', 'Biochemistry', '6 Hours' FROM DUAL UNION ALL
        SELECT 'BIOC', 'SGPT',      'SGPT (ALT)',                   400, 'Y', 'Blood', 'Biochemistry', '4 Hours' FROM DUAL UNION ALL
        SELECT 'MICRO','URINE_RE',  'Urine R/E',                    250, 'Y', 'Urine', 'Clinical Path','2 Hours' FROM DUAL UNION ALL
        SELECT 'SERO', 'NS1',       'Dengue NS1 Antigen',           500, 'Y', 'Blood', 'Serology',     '2 Hours' FROM DUAL UNION ALL
        SELECT 'SERO', 'HBSAG',     'HBsAg',                        500, 'Y', 'Blood', 'Serology',     '2 Hours' FROM DUAL UNION ALL
        SELECT 'XRAY', 'XR-CHEST',  'X-Ray Chest P/A View',         600, 'N', NULL,    'X-Ray',        '1 Hour'  FROM DUAL UNION ALL
        SELECT 'USG',  'USG-WA',    'USG of Whole Abdomen',        2000, 'N', NULL,    'USG',          '2 Hours' FROM DUAL UNION ALL
        SELECT 'CT',   'CT-BRAIN',  'CT Scan of Brain',            5000, 'N', NULL,    'CT',           '4 Hours' FROM DUAL UNION ALL
        SELECT 'CARDIO','ECG',      'ECG (12 Lead)',                400, 'N', NULL,    'Cardiology',   '30 Min'  FROM DUAL UNION ALL
        SELECT 'CARDIO','ECHO',     'Echocardiography',            3000, 'N', NULL,    'Cardiology',   '2 Hours' FROM DUAL UNION ALL
        SELECT 'PROC', 'DRESSING',  'Dressing (Small)',             300, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'PROC', 'NEBULIZE',  'Nebulization',                 200, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'BED',  'BED-GEN',   'General Ward Bed (per day)',  1000, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'BED',  'BED-CABIN', 'AC Cabin (per day)',          4000, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'BED',  'BED-ICU',   'ICU Bed (per day)',          12000, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'NURS', 'NURS-DAY',  'Nursing Charge (per day)',     500, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'MISC', 'ADM-FEE',   'Admission Fee',                500, 'N', NULL,    NULL,           NULL      FROM DUAL UNION ALL
        SELECT 'MISC', 'REG-FEE',   'Registration Fee',             100, 'N', NULL,    NULL,           NULL      FROM DUAL) x
    ON x.CAT = c.CATEGORY_CODE;

-- Lab parameters (CBC example) -------------------------------------------------
INSERT INTO HMS_LAB_PARAMETER (SERVICE_ID, PARAMETER_CODE, PARAMETER_NAME, UNIT, RESULT_TYPE, DISPLAY_ORDER)
SELECT s.SERVICE_ID, x.C, x.N, x.U, 'NUMERIC', x.O
  FROM HMS_SERVICE_MASTER s
  JOIN (SELECT 'CBC' SVC, 'HB' C, 'Hemoglobin' N, 'g/dL' U, 1 O FROM DUAL UNION ALL
        SELECT 'CBC', 'WBC', 'Total WBC Count', '/cmm', 2 FROM DUAL UNION ALL
        SELECT 'CBC', 'NEUT', 'Neutrophils', '%', 3 FROM DUAL UNION ALL
        SELECT 'CBC', 'LYMPH', 'Lymphocytes', '%', 4 FROM DUAL UNION ALL
        SELECT 'CBC', 'PLT', 'Platelet Count', '/cmm', 5 FROM DUAL UNION ALL
        SELECT 'CBC', 'RBC', 'RBC Count', 'million/cmm', 6 FROM DUAL UNION ALL
        SELECT 'RBS', 'RBS', 'Random Blood Sugar', 'mmol/L', 1 FROM DUAL UNION ALL
        SELECT 'FBS', 'FBS', 'Fasting Blood Sugar', 'mmol/L', 1 FROM DUAL UNION ALL
        SELECT 'SCR', 'CREAT', 'Serum Creatinine', 'mg/dL', 1 FROM DUAL) x
    ON x.SVC = s.SERVICE_CODE;

INSERT INTO HMS_LAB_REFERENCE_RANGE (PARAMETER_ID, GENDER, MIN_VALUE, MAX_VALUE, CRITICAL_LOW, CRITICAL_HIGH)
SELECT p.PARAMETER_ID, x.G, x.MN, x.MX, x.CL, x.CH
  FROM HMS_LAB_PARAMETER p
  JOIN (SELECT 'HB' C, 'MALE' G, 13.0 MN, 17.0 MX, 7 CL, 20 CH FROM DUAL UNION ALL
        SELECT 'HB', 'FEMALE', 12.0, 15.5, 7, 20 FROM DUAL UNION ALL
        SELECT 'WBC', 'ALL', 4000, 11000, 2000, 30000 FROM DUAL UNION ALL
        SELECT 'NEUT', 'ALL', 40, 75, NULL, NULL FROM DUAL UNION ALL
        SELECT 'LYMPH', 'ALL', 20, 45, NULL, NULL FROM DUAL UNION ALL
        SELECT 'PLT', 'ALL', 150000, 450000, 20000, 1000000 FROM DUAL UNION ALL
        SELECT 'RBS', 'ALL', 3.9, 7.8, 2.5, 25 FROM DUAL UNION ALL
        SELECT 'FBS', 'ALL', 3.9, 6.1, 2.5, 25 FROM DUAL UNION ALL
        SELECT 'CREAT', 'MALE', 0.7, 1.3, NULL, 5 FROM DUAL UNION ALL
        SELECT 'CREAT', 'FEMALE', 0.6, 1.1, NULL, 5 FROM DUAL) x
    ON x.C = p.PARAMETER_CODE;

-- Ward & Bed ------------------------------------------------------------------
INSERT INTO HMS_WARD (BRANCH_ID, WARD_CODE, WARD_NAME, WARD_TYPE, FLOOR_NO, TOTAL_BEDS, GENDER_ALLOWED)
SELECT b.BRANCH_ID, x.C, x.N, x.T, x.F, x.B, x.G
  FROM HMS_BRANCH b,
       (SELECT 'GW-M' C, 'General Ward (Male)' N, 'GENERAL' T, '3' F, 10 B, 'MALE' G FROM DUAL UNION ALL
        SELECT 'GW-F', 'General Ward (Female)', 'GENERAL', '3', 10, 'FEMALE' FROM DUAL UNION ALL
        SELECT 'CAB',  'Cabin Block',           'CABIN',   '4', 10, 'ALL'    FROM DUAL UNION ALL
        SELECT 'ICU',  'ICU',                   'ICU',     '5',  6, 'ALL'    FROM DUAL) x
 WHERE b.BRANCH_CODE = 'HQ';

-- Beds: ward onujayi auto create (GW-M-01 ... )
INSERT INTO HMS_BED (WARD_ID, BED_NO, BED_TYPE, SERVICE_ID, DAILY_CHARGE)
SELECT w.WARD_ID,
       w.WARD_CODE || '-' || LPAD(n.N, 2, '0'),
       CASE w.WARD_TYPE WHEN 'CABIN' THEN 'CABIN_AC' WHEN 'ICU' THEN 'ICU' ELSE 'GENERAL' END,
       s.SERVICE_ID,
       s.BASE_CHARGE
  FROM HMS_WARD w
  JOIN (SELECT LEVEL N FROM DUAL CONNECT BY LEVEL <= 20) n ON n.N <= w.TOTAL_BEDS
  JOIN HMS_SERVICE_MASTER s
    ON s.SERVICE_CODE = CASE w.WARD_TYPE WHEN 'CABIN' THEN 'BED-CABIN' WHEN 'ICU' THEN 'BED-ICU' ELSE 'BED-GEN' END;

-- OT --------------------------------------------------------------------------
INSERT INTO HMS_OT_MASTER (BRANCH_ID, OT_CODE, OT_NAME, OT_TYPE, FLOOR_NO)
SELECT BRANCH_ID, 'OT-1', 'Major OT 1', 'MAJOR', '6' FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ' UNION ALL
SELECT BRANCH_ID, 'OT-2', 'Minor OT',   'MINOR', '6' FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ';

-- Pharmacy store ----------------------------------------------------------------
INSERT INTO HMS_PHARMA_STORE (BRANCH_ID, STORE_CODE, STORE_NAME, STORE_TYPE)
SELECT BRANCH_ID, 'PH-MAIN', 'Main Medicine Store', 'MAIN' FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ' UNION ALL
SELECT BRANCH_ID, 'PH-OPD',  'OPD Pharmacy',        'OPD'  FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ' UNION ALL
SELECT BRANCH_ID, 'PH-IPD',  'IPD Pharmacy',        'IPD'  FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ';

INSERT INTO HMS_INV_STORE (BRANCH_ID, STORE_CODE, STORE_NAME)
SELECT BRANCH_ID, 'GEN-STORE', 'General Store' FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ';

COMMIT;
