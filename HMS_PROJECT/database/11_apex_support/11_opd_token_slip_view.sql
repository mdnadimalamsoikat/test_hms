-- =============================================================================
-- 11_opd_token_slip_view.sql   (Sprint 4 - Page 201 OPD Token Slip, 80mm print)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- Ek visit er token slip e lagbe sob tothho ek jaygay: branch letterhead,
-- patient, doctor, department, token, fee, payment. Page 201 sudhu ei view theke pore.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE VIEW VW_OPD_TOKEN_SLIP AS
SELECT v.VISIT_ID,
       v.BRANCH_ID,
       v.VISIT_NO,
       v.TOKEN_NO,
       v.VISIT_DATE,
       v.VISIT_TIME,
       v.IS_FOLLOWUP,
       v.CONSULTATION_FEE,
       v.DISCOUNT_AMOUNT,
       v.NET_FEE,
       v.PAYMENT_STATUS,
       br.BRANCH_NAME,
       TRIM(br.ADDRESS_LINE1 || NVL2(br.CITY, ', ' || br.CITY, NULL)) AS BRANCH_ADDRESS,
       br.PHONE                                                      AS BRANCH_PHONE,
       p.MRN,
       REGEXP_REPLACE(TRIM(p.FIRST_NAME || ' ' || p.MIDDLE_NAME || ' ' || p.LAST_NAME), ' +', ' ') AS PATIENT_NAME,
       p.GENDER,
       FN_CALCULATE_AGE(p.DATE_OF_BIRTH)                             AS AGE,
       p.PHONE_PRIMARY,
       'Dr. ' || TRIM(e.FIRST_NAME || ' ' || e.LAST_NAME)            AS DOCTOR_NAME,
       d.SPECIALIZATION,
       dep.DEPT_NAME,
       dep.FLOOR_NO,
       b.BILL_NO,
       b.PAID_AMOUNT,
       b.DUE_AMOUNT
  FROM HMS_OPD_VISIT  v
  JOIN HMS_BRANCH     br  ON br.BRANCH_ID   = v.BRANCH_ID
  JOIN HMS_PATIENT    p   ON p.PATIENT_ID   = v.PATIENT_ID
  JOIN HMS_DOCTOR     d   ON d.DOCTOR_ID    = v.DOCTOR_ID
  JOIN HMS_EMPLOYEE   e   ON e.EMPLOYEE_ID  = d.EMPLOYEE_ID
  JOIN HMS_DEPARTMENT dep ON dep.DEPT_ID    = v.DEPT_ID
  LEFT JOIN HMS_BILLING b ON b.OPD_VISIT_ID = v.VISIT_ID
                         AND b.BILL_STATUS <> 'CANCELLED';

SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS WHERE OBJECT_NAME = 'VW_OPD_TOKEN_SLIP';
