/*
================================================================================
 File    : database/05_packages/PKG_BILLING.sql
 Run As  : HMS_APP
 Purpose : Bill create, item add, recalc, discount, payment, advance
 Note    : PKG_OPD / PKG_IPD eta call kore - tai eta AGE compile korte hobe
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_BILLING ...

CREATE OR REPLACE PACKAGE PKG_BILLING AS

    FUNCTION create_bill (
        p_branch_id    IN NUMBER,
        p_patient_id   IN NUMBER,
        p_bill_type    IN VARCHAR2,
        p_opd_visit_id IN NUMBER DEFAULT NULL,
        p_admission_id IN NUMBER DEFAULT NULL,
        p_policy_id    IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE add_bill_item (
        p_bill_id      IN NUMBER,
        p_service_id   IN NUMBER,
        p_item_desc    IN VARCHAR2 DEFAULT NULL,
        p_quantity     IN NUMBER   DEFAULT 1,
        p_unit_price   IN NUMBER   DEFAULT NULL,   -- NULL dile rate auto
        p_discount     IN NUMBER   DEFAULT 0,
        p_doctor_id    IN NUMBER   DEFAULT NULL,
        p_ref_type     IN VARCHAR2 DEFAULT NULL,
        p_ref_id       IN NUMBER   DEFAULT NULL
    );

    PROCEDURE recalc_bill (p_bill_id IN NUMBER);

    PROCEDURE apply_discount (
        p_bill_id     IN NUMBER,
        p_amount      IN NUMBER,
        p_reason      IN VARCHAR2,
        p_approved_by IN NUMBER
    );

    FUNCTION receive_payment (
        p_bill_id      IN NUMBER,
        p_amount       IN NUMBER,
        p_payment_mode IN VARCHAR2,
        p_txn_ref      IN VARCHAR2 DEFAULT NULL,
        p_cashier_id   IN NUMBER   DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION collect_advance (
        p_patient_id   IN NUMBER,
        p_admission_id IN NUMBER,
        p_amount       IN NUMBER,
        p_payment_mode IN VARCHAR2,
        p_txn_ref      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE adjust_advance (p_bill_id IN NUMBER);

    PROCEDURE cancel_bill (p_bill_id IN NUMBER, p_reason IN VARCHAR2);

END PKG_BILLING;
/

CREATE OR REPLACE PACKAGE BODY PKG_BILLING AS

    ----------------------------------------------------------------------------
    FUNCTION create_bill (
        p_branch_id    IN NUMBER,
        p_patient_id   IN NUMBER,
        p_bill_type    IN VARCHAR2,
        p_opd_visit_id IN NUMBER DEFAULT NULL,
        p_admission_id IN NUMBER DEFAULT NULL,
        p_policy_id    IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        l_bill_id NUMBER;
        l_no      VARCHAR2(50) := FN_GET_NEXT_NO(p_branch_id, 'BILL');
    BEGIN
        INSERT INTO HMS_BILLING (BILL_NO, BRANCH_ID, PATIENT_ID, BILL_TYPE,
                                 OPD_VISIT_ID, ADMISSION_ID, POLICY_ID, BILL_STATUS)
        VALUES (l_no, p_branch_id, p_patient_id, p_bill_type,
                p_opd_visit_id, p_admission_id, p_policy_id, 'OPEN')
        RETURNING BILL_ID INTO l_bill_id;
        RETURN l_bill_id;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_BILLING.create_bill', 'patient=' || p_patient_id);
        RAISE;
    END create_bill;

    ----------------------------------------------------------------------------
    PROCEDURE add_bill_item (
        p_bill_id      IN NUMBER,
        p_service_id   IN NUMBER,
        p_item_desc    IN VARCHAR2 DEFAULT NULL,
        p_quantity     IN NUMBER   DEFAULT 1,
        p_unit_price   IN NUMBER   DEFAULT NULL,
        p_discount     IN NUMBER   DEFAULT 0,
        p_doctor_id    IN NUMBER   DEFAULT NULL,
        p_ref_type     IN VARCHAR2 DEFAULT NULL,
        p_ref_id       IN NUMBER   DEFAULT NULL
    ) IS
        l_bill   HMS_BILLING%ROWTYPE;
        l_cat    HMS_PATIENT.PATIENT_CATEGORY%TYPE;
        l_price  NUMBER;
        l_desc   VARCHAR2(300);
        l_tax    NUMBER := 0;
        l_gross  NUMBER;
        l_vat    NUMBER;
    BEGIN
        SELECT * INTO l_bill FROM HMS_BILLING WHERE BILL_ID = p_bill_id FOR UPDATE;
        IF l_bill.BILL_STATUS IN ('PAID', 'CANCELLED', 'REFUNDED') THEN
            RAISE_APPLICATION_ERROR(-20101, 'Bill ' || l_bill.BILL_NO || ' is ' || l_bill.BILL_STATUS || '. Item add kora jabe na.');
        END IF;

        SELECT PATIENT_CATEGORY INTO l_cat FROM HMS_PATIENT WHERE PATIENT_ID = l_bill.PATIENT_ID;

        IF p_service_id IS NOT NULL THEN
            SELECT SERVICE_NAME, CASE WHEN TAX_APPLICABLE = 'Y' THEN NVL(TAX_PERCENT, 0) ELSE 0 END
              INTO l_desc, l_tax
              FROM HMS_SERVICE_MASTER WHERE SERVICE_ID = p_service_id;
            l_price := NVL(p_unit_price, FN_GET_SERVICE_RATE(p_service_id, l_bill.BRANCH_ID, l_cat));
        ELSE
            l_price := NVL(p_unit_price, 0);
        END IF;

        l_gross := ROUND(NVL(p_quantity, 1) * l_price, 2);
        l_vat   := ROUND((l_gross - NVL(p_discount, 0)) * l_tax / 100, 2);

        INSERT INTO HMS_BILLING_DTL (BILL_ID, SERVICE_ID, ITEM_DESC, REF_TYPE, REF_ID, DOCTOR_ID,
                                     QUANTITY, UNIT_PRICE, GROSS_AMOUNT, DISCOUNT_AMOUNT, VAT_AMOUNT, NET_AMOUNT)
        VALUES (p_bill_id, p_service_id, NVL(p_item_desc, l_desc), p_ref_type, p_ref_id, p_doctor_id,
                NVL(p_quantity, 1), l_price, l_gross, NVL(p_discount, 0), l_vat,
                l_gross - NVL(p_discount, 0) + l_vat);

        recalc_bill(p_bill_id);
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_BILLING.add_bill_item', 'bill=' || p_bill_id || ' svc=' || p_service_id);
        RAISE;
    END add_bill_item;

    ----------------------------------------------------------------------------
    PROCEDURE recalc_bill (p_bill_id IN NUMBER) IS
        l_gross NUMBER; l_disc NUMBER; l_vat NUMBER; l_paid NUMBER;
        l_hdr_disc NUMBER; l_ins NUMBER;
        l_net NUMBER; l_payable NUMBER; l_status VARCHAR2(20);
    BEGIN
        SELECT NVL(SUM(GROSS_AMOUNT), 0), NVL(SUM(DISCOUNT_AMOUNT), 0), NVL(SUM(VAT_AMOUNT), 0)
          INTO l_gross, l_disc, l_vat
          FROM HMS_BILLING_DTL
         WHERE BILL_ID = p_bill_id AND IS_ACTIVE = 'Y';

        SELECT NVL(SUM(CASE WHEN RECEIPT_TYPE = 'REFUND' THEN -AMOUNT ELSE AMOUNT END), 0)
          INTO l_paid
          FROM HMS_PAYMENT_RECEIPT
         WHERE BILL_ID = p_bill_id AND RECEIPT_STATUS = 'VALID';

        -- header-level extra discount (apply_discount diye set hoy)
        SELECT NVL(HEADER_DISCOUNT, 0), NVL(INSURANCE_AMOUNT, 0)
          INTO l_hdr_disc, l_ins
          FROM HMS_BILLING WHERE BILL_ID = p_bill_id;

        l_net     := l_gross - l_disc - l_hdr_disc + l_vat;
        l_payable := l_net - l_ins;
        l_status  := CASE WHEN l_paid <= 0 THEN 'OPEN'
                          WHEN l_paid >= l_payable THEN 'PAID'
                          ELSE 'PARTIAL' END;

        UPDATE HMS_BILLING
           SET GROSS_AMOUNT    = l_gross,
               DISCOUNT_AMOUNT = l_disc + l_hdr_disc,
               VAT_AMOUNT      = l_vat,
               NET_AMOUNT      = l_net,
               PATIENT_PAYABLE = l_payable,
               PAID_AMOUNT     = l_paid,
               DUE_AMOUNT      = GREATEST(l_payable - l_paid, 0),
               BILL_STATUS     = CASE WHEN BILL_STATUS IN ('CANCELLED','REFUNDED') THEN BILL_STATUS ELSE l_status END
         WHERE BILL_ID = p_bill_id;
    END recalc_bill;

    ----------------------------------------------------------------------------
    PROCEDURE apply_discount (
        p_bill_id     IN NUMBER,
        p_amount      IN NUMBER,
        p_reason      IN VARCHAR2,
        p_approved_by IN NUMBER
    ) IS
        l_line_disc NUMBER;
        l_gross     NUMBER;
    BEGIN
        IF p_reason IS NULL OR p_approved_by IS NULL THEN
            RAISE_APPLICATION_ERROR(-20102, 'Discount reason ebong approver dorkar.');
        END IF;
        SELECT NVL(SUM(DISCOUNT_AMOUNT), 0), NVL(SUM(GROSS_AMOUNT), 0)
          INTO l_line_disc, l_gross
          FROM HMS_BILLING_DTL WHERE BILL_ID = p_bill_id AND IS_ACTIVE = 'Y';
        IF l_line_disc + p_amount > l_gross THEN
            RAISE_APPLICATION_ERROR(-20103, 'Discount gross amount er beshi hote parbe na.');
        END IF;
        UPDATE HMS_BILLING
           SET HEADER_DISCOUNT      = p_amount,
               DISCOUNT_REASON      = p_reason,
               DISCOUNT_APPROVED_BY = p_approved_by
         WHERE BILL_ID = p_bill_id;
        recalc_bill(p_bill_id);
    END apply_discount;

    ----------------------------------------------------------------------------
    FUNCTION receive_payment (
        p_bill_id      IN NUMBER,
        p_amount       IN NUMBER,
        p_payment_mode IN VARCHAR2,
        p_txn_ref      IN VARCHAR2 DEFAULT NULL,
        p_cashier_id   IN NUMBER   DEFAULT NULL
    ) RETURN NUMBER IS
        l_bill       HMS_BILLING%ROWTYPE;
        l_receipt_id NUMBER;
        l_no         VARCHAR2(50);
    BEGIN
        IF NVL(p_amount, 0) <= 0 THEN
            RAISE_APPLICATION_ERROR(-20104, 'Payment amount must be > 0');
        END IF;
        SELECT * INTO l_bill FROM HMS_BILLING WHERE BILL_ID = p_bill_id FOR UPDATE;
        IF l_bill.BILL_STATUS = 'CANCELLED' THEN
            RAISE_APPLICATION_ERROR(-20105, 'Cancelled bill e payment neya jabe na.');
        END IF;
        IF p_amount > l_bill.DUE_AMOUNT THEN
            RAISE_APPLICATION_ERROR(-20106, 'Payment (' || p_amount || ') due (' || l_bill.DUE_AMOUNT || ') er beshi.');
        END IF;

        l_no := FN_GET_NEXT_NO(l_bill.BRANCH_ID, 'RECEIPT');
        INSERT INTO HMS_PAYMENT_RECEIPT (RECEIPT_NO, BRANCH_ID, BILL_ID, PATIENT_ID, RECEIPT_TYPE,
                                         AMOUNT, PAYMENT_MODE, TRANSACTION_REF, CASHIER_ID)
        VALUES (l_no, l_bill.BRANCH_ID, p_bill_id, l_bill.PATIENT_ID,
                'PAYMENT', p_amount, p_payment_mode, p_txn_ref, p_cashier_id)
        RETURNING RECEIPT_ID INTO l_receipt_id;

        recalc_bill(p_bill_id);
        RETURN l_receipt_id;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_BILLING.receive_payment', 'bill=' || p_bill_id || ' amt=' || p_amount);
        RAISE;
    END receive_payment;

    ----------------------------------------------------------------------------
    FUNCTION collect_advance (
        p_patient_id   IN NUMBER,
        p_admission_id IN NUMBER,
        p_amount       IN NUMBER,
        p_payment_mode IN VARCHAR2,
        p_txn_ref      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        l_branch NUMBER;
        l_id     NUMBER;
        l_no     VARCHAR2(50);
    BEGIN
        SELECT BRANCH_ID INTO l_branch FROM HMS_PATIENT WHERE PATIENT_ID = p_patient_id;
        l_no := FN_GET_NEXT_NO(l_branch, 'ADVANCE');
        INSERT INTO HMS_PATIENT_ADVANCE (ADVANCE_NO, PATIENT_ID, ADMISSION_ID, AMOUNT, PAYMENT_MODE, TRANSACTION_REF)
        VALUES (l_no, p_patient_id, p_admission_id, p_amount, p_payment_mode, p_txn_ref)
        RETURNING ADVANCE_ID INTO l_id;
        RETURN l_id;
    END collect_advance;

    ----------------------------------------------------------------------------
    -- Patient er active advance theke bill er due adjust kora
    ----------------------------------------------------------------------------
    PROCEDURE adjust_advance (p_bill_id IN NUMBER) IS
        l_bill   HMS_BILLING%ROWTYPE;
        l_due    NUMBER;
        l_use    NUMBER;
        l_no     VARCHAR2(50);
    BEGIN
        recalc_bill(p_bill_id);
        SELECT * INTO l_bill FROM HMS_BILLING WHERE BILL_ID = p_bill_id FOR UPDATE;
        l_due := l_bill.DUE_AMOUNT;

        FOR a IN (SELECT ADVANCE_ID, AMOUNT - ADJUSTED_AMOUNT - REFUNDED_AMOUNT AS BAL
                    FROM HMS_PATIENT_ADVANCE
                   WHERE PATIENT_ID = l_bill.PATIENT_ID
                     AND ADVANCE_STATUS = 'ACTIVE'
                     AND (l_bill.ADMISSION_ID IS NULL OR ADMISSION_ID IS NULL OR ADMISSION_ID = l_bill.ADMISSION_ID)
                   ORDER BY ADVANCE_DATE
                     FOR UPDATE)
        LOOP
            EXIT WHEN l_due <= 0;
            l_use := LEAST(a.BAL, l_due);
            IF l_use > 0 THEN
                UPDATE HMS_PATIENT_ADVANCE
                   SET ADJUSTED_AMOUNT = ADJUSTED_AMOUNT + l_use,
                       ADVANCE_STATUS  = CASE WHEN AMOUNT - (ADJUSTED_AMOUNT + l_use) - REFUNDED_AMOUNT <= 0
                                              THEN 'ADJUSTED' ELSE 'ACTIVE' END
                 WHERE ADVANCE_ID = a.ADVANCE_ID;

                l_no := FN_GET_NEXT_NO(l_bill.BRANCH_ID, 'RECEIPT');
                INSERT INTO HMS_PAYMENT_RECEIPT (RECEIPT_NO, BRANCH_ID, BILL_ID, PATIENT_ID, RECEIPT_TYPE,
                                                 AMOUNT, PAYMENT_MODE, TRANSACTION_REF)
                VALUES (l_no, l_bill.BRANCH_ID, p_bill_id, l_bill.PATIENT_ID,
                        'ADJUSTMENT', l_use, 'ADVANCE', 'ADV#' || a.ADVANCE_ID);
                l_due := l_due - l_use;
            END IF;
        END LOOP;
        recalc_bill(p_bill_id);
    END adjust_advance;

    ----------------------------------------------------------------------------
    PROCEDURE cancel_bill (p_bill_id IN NUMBER, p_reason IN VARCHAR2) IS
        l_paid NUMBER;
    BEGIN
        SELECT PAID_AMOUNT INTO l_paid FROM HMS_BILLING WHERE BILL_ID = p_bill_id FOR UPDATE;
        IF l_paid > 0 THEN
            RAISE_APPLICATION_ERROR(-20107, 'Payment ache - age refund korun, tarpor cancel.');
        END IF;
        UPDATE HMS_BILLING SET BILL_STATUS = 'CANCELLED', CANCEL_REASON = p_reason WHERE BILL_ID = p_bill_id;
    END cancel_bill;

END PKG_BILLING;
/
SHOW ERRORS
