/*
================================================================================
 File    : database/05_packages/PKG_OPD.sql
 Run As  : HMS_APP
 Purpose : OPD visit (token, follow-up fee logic, auto bill), vitals, consultation
 Depends : PKG_BILLING
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_OPD ...

CREATE OR REPLACE PACKAGE PKG_OPD AS

    FUNCTION create_visit (
        p_branch_id      IN NUMBER,
        p_patient_id     IN NUMBER,
        p_doctor_id      IN NUMBER,
        p_dept_id        IN NUMBER,
        p_appointment_id IN NUMBER   DEFAULT NULL,
        p_discount       IN NUMBER   DEFAULT 0,
        p_visit_no       OUT VARCHAR2,
        p_bill_id        OUT NUMBER
    ) RETURN NUMBER;

    PROCEDURE save_vitals (
        p_visit_id  IN NUMBER,
        p_bp_sys    IN NUMBER DEFAULT NULL,
        p_bp_dia    IN NUMBER DEFAULT NULL,
        p_pulse     IN NUMBER DEFAULT NULL,
        p_temp      IN NUMBER DEFAULT NULL,
        p_spo2      IN NUMBER DEFAULT NULL,
        p_weight    IN NUMBER DEFAULT NULL,
        p_height    IN NUMBER DEFAULT NULL
    );

    PROCEDURE start_consultation (p_visit_id IN NUMBER);
    PROCEDURE complete_visit     (p_visit_id IN NUMBER);

END PKG_OPD;
/

CREATE OR REPLACE PACKAGE BODY PKG_OPD AS

    FUNCTION create_visit (
        p_branch_id      IN NUMBER,
        p_patient_id     IN NUMBER,
        p_doctor_id      IN NUMBER,
        p_dept_id        IN NUMBER,
        p_appointment_id IN NUMBER   DEFAULT NULL,
        p_discount       IN NUMBER   DEFAULT 0,
        p_visit_no       OUT VARCHAR2,
        p_bill_id        OUT NUMBER
    ) RETURN NUMBER IS
        l_doc       HMS_DOCTOR%ROWTYPE;
        l_prev_id   NUMBER;
        l_prev_date DATE;
        l_is_fu     CHAR(1) := 'N';
        l_fee       NUMBER;
        l_token     NUMBER;
        l_visit_id  NUMBER;
        l_svc_id    NUMBER;
    BEGIN
        SELECT * INTO l_doc FROM HMS_DOCTOR WHERE DOCTOR_ID = p_doctor_id AND IS_ACTIVE = 'Y';

        -- Last visit with same doctor (follow-up check)
        BEGIN
            SELECT VISIT_ID, VISIT_DATE INTO l_prev_id, l_prev_date
              FROM (SELECT VISIT_ID, VISIT_DATE
                      FROM HMS_OPD_VISIT
                     WHERE PATIENT_ID = p_patient_id
                       AND DOCTOR_ID  = p_doctor_id
                       AND VISIT_STATUS <> 'CANCELLED'
                       AND IS_FOLLOWUP = 'N'
                     ORDER BY VISIT_DATE DESC, VISIT_ID DESC)
             WHERE ROWNUM = 1;
            IF TRUNC(SYSDATE) - l_prev_date <= NVL(l_doc.FOLLOWUP_VALID_DAYS, 7) THEN
                l_is_fu := 'Y';
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;

        l_fee := CASE WHEN l_is_fu = 'Y' THEN NVL(l_doc.FOLLOWUP_FEE, 0) ELSE NVL(l_doc.CONSULTATION_FEE, 0) END;

        -- Token: doctor wise daily serial
        SELECT NVL(MAX(TOKEN_NO), 0) + 1 INTO l_token
          FROM HMS_OPD_VISIT
         WHERE DOCTOR_ID = p_doctor_id AND VISIT_DATE = TRUNC(SYSDATE);

        p_visit_no := FN_GET_NEXT_NO(p_branch_id, 'OPD');

        INSERT INTO HMS_OPD_VISIT (VISIT_NO, BRANCH_ID, PATIENT_ID, DOCTOR_ID, DEPT_ID, APPOINTMENT_ID,
                                   TOKEN_NO, VISIT_TYPE, IS_FOLLOWUP, PREVIOUS_VISIT_ID,
                                   CONSULTATION_FEE, DISCOUNT_AMOUNT, NET_FEE)
        VALUES (p_visit_no, p_branch_id, p_patient_id, p_doctor_id, p_dept_id, p_appointment_id,
                l_token, CASE WHEN l_is_fu = 'Y' THEN 'FOLLOWUP' ELSE 'NEW' END, l_is_fu,
                CASE WHEN l_is_fu = 'Y' THEN l_prev_id END,
                l_fee, NVL(p_discount, 0), l_fee - NVL(p_discount, 0))
        RETURNING VISIT_ID INTO l_visit_id;

        IF p_appointment_id IS NOT NULL THEN
            UPDATE HMS_APPOINTMENT
               SET APPOINTMENT_STATUS = 'ARRIVED', OPD_VISIT_ID = l_visit_id
             WHERE APPOINTMENT_ID = p_appointment_id;
        END IF;

        -- Auto bill (consultation service code = 'CONS-OPD')
        BEGIN
            SELECT SERVICE_ID INTO l_svc_id FROM HMS_SERVICE_MASTER WHERE SERVICE_CODE = 'CONS-OPD';
        EXCEPTION WHEN NO_DATA_FOUND THEN l_svc_id := NULL;
        END;

        p_bill_id := PKG_BILLING.create_bill(p_branch_id, p_patient_id, 'OPD', p_opd_visit_id => l_visit_id);
        PKG_BILLING.add_bill_item(
            p_bill_id    => p_bill_id,
            p_service_id => l_svc_id,
            p_item_desc  => CASE WHEN l_is_fu = 'Y' THEN 'Follow-up Consultation' ELSE 'Consultation Fee' END,
            p_quantity   => 1,
            p_unit_price => l_fee,
            p_discount   => NVL(p_discount, 0),
            p_doctor_id  => p_doctor_id,
            p_ref_type   => 'OPD_VISIT',
            p_ref_id     => l_visit_id);

        RETURN l_visit_id;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_OPD.create_visit', 'patient=' || p_patient_id || ' doctor=' || p_doctor_id);
        RAISE;
    END create_visit;

    PROCEDURE save_vitals (
        p_visit_id  IN NUMBER,
        p_bp_sys    IN NUMBER DEFAULT NULL,
        p_bp_dia    IN NUMBER DEFAULT NULL,
        p_pulse     IN NUMBER DEFAULT NULL,
        p_temp      IN NUMBER DEFAULT NULL,
        p_spo2      IN NUMBER DEFAULT NULL,
        p_weight    IN NUMBER DEFAULT NULL,
        p_height    IN NUMBER DEFAULT NULL
    ) IS
        l_bmi NUMBER;
    BEGIN
        IF p_weight > 0 AND p_height > 0 THEN
            l_bmi := ROUND(p_weight / POWER(p_height / 100, 2), 2);
        END IF;
        INSERT INTO HMS_OPD_VITALS (VISIT_ID, BP_SYSTOLIC, BP_DIASTOLIC, PULSE_RATE, TEMPERATURE_F,
                                    SPO2, WEIGHT_KG, HEIGHT_CM, BMI)
        VALUES (p_visit_id, p_bp_sys, p_bp_dia, p_pulse, p_temp, p_spo2, p_weight, p_height, l_bmi);
    END save_vitals;

    PROCEDURE start_consultation (p_visit_id IN NUMBER) IS
    BEGIN
        UPDATE HMS_OPD_VISIT SET VISIT_STATUS = 'IN_CONSULTATION'
         WHERE VISIT_ID = p_visit_id AND VISIT_STATUS = 'WAITING';
    END start_consultation;

    PROCEDURE complete_visit (p_visit_id IN NUMBER) IS
    BEGIN
        UPDATE HMS_OPD_VISIT SET VISIT_STATUS = 'COMPLETED' WHERE VISIT_ID = p_visit_id;
        UPDATE HMS_APPOINTMENT SET APPOINTMENT_STATUS = 'COMPLETED' WHERE OPD_VISIT_ID = p_visit_id;
    END complete_visit;

END PKG_OPD;
/
SHOW ERRORS
