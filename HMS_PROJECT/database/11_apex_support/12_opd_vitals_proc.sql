-- =============================================================================
-- 12_opd_vitals_proc.sql   (Sprint 4 - Page 22 Consultation, Vitals)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- PKG_OPD.save_vitals sudhu INSERT kore (duibar Save dile duita row hoy).
-- Ei procedure: visit er vitals row thakle UPDATE, na thakle INSERT; BMI hisab kore;
-- sahaj range/logic check kore (English message).
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PROCEDURE PR_SAVE_OPD_VITALS (
    p_visit_id    IN NUMBER,
    p_bp_sys      IN NUMBER DEFAULT NULL,
    p_bp_dia      IN NUMBER DEFAULT NULL,
    p_pulse       IN NUMBER DEFAULT NULL,
    p_temp        IN NUMBER DEFAULT NULL,
    p_rr          IN NUMBER DEFAULT NULL,
    p_spo2        IN NUMBER DEFAULT NULL,
    p_weight      IN NUMBER DEFAULT NULL,
    p_height      IN NUMBER DEFAULT NULL,
    p_sugar       IN NUMBER DEFAULT NULL,
    p_employee_id IN NUMBER DEFAULT NULL
) IS
    l_vital_id NUMBER;
    l_bmi      NUMBER;
    l_emp      NUMBER;
BEGIN
    IF p_visit_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20301, 'Visit is required.');
    END IF;
    IF p_bp_sys IS NOT NULL AND p_bp_dia IS NOT NULL AND p_bp_dia >= p_bp_sys THEN
        RAISE_APPLICATION_ERROR(-20302, 'Diastolic pressure must be lower than systolic pressure.');
    END IF;
    IF p_spo2 IS NOT NULL AND p_spo2 NOT BETWEEN 0 AND 100 THEN
        RAISE_APPLICATION_ERROR(-20303, 'SpO2 must be between 0 and 100.');
    END IF;
    IF p_weight IS NOT NULL AND p_weight <= 0 THEN
        RAISE_APPLICATION_ERROR(-20304, 'Weight must be greater than zero.');
    END IF;
    IF p_height IS NOT NULL AND p_height <= 0 THEN
        RAISE_APPLICATION_ERROR(-20305, 'Height must be greater than zero.');
    END IF;

    IF p_weight > 0 AND p_height > 0 THEN
        l_bmi := ROUND(p_weight / POWER(p_height / 100, 2), 2);
    END IF;

    -- RECORDED_BY FK: employee row na thakle NULL (error dibe na)
    BEGIN
        SELECT EMPLOYEE_ID INTO l_emp FROM HMS_EMPLOYEE WHERE EMPLOYEE_ID = p_employee_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        l_emp := NULL;
    END;

    SELECT MAX(VITAL_ID) INTO l_vital_id FROM HMS_OPD_VITALS WHERE VISIT_ID = p_visit_id;

    IF l_vital_id IS NULL THEN
        INSERT INTO HMS_OPD_VITALS (VISIT_ID, BP_SYSTOLIC, BP_DIASTOLIC, PULSE_RATE, TEMPERATURE_F,
                                    RESPIRATORY_RATE, SPO2, WEIGHT_KG, HEIGHT_CM, BMI, BLOOD_SUGAR, RECORDED_BY)
        VALUES (p_visit_id, p_bp_sys, p_bp_dia, p_pulse, p_temp,
                p_rr, p_spo2, p_weight, p_height, l_bmi, p_sugar, l_emp);
    ELSE
        UPDATE HMS_OPD_VITALS
           SET BP_SYSTOLIC = p_bp_sys, BP_DIASTOLIC = p_bp_dia, PULSE_RATE = p_pulse,
               TEMPERATURE_F = p_temp, RESPIRATORY_RATE = p_rr, SPO2 = p_spo2,
               WEIGHT_KG = p_weight, HEIGHT_CM = p_height, BMI = l_bmi, BLOOD_SUGAR = p_sugar,
               RECORDED_BY = NVL(l_emp, RECORDED_BY), RECORDED_TIME = SYSTIMESTAMP
         WHERE VITAL_ID = l_vital_id;
    END IF;
END PR_SAVE_OPD_VITALS;
/

SELECT object_name, status FROM user_objects WHERE object_name = 'PR_SAVE_OPD_VITALS';
