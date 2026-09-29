/*
================================================================================
 File    : database/05_packages/PKG_PATIENT.sql
 Run As  : HMS_APP
 Purpose : Patient registration (MRN auto), duplicate check, allergy
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_PATIENT ...

CREATE OR REPLACE PACKAGE PKG_PATIENT AS

    FUNCTION register_patient (
        p_branch_id      IN NUMBER,
        p_first_name     IN VARCHAR2,
        p_last_name      IN VARCHAR2,
        p_gender         IN VARCHAR2,
        p_phone          IN VARCHAR2,
        p_dob            IN DATE     DEFAULT NULL,
        p_age_years      IN NUMBER   DEFAULT NULL,
        p_blood_group    IN VARCHAR2 DEFAULT NULL,
        p_father_name    IN VARCHAR2 DEFAULT NULL,
        p_nid            IN VARCHAR2 DEFAULT NULL,
        p_address        IN VARCHAR2 DEFAULT NULL,
        p_district       IN VARCHAR2 DEFAULT NULL,
        p_category       IN VARCHAR2 DEFAULT 'GENERAL',
        p_ref_doctor_id  IN NUMBER   DEFAULT NULL,
        p_mrn            OUT VARCHAR2
    ) RETURN NUMBER;

    -- Same phone + name + gender age thakle patient_id return kore (duplicate check)
    FUNCTION find_duplicate (
        p_phone      IN VARCHAR2,
        p_first_name IN VARCHAR2,
        p_gender     IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION get_full_name (p_patient_id IN NUMBER) RETURN VARCHAR2;

    PROCEDURE add_allergy (
        p_patient_id IN NUMBER,
        p_type       IN VARCHAR2,
        p_name       IN VARCHAR2,
        p_severity   IN VARCHAR2 DEFAULT 'MILD',
        p_reaction   IN VARCHAR2 DEFAULT NULL
    );

END PKG_PATIENT;
/

CREATE OR REPLACE PACKAGE BODY PKG_PATIENT AS

    FUNCTION register_patient (
        p_branch_id      IN NUMBER,
        p_first_name     IN VARCHAR2,
        p_last_name      IN VARCHAR2,
        p_gender         IN VARCHAR2,
        p_phone          IN VARCHAR2,
        p_dob            IN DATE     DEFAULT NULL,
        p_age_years      IN NUMBER   DEFAULT NULL,
        p_blood_group    IN VARCHAR2 DEFAULT NULL,
        p_father_name    IN VARCHAR2 DEFAULT NULL,
        p_nid            IN VARCHAR2 DEFAULT NULL,
        p_address        IN VARCHAR2 DEFAULT NULL,
        p_district       IN VARCHAR2 DEFAULT NULL,
        p_category       IN VARCHAR2 DEFAULT 'GENERAL',
        p_ref_doctor_id  IN NUMBER   DEFAULT NULL,
        p_mrn            OUT VARCHAR2
    ) RETURN NUMBER IS
        l_id  NUMBER;
        l_dob DATE := p_dob;
    BEGIN
        IF TRIM(p_first_name) IS NULL OR TRIM(p_phone) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20201, 'Patient name ebong phone mandatory.');
        END IF;
        -- DOB na dile age theke approx DOB
        IF l_dob IS NULL AND p_age_years IS NOT NULL THEN
            l_dob := ADD_MONTHS(TRUNC(SYSDATE), -12 * p_age_years);
        END IF;

        p_mrn := FN_GET_NEXT_NO(p_branch_id, 'MRN');

        INSERT INTO HMS_PATIENT (MRN, BRANCH_ID, FIRST_NAME, LAST_NAME, GENDER, DATE_OF_BIRTH, AGE_YEARS,
                                 BLOOD_GROUP, FATHER_NAME, NID_NUMBER, PHONE_PRIMARY, PRESENT_ADDRESS,
                                 PRESENT_DISTRICT, PATIENT_CATEGORY, REFERRED_DOCTOR_ID)
        VALUES (p_mrn, p_branch_id, INITCAP(TRIM(p_first_name)), INITCAP(TRIM(p_last_name)), UPPER(p_gender),
                l_dob, NVL(p_age_years, TRUNC(MONTHS_BETWEEN(SYSDATE, l_dob) / 12)),
                p_blood_group, p_father_name, p_nid, TRIM(p_phone), p_address,
                p_district, NVL(p_category, 'GENERAL'), p_ref_doctor_id)
        RETURNING PATIENT_ID INTO l_id;

        RETURN l_id;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_PATIENT.register_patient', p_first_name || '/' || p_phone);
        RAISE;
    END register_patient;

    FUNCTION find_duplicate (
        p_phone      IN VARCHAR2,
        p_first_name IN VARCHAR2,
        p_gender     IN VARCHAR2
    ) RETURN NUMBER IS
        l_id NUMBER;
    BEGIN
        SELECT MIN(PATIENT_ID) INTO l_id
          FROM HMS_PATIENT
         WHERE PHONE_PRIMARY = TRIM(p_phone)
           AND UPPER(FIRST_NAME) = UPPER(TRIM(p_first_name))
           AND GENDER = UPPER(p_gender)
           AND IS_ACTIVE = 'Y';
        RETURN l_id;
    END find_duplicate;

    FUNCTION get_full_name (p_patient_id IN NUMBER) RETURN VARCHAR2 IS
        l_name VARCHAR2(400);
    BEGIN
        SELECT TRIM(TITLE || ' ' || FIRST_NAME || ' ' || MIDDLE_NAME || ' ' || LAST_NAME)
          INTO l_name FROM HMS_PATIENT WHERE PATIENT_ID = p_patient_id;
        RETURN REGEXP_REPLACE(l_name, ' +', ' ');
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
    END get_full_name;

    PROCEDURE add_allergy (
        p_patient_id IN NUMBER,
        p_type       IN VARCHAR2,
        p_name       IN VARCHAR2,
        p_severity   IN VARCHAR2 DEFAULT 'MILD',
        p_reaction   IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO HMS_PATIENT_ALLERGY (PATIENT_ID, ALLERGY_TYPE, ALLERGY_NAME, SEVERITY, REACTION_DESC)
        VALUES (p_patient_id, UPPER(p_type), p_name, UPPER(p_severity), p_reaction);
    END add_allergy;

END PKG_PATIENT;
/
SHOW ERRORS
