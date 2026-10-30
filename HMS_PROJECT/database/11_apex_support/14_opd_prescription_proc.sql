-- =============================================================================
-- 14_opd_prescription_proc.sql   (Sprint 4 - Page 22 Prescription lines)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- PR_ADD_OPD_RX_LINE    : visit er prescription e 1 ta medicine line jog kore.
--                         Prescription header (RX-<VISIT_NO>) na thakle nije banay.
-- PR_REMOVE_OPD_RX_LINE : 1 ta line soft-delete kore (IS_ACTIVE = 'N').
-- Completed / cancelled visit e kono change hobe na.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PROCEDURE PR_ADD_OPD_RX_LINE (
    p_visit_id     IN NUMBER,
    p_item_id      IN NUMBER,
    p_dosage       IN VARCHAR2 DEFAULT NULL,
    p_frequency    IN VARCHAR2 DEFAULT NULL,
    p_route        IN VARCHAR2 DEFAULT 'Oral',
    p_days         IN NUMBER   DEFAULT NULL,
    p_meal         IN VARCHAR2 DEFAULT 'ANY',
    p_instructions IN VARCHAR2 DEFAULT NULL
) IS
    l_status    HMS_OPD_VISIT.VISIT_STATUS%TYPE;
    l_doctor_id NUMBER;
    l_visit_no  VARCHAR2(30);
    l_rx_id     NUMBER;
    l_cons_id   NUMBER;
    l_name      VARCHAR2(300);
    l_per_day   NUMBER := 0;
    l_qty       NUMBER;
    l_dup       NUMBER;
    l_meal      VARCHAR2(50) := NVL(p_meal, 'ANY');
BEGIN
    IF p_visit_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20320, 'Visit is missing.');
    END IF;

    BEGIN
        SELECT VISIT_STATUS, DOCTOR_ID, VISIT_NO
          INTO l_status, l_doctor_id, l_visit_no
          FROM HMS_OPD_VISIT WHERE VISIT_ID = p_visit_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20321, 'Visit not found.');
    END;

    IF l_status IN ('COMPLETED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20322, 'This visit is already ' || LOWER(l_status) || '. The prescription cannot be changed.');
    END IF;

    IF p_item_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20323, 'Please select a medicine.');
    END IF;
    BEGIN
        SELECT ITEM_NAME || NVL2(STRENGTH, ' ' || STRENGTH, '') || NVL2(DOSAGE_FORM, ' (' || DOSAGE_FORM || ')', '')
          INTO l_name
          FROM HMS_PHARMA_ITEM WHERE ITEM_ID = p_item_id AND IS_ACTIVE = 'Y';
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20324, 'Medicine not found or inactive.');
    END;

    IF p_frequency IS NULL THEN
        RAISE_APPLICATION_ERROR(-20325, 'Please select how often the medicine is taken.');
    END IF;
    IF p_frequency <> 'SOS' AND NOT REGEXP_LIKE(p_frequency, '^[0-9](\+[0-9]){1,3}$') THEN
        RAISE_APPLICATION_ERROR(-20326, 'Frequency must look like 1+0+1 (or SOS).');
    END IF;

    IF p_frequency = 'SOS' THEN
        l_qty := NULL;                      -- SOS = proyojon hole, quantity hishab hobe na
    ELSE
        IF p_days IS NULL OR p_days < 1 OR p_days > 365 OR p_days <> TRUNC(p_days) THEN
            RAISE_APPLICATION_ERROR(-20327, 'Duration must be a whole number between 1 and 365 days.');
        END IF;
        FOR i IN 1 .. REGEXP_COUNT(p_frequency, '[0-9]') LOOP
            l_per_day := l_per_day + TO_NUMBER(REGEXP_SUBSTR(p_frequency, '[0-9]', 1, i));
        END LOOP;
        l_qty := l_per_day * p_days;        -- 1+0+1 x 5 din = 10 (1 unit per dose dhore)
    END IF;

    IF l_meal NOT IN ('BEFORE_MEAL', 'AFTER_MEAL', 'WITH_MEAL', 'EMPTY_STOMACH', 'ANY') THEN
        RAISE_APPLICATION_ERROR(-20328, 'Invalid meal instruction.');
    END IF;

    -- Header (1 visit = 1 prescription): thakle nao, na thakle banao
    BEGIN
        SELECT PRESCRIPTION_ID INTO l_rx_id
          FROM HMS_OPD_PRESCRIPTION
         WHERE VISIT_ID = p_visit_id AND IS_ACTIVE = 'Y' AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        BEGIN
            SELECT CONSULTATION_ID INTO l_cons_id
              FROM (SELECT CONSULTATION_ID FROM HMS_OPD_CONSULTATION
                     WHERE VISIT_ID = p_visit_id ORDER BY CONSULTATION_ID DESC)
             WHERE ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN l_cons_id := NULL;
        END;
        INSERT INTO HMS_OPD_PRESCRIPTION (VISIT_ID, CONSULTATION_ID, PRESCRIPTION_NO, DOCTOR_ID)
        VALUES (p_visit_id, l_cons_id, 'RX-' || l_visit_no, l_doctor_id)
        RETURNING PRESCRIPTION_ID INTO l_rx_id;
    END;

    SELECT COUNT(*) INTO l_dup
      FROM HMS_OPD_PRESCRIPTION_DTL
     WHERE PRESCRIPTION_ID = l_rx_id AND ITEM_ID = p_item_id AND IS_ACTIVE = 'Y';
    IF l_dup > 0 THEN
        RAISE_APPLICATION_ERROR(-20329, 'This medicine is already in the prescription. Remove it first to change it.');
    END IF;

    INSERT INTO HMS_OPD_PRESCRIPTION_DTL
        (PRESCRIPTION_ID, ITEM_ID, MEDICINE_NAME, DOSAGE, FREQUENCY, ROUTE,
         DURATION_DAYS, MEAL_INSTRUCTION, QUANTITY, INSTRUCTIONS)
    VALUES
        (l_rx_id, p_item_id, l_name, TRIM(p_dosage), p_frequency, p_route,
         p_days, l_meal, l_qty, TRIM(p_instructions));
END PR_ADD_OPD_RX_LINE;
/

CREATE OR REPLACE PROCEDURE PR_REMOVE_OPD_RX_LINE (
    p_dtl_id IN NUMBER
) IS
    l_status HMS_OPD_VISIT.VISIT_STATUS%TYPE;
BEGIN
    BEGIN
        SELECT v.VISIT_STATUS INTO l_status
          FROM HMS_OPD_PRESCRIPTION_DTL d
          JOIN HMS_OPD_PRESCRIPTION r ON r.PRESCRIPTION_ID = d.PRESCRIPTION_ID
          JOIN HMS_OPD_VISIT v        ON v.VISIT_ID = r.VISIT_ID
         WHERE d.PRESCRIPTION_DTL_ID = p_dtl_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20330, 'Prescription line not found.');
    END;

    IF l_status IN ('COMPLETED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20331, 'This visit is already ' || LOWER(l_status) || '. The prescription cannot be changed.');
    END IF;

    UPDATE HMS_OPD_PRESCRIPTION_DTL SET IS_ACTIVE = 'N' WHERE PRESCRIPTION_DTL_ID = p_dtl_id;
END PR_REMOVE_OPD_RX_LINE;
/

SELECT object_name, status FROM user_objects
 WHERE object_name IN ('PR_ADD_OPD_RX_LINE', 'PR_REMOVE_OPD_RX_LINE');
