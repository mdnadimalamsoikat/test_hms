-- =============================================================================
-- 09_opd_fee_functions.sql   (Sprint 4 - Page 20 New OPD Visit)
-- Schema: HMS_APP  |  Re-runnable
--
-- Page 20 e fee dekhano + validation er jonno ekta-i hisab (PKG_OPD.create_visit
-- er sathe EKI niyom):  oi doctor er kache aager NEW visit er por
-- FOLLOWUP_VALID_DAYS (default 7) er moddhe hole -> FOLLOWUP_FEE, nahole CONSULTATION_FEE.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE FUNCTION FN_OPD_IS_FOLLOWUP (
    p_patient_id IN NUMBER,
    p_doctor_id  IN NUMBER
) RETURN VARCHAR2 IS
    l_days NUMBER;
    l_last DATE;
BEGIN
    IF p_patient_id IS NULL OR p_doctor_id IS NULL THEN
        RETURN 'N';
    END IF;

    SELECT NVL(FOLLOWUP_VALID_DAYS, 7) INTO l_days
      FROM HMS_DOCTOR WHERE DOCTOR_ID = p_doctor_id;

    SELECT MAX(VISIT_DATE) INTO l_last
      FROM HMS_OPD_VISIT
     WHERE PATIENT_ID   = p_patient_id
       AND DOCTOR_ID    = p_doctor_id
       AND VISIT_STATUS <> 'CANCELLED'
       AND IS_FOLLOWUP  = 'N';

    IF l_last IS NOT NULL AND TRUNC(SYSDATE) - l_last <= l_days THEN
        RETURN 'Y';
    END IF;
    RETURN 'N';
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'N';
END FN_OPD_IS_FOLLOWUP;
/

CREATE OR REPLACE FUNCTION FN_OPD_FEE (
    p_patient_id IN NUMBER,
    p_doctor_id  IN NUMBER
) RETURN NUMBER IS
    l_new NUMBER;
    l_fu  NUMBER;
BEGIN
    IF p_doctor_id IS NULL THEN
        RETURN 0;
    END IF;

    SELECT NVL(CONSULTATION_FEE, 0), NVL(FOLLOWUP_FEE, 0)
      INTO l_new, l_fu
      FROM HMS_DOCTOR WHERE DOCTOR_ID = p_doctor_id;

    IF FN_OPD_IS_FOLLOWUP(p_patient_id, p_doctor_id) = 'Y' THEN
        RETURN l_fu;
    END IF;
    RETURN l_new;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
END FN_OPD_FEE;
/

SELECT object_name, status FROM user_objects
 WHERE object_name IN ('FN_OPD_IS_FOLLOWUP','FN_OPD_FEE');
