/*
================================================================================
 File    : database/11_apex_support/02_pkg_lab.sql
 Run As  : HMS_APP
 Purpose : Lab workflow (Order -> Sample -> Result -> Verify) - APEX Sprint 7
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_LAB ...

CREATE OR REPLACE PACKAGE PKG_LAB AS
    -- Order header + bill (LAB bill) banay; order_id return
    FUNCTION create_order (
        p_branch_id    IN NUMBER,
        p_patient_id   IN NUMBER,
        p_source       IN VARCHAR2 DEFAULT 'OPD',
        p_opd_visit_id IN NUMBER   DEFAULT NULL,
        p_admission_id IN NUMBER   DEFAULT NULL,
        p_ref_doctor   IN NUMBER   DEFAULT NULL,
        p_priority     IN VARCHAR2 DEFAULT 'ROUTINE',
        p_notes        IN VARCHAR2 DEFAULT NULL,
        p_order_no     OUT VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE add_test (p_order_id IN NUMBER, p_service_id IN NUMBER, p_discount IN NUMBER DEFAULT 0);
    -- Apex shuttle theke "12:15:18" string dile ek sathe sob test
    PROCEDURE add_tests (p_order_id IN NUMBER, p_service_ids IN VARCHAR2);

    FUNCTION collect_sample (p_order_dtl_id IN NUMBER, p_sample_type IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

    -- Result entry: flag (H/L/HH/LL) auto hisab
    PROCEDURE save_result (p_order_dtl_id IN NUMBER, p_parameter_id IN NUMBER, p_value IN VARCHAR2);
    PROCEDURE verify_test  (p_order_dtl_id IN NUMBER);
END PKG_LAB;
/

CREATE OR REPLACE PACKAGE BODY PKG_LAB AS

    FUNCTION emp_id RETURN NUMBER IS
    BEGIN
        RETURN TO_NUMBER(V('G_EMPLOYEE_ID'));
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
    END;

    PROCEDURE refresh_order (p_order_id IN NUMBER) IS
    BEGIN
        UPDATE HMS_INVESTIGATION_ORDER o
           SET (TOTAL_AMOUNT, DISCOUNT_AMOUNT, NET_AMOUNT) =
               (SELECT NVL(SUM(CHARGE_AMOUNT),0), NVL(SUM(DISCOUNT_AMOUNT),0), NVL(SUM(NET_AMOUNT),0)
                  FROM HMS_INVESTIGATION_ORDER_DTL d
                 WHERE d.ORDER_ID = o.ORDER_ID AND d.ITEM_STATUS <> 'CANCELLED'),
               ORDER_STATUS =
               CASE WHEN NOT EXISTS (SELECT 1 FROM HMS_INVESTIGATION_ORDER_DTL d
                                      WHERE d.ORDER_ID = o.ORDER_ID
                                        AND d.ITEM_STATUS NOT IN ('VERIFIED','DELIVERED','CANCELLED'))
                    THEN 'COMPLETED'
                    WHEN EXISTS (SELECT 1 FROM HMS_INVESTIGATION_ORDER_DTL d
                                  WHERE d.ORDER_ID = o.ORDER_ID AND d.ITEM_STATUS IN ('VERIFIED','DELIVERED'))
                    THEN 'PARTIAL' ELSE 'ORDERED' END
         WHERE ORDER_ID = p_order_id;
    END refresh_order;

    ----------------------------------------------------------------------------
    FUNCTION create_order (
        p_branch_id IN NUMBER, p_patient_id IN NUMBER, p_source IN VARCHAR2 DEFAULT 'OPD',
        p_opd_visit_id IN NUMBER DEFAULT NULL, p_admission_id IN NUMBER DEFAULT NULL,
        p_ref_doctor IN NUMBER DEFAULT NULL, p_priority IN VARCHAR2 DEFAULT 'ROUTINE',
        p_notes IN VARCHAR2 DEFAULT NULL, p_order_no OUT VARCHAR2
    ) RETURN NUMBER IS
        l_id NUMBER;
    BEGIN
        p_order_no := FN_GET_NEXT_NO(p_branch_id, 'LAB_ORDER');
        INSERT INTO HMS_INVESTIGATION_ORDER
               (ORDER_NO, BRANCH_ID, PATIENT_ID, OPD_VISIT_ID, ADMISSION_ID, ORDER_SOURCE,
                REFERRED_DOCTOR_ID, PRIORITY, CLINICAL_NOTES)
        VALUES (p_order_no, p_branch_id, p_patient_id, p_opd_visit_id, p_admission_id, p_source,
                p_ref_doctor, p_priority, p_notes)
        RETURNING ORDER_ID INTO l_id;
        RETURN l_id;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_LAB.create_order', 'patient=' || p_patient_id);
        RAISE;
    END create_order;

    ----------------------------------------------------------------------------
    PROCEDURE add_test (p_order_id IN NUMBER, p_service_id IN NUMBER, p_discount IN NUMBER DEFAULT 0) IS
        l_ord  HMS_INVESTIGATION_ORDER%ROWTYPE;
        l_svc  HMS_SERVICE_MASTER%ROWTYPE;
        l_rate NUMBER;
        l_bill NUMBER;
        l_dtl  NUMBER;
    BEGIN
        SELECT * INTO l_ord FROM HMS_INVESTIGATION_ORDER WHERE ORDER_ID = p_order_id;
        SELECT * INTO l_svc FROM HMS_SERVICE_MASTER  WHERE SERVICE_ID = p_service_id;
        l_rate := CASE WHEN l_ord.PRIORITY = 'STAT' THEN NVL(l_svc.EMERGENCY_CHARGE, l_svc.BASE_CHARGE)
                       ELSE l_svc.BASE_CHARGE END;

        INSERT INTO HMS_INVESTIGATION_ORDER_DTL
               (ORDER_ID, SERVICE_ID, SERVICE_NAME, CHARGE_AMOUNT, DISCOUNT_AMOUNT, NET_AMOUNT)
        VALUES (p_order_id, p_service_id, l_svc.SERVICE_NAME, l_rate, NVL(p_discount,0), l_rate - NVL(p_discount,0))
        RETURNING ORDER_DTL_ID INTO l_dtl;

        -- IPD hole IPD running bill e, na hole LAB bill e
        IF l_ord.ADMISSION_ID IS NOT NULL THEN
            l_bill := PKG_IPD.get_ipd_bill_id(l_ord.ADMISSION_ID);
        ELSE
            BEGIN
                SELECT BILL_ID INTO l_bill FROM HMS_BILLING
                 WHERE BILL_TYPE = 'LAB' AND REMARKS = l_ord.ORDER_NO AND BILL_STATUS <> 'CANCELLED';
            EXCEPTION WHEN NO_DATA_FOUND THEN
                l_bill := PKG_BILLING.create_bill(l_ord.BRANCH_ID, l_ord.PATIENT_ID, 'LAB', l_ord.OPD_VISIT_ID);
                UPDATE HMS_BILLING SET REMARKS = l_ord.ORDER_NO WHERE BILL_ID = l_bill;
            END;
        END IF;
        PKG_BILLING.add_bill_item(l_bill, p_service_id, l_svc.SERVICE_NAME, 1, l_rate, NVL(p_discount,0),
                                  l_ord.REFERRED_DOCTOR_ID, 'LAB', l_dtl);
        refresh_order(p_order_id);
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_LAB.add_test', 'order=' || p_order_id || ' svc=' || p_service_id);
        RAISE;
    END add_test;

    PROCEDURE add_tests (p_order_id IN NUMBER, p_service_ids IN VARCHAR2) IS
    BEGIN
        FOR r IN (SELECT TO_NUMBER(COLUMN_VALUE) SID
                    FROM TABLE(APEX_STRING.SPLIT(p_service_ids, ':'))) LOOP
            add_test(p_order_id, r.SID);
        END LOOP;
    END add_tests;

    ----------------------------------------------------------------------------
    FUNCTION collect_sample (p_order_dtl_id IN NUMBER, p_sample_type IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
        l_no     VARCHAR2(30);
        l_order  NUMBER;
        l_branch NUMBER;
        l_type   VARCHAR2(50);
        l_emp    NUMBER := emp_id;   -- private function SQL e chole na (PLS-00231)
    BEGIN
        SELECT d.ORDER_ID, o.BRANCH_ID, NVL(p_sample_type, s.SAMPLE_TYPE)
          INTO l_order, l_branch, l_type
          FROM HMS_INVESTIGATION_ORDER_DTL d
          JOIN HMS_INVESTIGATION_ORDER o ON o.ORDER_ID = d.ORDER_ID
          JOIN HMS_SERVICE_MASTER s      ON s.SERVICE_ID = d.SERVICE_ID
         WHERE d.ORDER_DTL_ID = p_order_dtl_id;

        l_no := FN_GET_NEXT_NO(l_branch, 'SAMPLE');
        INSERT INTO HMS_LAB_SAMPLE (SAMPLE_NO, ORDER_ID, ORDER_DTL_ID, SAMPLE_TYPE, COLLECTED_BY,
                                    COLLECTION_TIME, SAMPLE_STATUS)
        VALUES (l_no, l_order, p_order_dtl_id, l_type, l_emp, SYSTIMESTAMP, 'COLLECTED');

        UPDATE HMS_INVESTIGATION_ORDER_DTL SET ITEM_STATUS = 'SAMPLE_COLLECTED'
         WHERE ORDER_DTL_ID = p_order_dtl_id AND ITEM_STATUS = 'ORDERED';
        RETURN l_no;
    END collect_sample;

    ----------------------------------------------------------------------------
    PROCEDURE save_result (p_order_dtl_id IN NUMBER, p_parameter_id IN NUMBER, p_value IN VARCHAR2) IS
        l_num    NUMBER;
        l_gender VARCHAR2(10);
        l_days   NUMBER;
        l_rng    HMS_LAB_REFERENCE_RANGE%ROWTYPE;
        l_flag   VARCHAR2(2) := 'N';
        l_unit   VARCHAR2(50);
        l_ref    VARCHAR2(200);
        l_sample NUMBER;
        l_emp    NUMBER := emp_id;
    BEGIN
        BEGIN l_num := TO_NUMBER(TRIM(p_value)); EXCEPTION WHEN VALUE_ERROR THEN l_num := NULL; END;

        SELECT p.GENDER, TRUNC(SYSDATE) - NVL(p.DATE_OF_BIRTH, ADD_MONTHS(TRUNC(SYSDATE), -12 * NVL(p.AGE_YEARS, 30)))
          INTO l_gender, l_days
          FROM HMS_INVESTIGATION_ORDER_DTL d
          JOIN HMS_INVESTIGATION_ORDER o ON o.ORDER_ID = d.ORDER_ID
          JOIN HMS_PATIENT p             ON p.PATIENT_ID = o.PATIENT_ID
         WHERE d.ORDER_DTL_ID = p_order_dtl_id;

        SELECT UNIT INTO l_unit FROM HMS_LAB_PARAMETER WHERE PARAMETER_ID = p_parameter_id;

        BEGIN
            SELECT * INTO l_rng FROM (
                SELECT * FROM HMS_LAB_REFERENCE_RANGE
                 WHERE PARAMETER_ID = p_parameter_id AND IS_ACTIVE = 'Y'
                   AND GENDER IN (l_gender, 'ALL')
                   AND l_days BETWEEN AGE_FROM_DAYS AND AGE_TO_DAYS
                 ORDER BY CASE WHEN GENDER = 'ALL' THEN 2 ELSE 1 END)
             WHERE ROWNUM = 1;
            l_ref := NVL(l_rng.NORMAL_TEXT, l_rng.MIN_VALUE || ' - ' || l_rng.MAX_VALUE);
            IF l_num IS NOT NULL THEN
                l_flag := CASE WHEN l_num < l_rng.CRITICAL_LOW  THEN 'LL'
                               WHEN l_num > l_rng.CRITICAL_HIGH THEN 'HH'
                               WHEN l_num < l_rng.MIN_VALUE     THEN 'L'
                               WHEN l_num > l_rng.MAX_VALUE     THEN 'H'
                               ELSE 'N' END;
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
        END;

        SELECT MAX(SAMPLE_ID) INTO l_sample FROM HMS_LAB_SAMPLE WHERE ORDER_DTL_ID = p_order_dtl_id;

        MERGE INTO HMS_LAB_RESULT r
        USING (SELECT p_order_dtl_id DTL, p_parameter_id PRM FROM DUAL) x
           ON (r.ORDER_DTL_ID = x.DTL AND r.PARAMETER_ID = x.PRM)
         WHEN MATCHED THEN UPDATE SET
              RESULT_VALUE = p_value, RESULT_NUMERIC = l_num, RESULT_FLAG = l_flag,
              IS_ABNORMAL = CASE WHEN l_flag IN ('L','H','LL','HH') THEN 'Y' ELSE 'N' END,
              IS_CRITICAL = CASE WHEN l_flag IN ('LL','HH') THEN 'Y' ELSE 'N' END,
              ENTERED_BY = l_emp, ENTERED_TIME = SYSTIMESTAMP,
              RESULT_STATUS = CASE WHEN RESULT_STATUS = 'VERIFIED' THEN 'AMENDED' ELSE 'ENTERED' END
         WHEN NOT MATCHED THEN INSERT
              (ORDER_DTL_ID, SAMPLE_ID, PARAMETER_ID, RESULT_VALUE, RESULT_NUMERIC, UNIT, REFERENCE_RANGE,
               IS_ABNORMAL, IS_CRITICAL, RESULT_FLAG, ENTERED_BY)
              VALUES (p_order_dtl_id, l_sample, p_parameter_id, p_value, l_num, l_unit, l_ref,
                      CASE WHEN l_flag IN ('L','H','LL','HH') THEN 'Y' ELSE 'N' END,
                      CASE WHEN l_flag IN ('LL','HH') THEN 'Y' ELSE 'N' END, l_flag, l_emp);

        UPDATE HMS_INVESTIGATION_ORDER_DTL SET ITEM_STATUS = 'RESULT_ENTERED'
         WHERE ORDER_DTL_ID = p_order_dtl_id AND ITEM_STATUS IN ('ORDERED','SAMPLE_COLLECTED','IN_PROCESS');
    END save_result;

    ----------------------------------------------------------------------------
    PROCEDURE verify_test (p_order_dtl_id IN NUMBER) IS
        l_order NUMBER;
        l_emp   NUMBER := emp_id;
    BEGIN
        UPDATE HMS_LAB_RESULT SET RESULT_STATUS = 'VERIFIED', VERIFIED_BY = l_emp, VERIFIED_TIME = SYSTIMESTAMP
         WHERE ORDER_DTL_ID = p_order_dtl_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20401, 'Result entry chara verify kora jabe na');
        END IF;
        UPDATE HMS_INVESTIGATION_ORDER_DTL
           SET ITEM_STATUS = 'VERIFIED', VERIFIED_BY = l_emp, VERIFIED_DATE = SYSTIMESTAMP,
               REPORTED_BY = NVL(REPORTED_BY, l_emp), REPORTED_DATE = NVL(REPORTED_DATE, SYSTIMESTAMP)
         WHERE ORDER_DTL_ID = p_order_dtl_id
        RETURNING ORDER_ID INTO l_order;
        refresh_order(l_order);
    END verify_test;

END PKG_LAB;
/
SHOW ERRORS PACKAGE BODY PKG_LAB
