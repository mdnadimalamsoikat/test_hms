/*
================================================================================
 File    : database/05_packages/PKG_IPD.sql
 Run As  : HMS_APP
 Purpose : Admission, bed transfer, bed charge posting, discharge
 Depends : PKG_BILLING, TRG_ADMISSION_BED_STATUS (bed status auto update)
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_IPD ...

CREATE OR REPLACE PACKAGE PKG_IPD AS

    FUNCTION admit_patient (
        p_branch_id       IN NUMBER,
        p_patient_id      IN NUMBER,
        p_doctor_id       IN NUMBER,
        p_dept_id         IN NUMBER,
        p_bed_id          IN NUMBER,
        p_admission_type  IN VARCHAR2 DEFAULT 'PLANNED',
        p_reason          IN VARCHAR2 DEFAULT NULL,
        p_opd_visit_id    IN NUMBER   DEFAULT NULL,
        p_attendant_name  IN VARCHAR2 DEFAULT NULL,
        p_attendant_phone IN VARCHAR2 DEFAULT NULL,
        p_advance_amount  IN NUMBER   DEFAULT 0,
        p_payment_mode    IN VARCHAR2 DEFAULT 'CASH',
        p_admission_no    OUT VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE transfer_bed (
        p_admission_id IN NUMBER,
        p_to_bed_id    IN NUMBER,
        p_reason       IN VARCHAR2,
        p_authorized_by IN NUMBER DEFAULT NULL
    );

    -- Bed rent bill e post (discharge er somoy / daily job)
    PROCEDURE post_bed_charges (p_admission_id IN NUMBER);

    FUNCTION get_ipd_bill_id (p_admission_id IN NUMBER) RETURN NUMBER;

    PROCEDURE discharge_patient (
        p_admission_id   IN NUMBER,
        p_discharge_type IN VARCHAR2 DEFAULT 'NORMAL',
        p_allow_due      IN VARCHAR2 DEFAULT 'N'
    );

END PKG_IPD;
/

CREATE OR REPLACE PACKAGE BODY PKG_IPD AS

    FUNCTION get_ipd_bill_id (p_admission_id IN NUMBER) RETURN NUMBER IS
        l_id NUMBER;
    BEGIN
        SELECT MAX(BILL_ID) INTO l_id
          FROM HMS_BILLING
         WHERE ADMISSION_ID = p_admission_id
           AND BILL_TYPE = 'IPD'
           AND BILL_STATUS <> 'CANCELLED';
        RETURN l_id;
    END get_ipd_bill_id;

    ----------------------------------------------------------------------------
    FUNCTION admit_patient (
        p_branch_id       IN NUMBER,
        p_patient_id      IN NUMBER,
        p_doctor_id       IN NUMBER,
        p_dept_id         IN NUMBER,
        p_bed_id          IN NUMBER,
        p_admission_type  IN VARCHAR2 DEFAULT 'PLANNED',
        p_reason          IN VARCHAR2 DEFAULT NULL,
        p_opd_visit_id    IN NUMBER   DEFAULT NULL,
        p_attendant_name  IN VARCHAR2 DEFAULT NULL,
        p_attendant_phone IN VARCHAR2 DEFAULT NULL,
        p_advance_amount  IN NUMBER   DEFAULT 0,
        p_payment_mode    IN VARCHAR2 DEFAULT 'CASH',
        p_admission_no    OUT VARCHAR2
    ) RETURN NUMBER IS
        l_bed_status HMS_BED.BED_STATUS%TYPE;
        l_ward_id    NUMBER;
        l_cnt        NUMBER;
        l_adm_id     NUMBER;
        l_bill_id    NUMBER;
        l_adv_id     NUMBER;
    BEGIN
        -- Already admitted?
        SELECT COUNT(*) INTO l_cnt
          FROM HMS_IPD_ADMISSION
         WHERE PATIENT_ID = p_patient_id
           AND ADMISSION_STATUS IN ('ADMITTED', 'DISCHARGE_INITIATED');
        IF l_cnt > 0 THEN
            RAISE_APPLICATION_ERROR(-20301, 'Patient already admitted.');
        END IF;

        -- Lock bed row (2 jon same bed dite parbe na)
        SELECT BED_STATUS, WARD_ID INTO l_bed_status, l_ward_id
          FROM HMS_BED WHERE BED_ID = p_bed_id FOR UPDATE;
        IF l_bed_status NOT IN ('AVAILABLE', 'RESERVED') THEN
            RAISE_APPLICATION_ERROR(-20302, 'Bed available na (status: ' || l_bed_status || ')');
        END IF;

        p_admission_no := FN_GET_NEXT_NO(p_branch_id, 'IPD');

        INSERT INTO HMS_IPD_ADMISSION (ADMISSION_NO, BRANCH_ID, PATIENT_ID, OPD_VISIT_ID, ADMITTING_DOCTOR_ID,
                                       DEPT_ID, WARD_ID, BED_ID, ADMISSION_TYPE, ADMISSION_REASON,
                                       ATTENDANT_NAME, ATTENDANT_PHONE)
        VALUES (p_admission_no, p_branch_id, p_patient_id, p_opd_visit_id, p_doctor_id,
                p_dept_id, l_ward_id, p_bed_id, NVL(p_admission_type, 'PLANNED'), p_reason,
                p_attendant_name, p_attendant_phone)
        RETURNING ADMISSION_ID INTO l_adm_id;
        -- NOTE: bed OCCUPIED hobe TRG_ADMISSION_BED_STATUS trigger diye

        IF p_opd_visit_id IS NOT NULL THEN
            UPDATE HMS_OPD_VISIT SET VISIT_STATUS = 'ADMITTED' WHERE VISIT_ID = p_opd_visit_id;
        END IF;

        -- Running IPD bill open
        l_bill_id := PKG_BILLING.create_bill(p_branch_id, p_patient_id, 'IPD', p_admission_id => l_adm_id);

        IF NVL(p_advance_amount, 0) > 0 THEN
            l_adv_id := PKG_BILLING.collect_advance(p_patient_id, l_adm_id, p_advance_amount, p_payment_mode);
        END IF;

        RETURN l_adm_id;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_IPD.admit_patient', 'patient=' || p_patient_id || ' bed=' || p_bed_id);
        RAISE;
    END admit_patient;

    ----------------------------------------------------------------------------
    PROCEDURE transfer_bed (
        p_admission_id IN NUMBER,
        p_to_bed_id    IN NUMBER,
        p_reason       IN VARCHAR2,
        p_authorized_by IN NUMBER DEFAULT NULL
    ) IS
        l_from_bed NUMBER;
        l_status   HMS_BED.BED_STATUS%TYPE;
        l_ward     NUMBER;
    BEGIN
        SELECT BED_ID INTO l_from_bed
          FROM HMS_IPD_ADMISSION
         WHERE ADMISSION_ID = p_admission_id AND ADMISSION_STATUS = 'ADMITTED'
           FOR UPDATE;

        SELECT BED_STATUS, WARD_ID INTO l_status, l_ward FROM HMS_BED WHERE BED_ID = p_to_bed_id FOR UPDATE;
        IF l_status NOT IN ('AVAILABLE', 'RESERVED') THEN
            RAISE_APPLICATION_ERROR(-20303, 'Target bed available na.');
        END IF;

        -- Purono bed er rent post kore nei, tarpor transfer
        post_bed_charges(p_admission_id);

        INSERT INTO HMS_BED_TRANSFER (ADMISSION_ID, FROM_BED_ID, TO_BED_ID, TRANSFER_REASON, AUTHORIZED_BY)
        VALUES (p_admission_id, l_from_bed, p_to_bed_id, p_reason, p_authorized_by);

        UPDATE HMS_IPD_ADMISSION SET BED_ID = p_to_bed_id, WARD_ID = l_ward
         WHERE ADMISSION_ID = p_admission_id;
        -- trigger: old bed -> CLEANING, new bed -> OCCUPIED
    END transfer_bed;

    ----------------------------------------------------------------------------
    -- Bed charge: last posting (or admission / last transfer) theke aj porjonto
    -- din hisab (minimum 1 din). REF_TYPE='BED', REF_ID = BED_ID
    ----------------------------------------------------------------------------
    PROCEDURE post_bed_charges (p_admission_id IN NUMBER) IS
        l_adm      HMS_IPD_ADMISSION%ROWTYPE;
        l_bill_id  NUMBER;
        l_from     DATE;
        l_days     NUMBER;
        l_rate     NUMBER;
        l_svc      NUMBER;
        l_bed_no   HMS_BED.BED_NO%TYPE;
        l_posted   NUMBER;
    BEGIN
        SELECT * INTO l_adm FROM HMS_IPD_ADMISSION WHERE ADMISSION_ID = p_admission_id;
        l_bill_id := get_ipd_bill_id(p_admission_id);
        IF l_bill_id IS NULL THEN
            l_bill_id := PKG_BILLING.create_bill(l_adm.BRANCH_ID, l_adm.PATIENT_ID, 'IPD', p_admission_id => p_admission_id);
        END IF;

        -- Current bed kobe theke (last transfer ba admission)
        SELECT NVL(MAX(CAST(TRANSFER_DATE AS DATE)), CAST(l_adm.ADMISSION_DATE AS DATE))
          INTO l_from
          FROM HMS_BED_TRANSFER
         WHERE ADMISSION_ID = p_admission_id AND TO_BED_ID = l_adm.BED_ID;

        -- Ei bed er already koto din post hoyeche
        SELECT NVL(SUM(d.QUANTITY), 0) INTO l_posted
          FROM HMS_BILLING_DTL d
         WHERE d.BILL_ID = l_bill_id AND d.REF_TYPE = 'BED' AND d.REF_ID = l_adm.BED_ID
           AND d.SERVICE_DATE >= TRUNC(l_from) AND d.IS_ACTIVE = 'Y';

        l_days := GREATEST(CEIL(SYSDATE - l_from), 1) - l_posted;

        IF l_days > 0 THEN
            SELECT DAILY_CHARGE, SERVICE_ID, BED_NO INTO l_rate, l_svc, l_bed_no
              FROM HMS_BED WHERE BED_ID = l_adm.BED_ID;
            PKG_BILLING.add_bill_item(
                p_bill_id    => l_bill_id,
                p_service_id => l_svc,
                p_item_desc  => 'Bed Charge - ' || l_bed_no,
                p_quantity   => l_days,
                p_unit_price => l_rate,
                p_ref_type   => 'BED',
                p_ref_id     => l_adm.BED_ID);
        END IF;
    END post_bed_charges;

    ----------------------------------------------------------------------------
    PROCEDURE discharge_patient (
        p_admission_id   IN NUMBER,
        p_discharge_type IN VARCHAR2 DEFAULT 'NORMAL',
        p_allow_due      IN VARCHAR2 DEFAULT 'N'
    ) IS
        l_status  HMS_IPD_ADMISSION.ADMISSION_STATUS%TYPE;
        l_bill_id NUMBER;
        l_due     NUMBER;
    BEGIN
        SELECT ADMISSION_STATUS INTO l_status
          FROM HMS_IPD_ADMISSION WHERE ADMISSION_ID = p_admission_id FOR UPDATE;
        IF l_status NOT IN ('ADMITTED', 'DISCHARGE_INITIATED') THEN
            RAISE_APPLICATION_ERROR(-20304, 'Admission already closed: ' || l_status);
        END IF;

        post_bed_charges(p_admission_id);
        l_bill_id := get_ipd_bill_id(p_admission_id);
        PKG_BILLING.adjust_advance(l_bill_id);

        SELECT DUE_AMOUNT INTO l_due FROM HMS_BILLING WHERE BILL_ID = l_bill_id;
        IF l_due > 0 AND NVL(p_allow_due, 'N') = 'N' AND p_discharge_type NOT IN ('DEATH', 'ABSCONDED') THEN
            RAISE_APPLICATION_ERROR(-20305, 'Due ache: ' || l_due || ' Tk. Clear na kore discharge kora jabe na.');
        END IF;

        UPDATE HMS_IPD_ADMISSION
           SET ADMISSION_STATUS = CASE p_discharge_type
                                      WHEN 'NORMAL'    THEN 'DISCHARGED'
                                      WHEN 'LAMA'      THEN 'LAMA'
                                      WHEN 'DEATH'     THEN 'DEATH'
                                      WHEN 'ABSCONDED' THEN 'ABSCONDED'
                                      WHEN 'REFERRED'  THEN 'REFERRED'
                                      ELSE 'DISCHARGED' END,
               DISCHARGE_DATE   = SYSTIMESTAMP
         WHERE ADMISSION_ID = p_admission_id;
        -- trigger: bed -> CLEANING
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_IPD.discharge_patient', 'admission=' || p_admission_id);
        RAISE;
    END discharge_patient;

END PKG_IPD;
/
SHOW ERRORS
