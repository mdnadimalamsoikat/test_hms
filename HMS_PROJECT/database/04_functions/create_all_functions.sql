/*
================================================================================
 Project : Hospital Management System (HMS) - Oracle 19c
 File    : database/04_functions/create_all_functions.sql
 Run As  : HMS_APP
 Purpose : Common utility functions / procedures
           PR_LOG_ERROR, FN_GET_NEXT_NO, FN_CALCULATE_AGE, FN_GET_AVAILABLE_BEDS,
           FN_GET_PATIENT_DUE, FN_CALCULATE_DISCOUNT, FN_GET_SERVICE_RATE,
           FN_HASH_PASSWORD, FN_CURRENT_USER
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating common functions ...

--------------------------------------------------------------------------------
-- Current user (APEX user thakle seta, na hole DB user)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CURRENT_USER RETURN VARCHAR2 IS
BEGIN
    RETURN NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
END FN_CURRENT_USER;
/

--------------------------------------------------------------------------------
-- Error logger (AUTONOMOUS - main transaction rollback holeo log thakbe)
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PR_LOG_ERROR (
    p_program IN VARCHAR2,
    p_params  IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- SQLCODE/SQLERRM SQL statement e directly use kora jay na (PLS-00231) -> variable e rakhi
    l_code NUMBER         := SQLCODE;
    l_msg  VARCHAR2(4000) := SUBSTR(SQLERRM, 1, 4000);
    l_bt   VARCHAR2(4000) := SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000);
BEGIN
    INSERT INTO HMS_ERROR_LOG (ERROR_CODE, ERROR_MSG, ERROR_BACKTRACE, PROGRAM_NAME, PARAMS, LOGGED_BY)
    VALUES (l_code, l_msg, l_bt,
            p_program, SUBSTR(p_params, 1, 4000), FN_CURRENT_USER);
    COMMIT;
END PR_LOG_ERROR;
/

--------------------------------------------------------------------------------
-- Document number generator  (MRN, BILL, OPD, IPD, LAB, RCPT ...)
-- Example : FN_GET_NEXT_NO(1,'MRN')  -> MRN-000001
--           FN_GET_NEXT_NO(1,'BILL') -> BIL-2026-000123  (yearly reset)
-- SELECT ... FOR UPDATE use kora hoyeche -> 2 user eksathe same number pabe na
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_GET_NEXT_NO (
    p_branch_id   IN NUMBER,
    p_series_type IN VARCHAR2
) RETURN VARCHAR2 IS
    l_rec   HMS_NUMBER_SERIES%ROWTYPE;
    l_reset BOOLEAN := FALSE;
    l_no    VARCHAR2(50);
    l_reset_yn CHAR(1) := 'N';   -- BOOLEAN SQL e chole na (19c), tai Y/N
BEGIN
    SELECT * INTO l_rec
      FROM HMS_NUMBER_SERIES
     WHERE BRANCH_ID = p_branch_id
       AND SERIES_TYPE = UPPER(p_series_type)
       FOR UPDATE;

    IF    l_rec.RESET_CYCLE = 'YEARLY'  AND TRUNC(NVL(l_rec.LAST_RESET_DATE, DATE '1900-01-01'), 'YYYY') <> TRUNC(SYSDATE, 'YYYY') THEN l_reset := TRUE;
    ELSIF l_rec.RESET_CYCLE = 'MONTHLY' AND TRUNC(NVL(l_rec.LAST_RESET_DATE, DATE '1900-01-01'), 'MM')   <> TRUNC(SYSDATE, 'MM')   THEN l_reset := TRUE;
    ELSIF l_rec.RESET_CYCLE = 'DAILY'   AND TRUNC(NVL(l_rec.LAST_RESET_DATE, DATE '1900-01-01'))         <> TRUNC(SYSDATE)         THEN l_reset := TRUE;
    END IF;

    IF l_reset THEN
        l_rec.CURRENT_NO := 0;
        l_reset_yn := 'Y';
    END IF;
    l_rec.CURRENT_NO := l_rec.CURRENT_NO + 1;

    UPDATE HMS_NUMBER_SERIES
       SET CURRENT_NO      = l_rec.CURRENT_NO,
           LAST_RESET_DATE = CASE WHEN l_reset_yn = 'Y' OR LAST_RESET_DATE IS NULL THEN TRUNC(SYSDATE) ELSE LAST_RESET_DATE END,
           UPDATED_DATE    = SYSTIMESTAMP
     WHERE SERIES_ID = l_rec.SERIES_ID;

    l_no := l_rec.PREFIX
         || CASE l_rec.RESET_CYCLE
                WHEN 'YEARLY'  THEN TO_CHAR(SYSDATE, 'YYYY') || '-'
                WHEN 'MONTHLY' THEN TO_CHAR(SYSDATE, 'YYMM') || '-'
                WHEN 'DAILY'   THEN TO_CHAR(SYSDATE, 'YYMMDD') || '-'
            END
         || LPAD(l_rec.CURRENT_NO, NVL(l_rec.PAD_LENGTH, 6), '0');
    RETURN l_no;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Number series not configured: ' || p_series_type || ' (branch ' || p_branch_id || ')');
END FN_GET_NEXT_NO;
/

--------------------------------------------------------------------------------
-- Age : '25Y 3M 12D'
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CALCULATE_AGE (
    p_dob     IN DATE,
    p_as_of   IN DATE DEFAULT SYSDATE
) RETURN VARCHAR2 DETERMINISTIC IS
    l_months NUMBER;
    l_years  NUMBER;
    l_mon    NUMBER;
    l_days   NUMBER;
BEGIN
    IF p_dob IS NULL THEN RETURN NULL; END IF;
    l_months := TRUNC(MONTHS_BETWEEN(TRUNC(p_as_of), TRUNC(p_dob)));
    l_years  := TRUNC(l_months / 12);
    l_mon    := MOD(l_months, 12);
    l_days   := TRUNC(p_as_of) - ADD_MONTHS(TRUNC(p_dob), l_months);
    RETURN l_years || 'Y ' || l_mon || 'M ' || l_days || 'D';
END FN_CALCULATE_AGE;
/

--------------------------------------------------------------------------------
-- Available bed count (ward wise; NULL dile sob ward)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_GET_AVAILABLE_BEDS (
    p_ward_id IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt
      FROM HMS_BED
     WHERE BED_STATUS = 'AVAILABLE'
       AND IS_ACTIVE = 'Y'
       AND (p_ward_id IS NULL OR WARD_ID = p_ward_id);
    RETURN l_cnt;
END FN_GET_AVAILABLE_BEDS;
/

--------------------------------------------------------------------------------
-- Patient total due (sob open bill er due - unadjusted advance)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_GET_PATIENT_DUE (
    p_patient_id IN NUMBER
) RETURN NUMBER IS
    l_due     NUMBER := 0;
    l_advance NUMBER := 0;
BEGIN
    SELECT NVL(SUM(DUE_AMOUNT), 0) INTO l_due
      FROM HMS_BILLING
     WHERE PATIENT_ID = p_patient_id
       AND BILL_STATUS IN ('OPEN', 'PARTIAL');

    SELECT NVL(SUM(AMOUNT - ADJUSTED_AMOUNT - REFUNDED_AMOUNT), 0) INTO l_advance
      FROM HMS_PATIENT_ADVANCE
     WHERE PATIENT_ID = p_patient_id
       AND ADVANCE_STATUS = 'ACTIVE';

    RETURN l_due - l_advance;
END FN_GET_PATIENT_DUE;
/

--------------------------------------------------------------------------------
-- Discount amount (percent)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CALCULATE_DISCOUNT (
    p_amount  IN NUMBER,
    p_percent IN NUMBER
) RETURN NUMBER DETERMINISTIC IS
BEGIN
    IF NVL(p_amount, 0) <= 0 OR NVL(p_percent, 0) <= 0 THEN RETURN 0; END IF;
    IF p_percent > 100 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Discount percent cannot exceed 100');
    END IF;
    RETURN ROUND(p_amount * p_percent / 100, 2);
END FN_CALCULATE_DISCOUNT;
/

--------------------------------------------------------------------------------
-- Service rate : category-wise rate thakle seta, na hole BASE_CHARGE
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_GET_SERVICE_RATE (
    p_service_id       IN NUMBER,
    p_branch_id        IN NUMBER,
    p_patient_category IN VARCHAR2 DEFAULT 'GENERAL',
    p_is_emergency     IN VARCHAR2 DEFAULT 'N'
) RETURN NUMBER IS
    l_rate NUMBER;
BEGIN
    BEGIN
        SELECT CHARGE_AMOUNT INTO l_rate
          FROM (SELECT CHARGE_AMOUNT
                  FROM HMS_SERVICE_CHARGE
                 WHERE SERVICE_ID = p_service_id
                   AND BRANCH_ID  = p_branch_id
                   AND PATIENT_CATEGORY = NVL(p_patient_category, 'GENERAL')
                   AND IS_ACTIVE = 'Y'
                   AND TRUNC(SYSDATE) BETWEEN EFFECTIVE_FROM AND NVL(EFFECTIVE_TO, DATE '9999-12-31')
                 ORDER BY EFFECTIVE_FROM DESC)
         WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        SELECT CASE WHEN p_is_emergency = 'Y' THEN NVL(EMERGENCY_CHARGE, BASE_CHARGE) ELSE BASE_CHARGE END
          INTO l_rate
          FROM HMS_SERVICE_MASTER
         WHERE SERVICE_ID = p_service_id;
    END;
    RETURN l_rate;
END FN_GET_SERVICE_RATE;
/

--------------------------------------------------------------------------------
-- Password hash (SHA-256, username as salt). Needs: GRANT EXECUTE ON DBMS_CRYPTO
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_HASH_PASSWORD (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    RETURN RAWTOHEX(
             DBMS_CRYPTO.HASH(
               UTL_I18N.STRING_TO_RAW(UPPER(p_username) || '#HMS#' || p_password, 'AL32UTF8'),
               DBMS_CRYPTO.HASH_SH256));
END FN_HASH_PASSWORD;
/

SHOW ERRORS
