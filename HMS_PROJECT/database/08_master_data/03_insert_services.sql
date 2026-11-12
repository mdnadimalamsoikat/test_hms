/*
================================================================================
 File    : database/08_master_data/03_insert_services.sql
 Run As  : HMS_APP
 Purpose : Service category, sample services + lab parameters, ward/bed, OT, store
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Inserting services / wards / stores ...

-- Re-runnable: har insert e NOT EXISTS ache, tai script ek-er-beshi bar chalale duplicate error hobe na.
-- Run kora hoy SQL Workshop > SQL Scripts (SQL Commands na) — error hole kon statement ta dekha jay.

-- 1) Service category -------------------------------------------------------
INSERT INTO HMS_SERVICE_CATEGORY (CATEGORY_CODE, CATEGORY_NAME, CATEGORY_TYPE, DISPLAY_ORDER)
SELECT v.V_CODE, v.V_NAME, v.V_TYPE, v.V_ORDER
  FROM (SELECT 'CONS' V_CODE, 'Consultation' V_NAME, 'CONSULTATION' V_TYPE, 1 V_ORDER FROM DUAL UNION ALL
        SELECT 'HEMA',  'Hematology',               'LAB',        2 FROM DUAL UNION ALL
        SELECT 'BIOC',  'Biochemistry',             'LAB',        3 FROM DUAL UNION ALL
        SELECT 'MICRO', 'Microbiology',             'LAB',        4 FROM DUAL UNION ALL
        SELECT 'SERO',  'Serology / Immunology',    'LAB',        5 FROM DUAL UNION ALL
        SELECT 'XRAY',  'X-Ray',                    'RADIOLOGY',  6 FROM DUAL UNION ALL
        SELECT 'USG',   'Ultrasonography',          'RADIOLOGY',  7 FROM DUAL UNION ALL
        SELECT 'CT',    'CT Scan',                  'RADIOLOGY',  8 FROM DUAL UNION ALL
        SELECT 'CARDIO','Cardiac Test (ECG/Echo)',  'RADIOLOGY',  9 FROM DUAL UNION ALL
        SELECT 'PROC',  'Procedure',                'PROCEDURE', 10 FROM DUAL UNION ALL
        SELECT 'BED',   'Bed / Room Charge',        'BED',       11 FROM DUAL UNION ALL
        SELECT 'OT',    'OT Charges',               'OT',        12 FROM DUAL UNION ALL
        SELECT 'NURS',  'Nursing Service',          'NURSING',   13 FROM DUAL UNION ALL
        SELECT 'MISC',  'Miscellaneous',            'MISC',      14 FROM DUAL) v
 WHERE NOT EXISTS (SELECT 1 FROM HMS_SERVICE_CATEGORY t WHERE t.CATEGORY_CODE = v.V_CODE);

-- 2) Services ---------------------------------------------------------------
INSERT INTO HMS_SERVICE_MASTER (CATEGORY_ID, SERVICE_CODE, SERVICE_NAME, BASE_CHARGE, SAMPLE_REQUIRED, SAMPLE_TYPE, REPORTING_SECTION, TURN_AROUND_TIME)
SELECT c.CATEGORY_ID, v.V_CODE, v.V_NAME, v.V_RATE, v.V_SAMPLE_REQ, v.V_SAMPLE_TYPE, v.V_SECTION, v.V_TAT
  FROM HMS_SERVICE_CATEGORY c
  JOIN (SELECT 'CONS' V_CAT, 'CONS-OPD' V_CODE, 'OPD Consultation' V_NAME, 0 V_RATE, 'N' V_SAMPLE_REQ, CAST(NULL AS VARCHAR2(30)) V_SAMPLE_TYPE, CAST(NULL AS VARCHAR2(50)) V_SECTION, CAST(NULL AS VARCHAR2(30)) V_TAT FROM DUAL UNION ALL
        SELECT 'CONS', 'CONS-IPD',  'IPD Doctor Visit',            1000, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'HEMA', 'CBC',       'Complete Blood Count (CBC)',   400, 'Y', 'Blood', 'Hematology',    '4 Hours' FROM DUAL UNION ALL
        SELECT 'HEMA', 'ESR',       'ESR',                          150, 'Y', 'Blood', 'Hematology',    '2 Hours' FROM DUAL UNION ALL
        SELECT 'HEMA', 'BGRP',      'Blood Grouping and Rh',          200, 'Y', 'Blood', 'Hematology',    '1 Hour'  FROM DUAL UNION ALL
        SELECT 'BIOC', 'RBS',       'Random Blood Sugar',           150, 'Y', 'Blood', 'Biochemistry',  '1 Hour'  FROM DUAL UNION ALL
        SELECT 'BIOC', 'FBS',       'Fasting Blood Sugar',          150, 'Y', 'Blood', 'Biochemistry',  '1 Hour'  FROM DUAL UNION ALL
        SELECT 'BIOC', 'SCR',       'Serum Creatinine',             400, 'Y', 'Blood', 'Biochemistry',  '4 Hours' FROM DUAL UNION ALL
        SELECT 'BIOC', 'LIPID',     'Lipid Profile',               1200, 'Y', 'Blood', 'Biochemistry',  '6 Hours' FROM DUAL UNION ALL
        SELECT 'BIOC', 'SGPT',      'SGPT (ALT)',                   400, 'Y', 'Blood', 'Biochemistry',  '4 Hours' FROM DUAL UNION ALL
        SELECT 'MICRO','URINE_RE',  'Urine R/E',                    250, 'Y', 'Urine', 'Clinical Path', '2 Hours' FROM DUAL UNION ALL
        SELECT 'SERO', 'NS1',       'Dengue NS1 Antigen',           500, 'Y', 'Blood', 'Serology',      '2 Hours' FROM DUAL UNION ALL
        SELECT 'SERO', 'HBSAG',     'HBsAg',                        500, 'Y', 'Blood', 'Serology',      '2 Hours' FROM DUAL UNION ALL
        SELECT 'XRAY', 'XR-CHEST',  'X-Ray Chest P/A View',         600, 'N', NULL,    'X-Ray',         '1 Hour'  FROM DUAL UNION ALL
        SELECT 'USG',  'USG-WA',    'USG of Whole Abdomen',        2000, 'N', NULL,    'USG',           '2 Hours' FROM DUAL UNION ALL
        SELECT 'CT',   'CT-BRAIN',  'CT Scan of Brain',            5000, 'N', NULL,    'CT',            '4 Hours' FROM DUAL UNION ALL
        SELECT 'CARDIO','ECG',      'ECG (12 Lead)',                400, 'N', NULL,    'Cardiology',    '30 Min'  FROM DUAL UNION ALL
        SELECT 'CARDIO','ECHO',     'Echocardiography',            3000, 'N', NULL,    'Cardiology',    '2 Hours' FROM DUAL UNION ALL
        SELECT 'PROC', 'DRESSING',  'Dressing (Small)',             300, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'PROC', 'NEBULIZE',  'Nebulization',                 200, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'BED',  'BED-GEN',   'General Ward Bed (per day)',  1000, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'BED',  'BED-CABIN', 'AC Cabin (per day)',          4000, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'BED',  'BED-ICU',   'ICU Bed (per day)',          12000, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'NURS', 'NURS-DAY',  'Nursing Charge (per day)',     500, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'MISC', 'ADM-FEE',   'Admission Fee',                500, 'N', NULL,    NULL,            NULL      FROM DUAL UNION ALL
        SELECT 'MISC', 'REG-FEE',   'Registration Fee',             100, 'N', NULL,    NULL,            NULL      FROM DUAL) v
    ON v.V_CAT = c.CATEGORY_CODE
 WHERE NOT EXISTS (SELECT 1 FROM HMS_SERVICE_MASTER t WHERE t.SERVICE_CODE = v.V_CODE);

-- 3) Lab parameters -----------------------------------------------------------
INSERT INTO HMS_LAB_PARAMETER (SERVICE_ID, PARAMETER_CODE, PARAMETER_NAME, UNIT, RESULT_TYPE, DISPLAY_ORDER)
SELECT s.SERVICE_ID, v.V_PCODE, v.V_PNAME, v.V_UNIT, 'NUMERIC', v.V_ORDER
  FROM HMS_SERVICE_MASTER s
  JOIN (SELECT 'CBC' V_SVC, 'HB' V_PCODE, 'Hemoglobin' V_PNAME, 'g/dL' V_UNIT, 1 V_ORDER FROM DUAL UNION ALL
        SELECT 'CBC', 'WBC',   'Total WBC Count',  '/cmm',        2 FROM DUAL UNION ALL
        SELECT 'CBC', 'NEUT',  'Neutrophils',      '%',           3 FROM DUAL UNION ALL
        SELECT 'CBC', 'LYMPH', 'Lymphocytes',      '%',           4 FROM DUAL UNION ALL
        SELECT 'CBC', 'PLT',   'Platelet Count',   '/cmm',        5 FROM DUAL UNION ALL
        SELECT 'CBC', 'RBC',   'RBC Count',        'million/cmm', 6 FROM DUAL UNION ALL
        SELECT 'RBS', 'RBS',   'Random Blood Sugar','mmol/L',     1 FROM DUAL UNION ALL
        SELECT 'FBS', 'FBS',   'Fasting Blood Sugar','mmol/L',    1 FROM DUAL UNION ALL
        SELECT 'SCR', 'CREAT', 'Serum Creatinine', 'mg/dL',       1 FROM DUAL) v
    ON v.V_SVC = s.SERVICE_CODE
 WHERE NOT EXISTS (SELECT 1 FROM HMS_LAB_PARAMETER t WHERE t.SERVICE_ID = s.SERVICE_ID AND t.PARAMETER_CODE = v.V_PCODE);

-- 4) Reference ranges -----------------------------------------------------------
INSERT INTO HMS_LAB_REFERENCE_RANGE (PARAMETER_ID, GENDER, MIN_VALUE, MAX_VALUE, CRITICAL_LOW, CRITICAL_HIGH)
SELECT p.PARAMETER_ID, v.V_GENDER, v.V_MIN, v.V_MAX, v.V_CRIT_LOW, v.V_CRIT_HIGH
  FROM HMS_LAB_PARAMETER p
  JOIN (SELECT 'HB' V_PCODE, 'MALE' V_GENDER, 13.0 V_MIN, 17.0 V_MAX, 7 V_CRIT_LOW, 20 V_CRIT_HIGH FROM DUAL UNION ALL
        SELECT 'HB',    'FEMALE', 12.0,   15.5,   7,     20      FROM DUAL UNION ALL
        SELECT 'WBC',   'ALL',    4000,   11000,  2000,  30000   FROM DUAL UNION ALL
        SELECT 'NEUT',  'ALL',    40,     75,     NULL,  NULL    FROM DUAL UNION ALL
        SELECT 'LYMPH', 'ALL',    20,     45,     NULL,  NULL    FROM DUAL UNION ALL
        SELECT 'PLT',   'ALL',    150000, 450000, 20000, 1000000 FROM DUAL UNION ALL
        SELECT 'RBS',   'ALL',    3.9,    7.8,    2.5,   25      FROM DUAL UNION ALL
        SELECT 'FBS',   'ALL',    3.9,    6.1,    2.5,   25      FROM DUAL UNION ALL
        SELECT 'CREAT', 'MALE',   0.7,    1.3,    NULL,  5       FROM DUAL UNION ALL
        SELECT 'CREAT', 'FEMALE', 0.6,    1.1,    NULL,  5       FROM DUAL) v
    ON v.V_PCODE = p.PARAMETER_CODE
 WHERE NOT EXISTS (SELECT 1 FROM HMS_LAB_REFERENCE_RANGE t WHERE t.PARAMETER_ID = p.PARAMETER_ID AND t.GENDER = v.V_GENDER);

-- 5) Ward ---------------------------------------------------------------------
INSERT INTO HMS_WARD (BRANCH_ID, WARD_CODE, WARD_NAME, WARD_TYPE, FLOOR_NO, TOTAL_BEDS, GENDER_ALLOWED)
SELECT br.BRANCH_ID, v.V_CODE, v.V_NAME, v.V_TYPE, v.V_FLOOR, v.V_BEDS, v.V_GENDER
  FROM HMS_BRANCH br
 CROSS JOIN (SELECT 'GW-M' V_CODE, 'General Ward (Male)' V_NAME, 'GENERAL' V_TYPE, '3' V_FLOOR, 10 V_BEDS, 'MALE' V_GENDER FROM DUAL UNION ALL
             SELECT 'GW-F', 'General Ward (Female)', 'GENERAL', '3', 10, 'FEMALE' FROM DUAL UNION ALL
             SELECT 'CAB',  'Cabin Block',           'CABIN',   '4', 10, 'ALL'    FROM DUAL UNION ALL
             SELECT 'ICU',  'ICU',                   'ICU',     '5',  6, 'ALL'    FROM DUAL) v
 WHERE br.BRANCH_CODE = 'HQ'
   AND NOT EXISTS (SELECT 1 FROM HMS_WARD t WHERE t.BRANCH_ID = br.BRANCH_ID AND t.WARD_CODE = v.V_CODE);

-- 6) Beds: ward onujayi auto create (GW-M-01 ... ) ----------------------------
INSERT INTO HMS_BED (WARD_ID, BED_NO, BED_TYPE, SERVICE_ID, DAILY_CHARGE)
SELECT w.WARD_ID,
       w.WARD_CODE || '-' || LPAD(nums.BED_SEQ, 2, '0'),
       CASE w.WARD_TYPE WHEN 'CABIN' THEN 'CABIN_AC' WHEN 'ICU' THEN 'ICU' ELSE 'GENERAL' END,
       s.SERVICE_ID,
       s.BASE_CHARGE
  FROM HMS_WARD w
  JOIN (SELECT LEVEL AS BED_SEQ FROM DUAL CONNECT BY LEVEL <= 20) nums ON nums.BED_SEQ <= w.TOTAL_BEDS
  JOIN HMS_SERVICE_MASTER s
    ON s.SERVICE_CODE = CASE w.WARD_TYPE WHEN 'CABIN' THEN 'BED-CABIN' WHEN 'ICU' THEN 'BED-ICU' ELSE 'BED-GEN' END
 WHERE NOT EXISTS (SELECT 1 FROM HMS_BED t WHERE t.WARD_ID = w.WARD_ID AND t.BED_NO = w.WARD_CODE || '-' || LPAD(nums.BED_SEQ, 2, '0'));

-- 7) OT -----------------------------------------------------------------------
INSERT INTO HMS_OT_MASTER (BRANCH_ID, OT_CODE, OT_NAME, OT_TYPE, FLOOR_NO)
SELECT br.BRANCH_ID, v.V_CODE, v.V_NAME, v.V_TYPE, '6'
  FROM HMS_BRANCH br
 CROSS JOIN (SELECT 'OT-1' V_CODE, 'Major OT 1' V_NAME, 'MAJOR' V_TYPE FROM DUAL UNION ALL
             SELECT 'OT-2', 'Minor OT', 'MINOR' FROM DUAL) v
 WHERE br.BRANCH_CODE = 'HQ'
   AND NOT EXISTS (SELECT 1 FROM HMS_OT_MASTER t WHERE t.BRANCH_ID = br.BRANCH_ID AND t.OT_CODE = v.V_CODE);

-- 8) Pharmacy stores ------------------------------------------------------------
INSERT INTO HMS_PHARMA_STORE (BRANCH_ID, STORE_CODE, STORE_NAME, STORE_TYPE)
SELECT br.BRANCH_ID, v.V_CODE, v.V_NAME, v.V_TYPE
  FROM HMS_BRANCH br
 CROSS JOIN (SELECT 'PH-MAIN' V_CODE, 'Main Medicine Store' V_NAME, 'MAIN' V_TYPE FROM DUAL UNION ALL
             SELECT 'PH-OPD',  'OPD Pharmacy', 'OPD' FROM DUAL UNION ALL
             SELECT 'PH-IPD',  'IPD Pharmacy', 'IPD' FROM DUAL) v
 WHERE br.BRANCH_CODE = 'HQ'
   AND NOT EXISTS (SELECT 1 FROM HMS_PHARMA_STORE t WHERE t.BRANCH_ID = br.BRANCH_ID AND t.STORE_CODE = v.V_CODE);

-- 9) General store --------------------------------------------------------------
INSERT INTO HMS_INV_STORE (BRANCH_ID, STORE_CODE, STORE_NAME)
SELECT br.BRANCH_ID, 'GEN-STORE', 'General Store'
  FROM HMS_BRANCH br
 WHERE br.BRANCH_CODE = 'HQ'
   AND NOT EXISTS (SELECT 1 FROM HMS_INV_STORE t WHERE t.BRANCH_ID = br.BRANCH_ID AND t.STORE_CODE = 'GEN-STORE');

COMMIT;
PROMPT >>> Done.
