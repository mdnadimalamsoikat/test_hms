/*
================================================================================
 File    : database/05_packages/PKG_PHARMACY.sql
 Run As  : HMS_APP
 Purpose : GRN posting (stock in), Sale (FEFO batch), Sale return
 Note    : Sale detail insert holei TRG_PHARMA_SALE_STOCK stock komabe
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_PHARMACY ...

CREATE OR REPLACE PACKAGE PKG_PHARMACY AS

    PROCEDURE post_grn (p_grn_id IN NUMBER);

    FUNCTION create_sale (
        p_branch_id    IN NUMBER,
        p_store_id     IN NUMBER,
        p_sale_type    IN VARCHAR2 DEFAULT 'OTC',
        p_patient_id   IN NUMBER   DEFAULT NULL,
        p_admission_id IN NUMBER   DEFAULT NULL,
        p_customer     IN VARCHAR2 DEFAULT NULL,
        p_phone        IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    -- FEFO: je batch age expire hobe seta age bikri
    PROCEDURE add_sale_item (
        p_sale_id  IN NUMBER,
        p_item_id  IN NUMBER,
        p_quantity IN NUMBER,
        p_discount IN NUMBER DEFAULT 0
    );

    PROCEDURE finalize_sale (
        p_sale_id      IN NUMBER,
        p_paid_amount  IN NUMBER,
        p_payment_mode IN VARCHAR2 DEFAULT 'CASH'
    );

    PROCEDURE return_item (
        p_sale_dtl_id IN NUMBER,
        p_qty         IN NUMBER,
        p_reason      IN VARCHAR2
    );

    FUNCTION get_stock (p_store_id IN NUMBER, p_item_id IN NUMBER) RETURN NUMBER;

END PKG_PHARMACY;
/

CREATE OR REPLACE PACKAGE BODY PKG_PHARMACY AS

    FUNCTION get_stock (p_store_id IN NUMBER, p_item_id IN NUMBER) RETURN NUMBER IS
        l_qty NUMBER;
    BEGIN
        SELECT NVL(SUM(QTY_AVAILABLE), 0) INTO l_qty
          FROM HMS_PHARMA_STOCK
         WHERE STORE_ID = p_store_id AND ITEM_ID = p_item_id
           AND EXPIRY_DATE > TRUNC(SYSDATE) AND IS_ACTIVE = 'Y';
        RETURN l_qty;
    END get_stock;

    ----------------------------------------------------------------------------
    PROCEDURE post_grn (p_grn_id IN NUMBER) IS
        l_grn HMS_PHARMA_GRN%ROWTYPE;
        l_stock_id NUMBER;
    BEGIN
        SELECT * INTO l_grn FROM HMS_PHARMA_GRN WHERE GRN_ID = p_grn_id FOR UPDATE;
        IF l_grn.GRN_STATUS <> 'DRAFT' THEN
            RAISE_APPLICATION_ERROR(-20401, 'GRN already ' || l_grn.GRN_STATUS);
        END IF;

        FOR d IN (SELECT * FROM HMS_PHARMA_GRN_DTL WHERE GRN_ID = p_grn_id AND IS_ACTIVE = 'Y') LOOP
            MERGE INTO HMS_PHARMA_STOCK s
            USING (SELECT l_grn.STORE_ID STORE_ID, d.ITEM_ID ITEM_ID, d.BATCH_NO BATCH_NO FROM DUAL) x
               ON (s.STORE_ID = x.STORE_ID AND s.ITEM_ID = x.ITEM_ID AND s.BATCH_NO = x.BATCH_NO)
            WHEN MATCHED THEN
                UPDATE SET s.QTY_AVAILABLE = s.QTY_AVAILABLE + d.QUANTITY + NVL(d.FREE_QTY, 0),
                           s.UNIT_COST = d.UNIT_COST, s.MRP = d.MRP, s.EXPIRY_DATE = d.EXPIRY_DATE,
                           s.UPDATED_DATE = SYSTIMESTAMP
            WHEN NOT MATCHED THEN
                INSERT (STORE_ID, ITEM_ID, BATCH_NO, EXPIRY_DATE, QTY_AVAILABLE, UNIT_COST, MRP)
                VALUES (l_grn.STORE_ID, d.ITEM_ID, d.BATCH_NO, d.EXPIRY_DATE,
                        d.QUANTITY + NVL(d.FREE_QTY, 0), d.UNIT_COST, d.MRP);

            SELECT STOCK_ID INTO l_stock_id FROM HMS_PHARMA_STOCK
             WHERE STORE_ID = l_grn.STORE_ID AND ITEM_ID = d.ITEM_ID AND BATCH_NO = d.BATCH_NO;

            INSERT INTO HMS_PHARMA_TRANSACTION (STORE_ID, ITEM_ID, STOCK_ID, BATCH_NO, TXN_TYPE, TXN_QTY, REF_TYPE, REF_ID)
            VALUES (l_grn.STORE_ID, d.ITEM_ID, l_stock_id, d.BATCH_NO, 'GRN',
                    d.QUANTITY + NVL(d.FREE_QTY, 0), 'GRN', p_grn_id);

            IF l_grn.PO_ID IS NOT NULL THEN
                UPDATE HMS_PHARMA_PO_DTL SET RECEIVED_QTY = NVL(RECEIVED_QTY, 0) + d.QUANTITY
                 WHERE PO_ID = l_grn.PO_ID AND ITEM_ID = d.ITEM_ID;
            END IF;

            UPDATE HMS_PHARMA_ITEM SET PURCHASE_PRICE = d.UNIT_COST, MRP = NVL(d.MRP, MRP)
             WHERE ITEM_ID = d.ITEM_ID;
        END LOOP;

        UPDATE HMS_PHARMA_GRN SET GRN_STATUS = 'POSTED' WHERE GRN_ID = p_grn_id;

        IF l_grn.PO_ID IS NOT NULL THEN
            UPDATE HMS_PHARMA_PURCHASE_ORDER po
               SET PO_STATUS = CASE WHEN NOT EXISTS (SELECT 1 FROM HMS_PHARMA_PO_DTL
                                                      WHERE PO_ID = po.PO_ID AND RECEIVED_QTY < ORDER_QTY)
                                    THEN 'RECEIVED' ELSE 'PARTIAL' END
             WHERE PO_ID = l_grn.PO_ID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        PR_LOG_ERROR('PKG_PHARMACY.post_grn', 'grn=' || p_grn_id);
        RAISE;
    END post_grn;

    ----------------------------------------------------------------------------
    FUNCTION create_sale (
        p_branch_id    IN NUMBER,
        p_store_id     IN NUMBER,
        p_sale_type    IN VARCHAR2 DEFAULT 'OTC',
        p_patient_id   IN NUMBER   DEFAULT NULL,
        p_admission_id IN NUMBER   DEFAULT NULL,
        p_customer     IN VARCHAR2 DEFAULT NULL,
        p_phone        IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        l_id NUMBER;
        l_no VARCHAR2(50) := FN_GET_NEXT_NO(p_branch_id, 'PHARMA_SALE');
    BEGIN
        INSERT INTO HMS_PHARMA_SALE (SALE_NO, BRANCH_ID, STORE_ID, PATIENT_ID, ADMISSION_ID,
                                     CUSTOMER_NAME, CUSTOMER_PHONE, SALE_TYPE, SALE_STATUS)
        VALUES (l_no, p_branch_id, p_store_id, p_patient_id, p_admission_id,
                p_customer, p_phone, NVL(p_sale_type, 'OTC'), 'DRAFT')
        RETURNING SALE_ID INTO l_id;
        RETURN l_id;
    END create_sale;

    ----------------------------------------------------------------------------
    PROCEDURE add_sale_item (
        p_sale_id  IN NUMBER,
        p_item_id  IN NUMBER,
        p_quantity IN NUMBER,
        p_discount IN NUMBER DEFAULT 0
    ) IS
        l_store  NUMBER;
        l_status VARCHAR2(20);
        l_need   NUMBER := p_quantity;
        l_take   NUMBER;
        l_first  BOOLEAN := TRUE;
        l_disc   NUMBER;
    BEGIN
        SELECT STORE_ID, SALE_STATUS INTO l_store, l_status FROM HMS_PHARMA_SALE WHERE SALE_ID = p_sale_id;
        IF l_status <> 'DRAFT' THEN
            RAISE_APPLICATION_ERROR(-20402, 'Sale already finalized.');
        END IF;
        IF get_stock(l_store, p_item_id) < p_quantity THEN
            RAISE_APPLICATION_ERROR(-20403, 'Stock nai. Available: ' || get_stock(l_store, p_item_id));
        END IF;

        FOR s IN (SELECT STOCK_ID, BATCH_NO, QTY_AVAILABLE, MRP
                    FROM HMS_PHARMA_STOCK
                   WHERE STORE_ID = l_store AND ITEM_ID = p_item_id
                     AND QTY_AVAILABLE > 0 AND EXPIRY_DATE > TRUNC(SYSDATE) AND IS_ACTIVE = 'Y'
                   ORDER BY EXPIRY_DATE, STOCK_ID
                     FOR UPDATE)
        LOOP
            EXIT WHEN l_need <= 0;
            l_take := LEAST(s.QTY_AVAILABLE, l_need);
            l_disc := CASE WHEN l_first THEN NVL(p_discount, 0) ELSE 0 END;  -- BOOLEAN SQL er baire
            INSERT INTO HMS_PHARMA_SALE_DTL (SALE_ID, ITEM_ID, STOCK_ID, BATCH_NO, QUANTITY, UNIT_PRICE,
                                             DISCOUNT_AMOUNT, LINE_TOTAL)
            VALUES (p_sale_id, p_item_id, s.STOCK_ID, s.BATCH_NO, l_take, s.MRP,
                    l_disc,
                    l_take * s.MRP - l_disc);
            -- stock deduction -> TRG_PHARMA_SALE_STOCK
            l_first := FALSE;
            l_need  := l_need - l_take;
        END LOOP;
    END add_sale_item;

    ----------------------------------------------------------------------------
    PROCEDURE finalize_sale (
        p_sale_id      IN NUMBER,
        p_paid_amount  IN NUMBER,
        p_payment_mode IN VARCHAR2 DEFAULT 'CASH'
    ) IS
        l_gross NUMBER; l_disc NUMBER; l_type VARCHAR2(20); l_adm NUMBER;
        l_branch NUMBER; l_patient NUMBER; l_bill_id NUMBER; l_sale_no VARCHAR2(30);
    BEGIN
        SELECT NVL(SUM(QUANTITY * UNIT_PRICE), 0), NVL(SUM(DISCOUNT_AMOUNT), 0)
          INTO l_gross, l_disc
          FROM HMS_PHARMA_SALE_DTL WHERE SALE_ID = p_sale_id AND IS_ACTIVE = 'Y';

        SELECT SALE_TYPE, ADMISSION_ID, BRANCH_ID, PATIENT_ID, SALE_NO
          INTO l_type, l_adm, l_branch, l_patient, l_sale_no
          FROM HMS_PHARMA_SALE WHERE SALE_ID = p_sale_id;

        UPDATE HMS_PHARMA_SALE
           SET GROSS_AMOUNT = l_gross, DISCOUNT_AMOUNT = l_disc, NET_AMOUNT = l_gross - l_disc,
               PAID_AMOUNT  = CASE WHEN l_type = 'IPD' THEN 0 ELSE NVL(p_paid_amount, 0) END,
               PAYMENT_MODE = p_payment_mode,
               SALE_STATUS  = CASE WHEN l_type = 'IPD' THEN 'IPD_CREDIT' ELSE 'COMPLETED' END
         WHERE SALE_ID = p_sale_id;

        -- IPD patient hole medicine bill IPD running bill e jabe
        IF l_type = 'IPD' AND l_adm IS NOT NULL THEN
            l_bill_id := PKG_IPD.get_ipd_bill_id(l_adm);
            PKG_BILLING.add_bill_item(l_bill_id, NULL, 'Pharmacy - ' || l_sale_no, 1, l_gross - l_disc,
                                      0, NULL, 'PHARMA_SALE', p_sale_id);
        END IF;
    END finalize_sale;

    ----------------------------------------------------------------------------
    PROCEDURE return_item (
        p_sale_dtl_id IN NUMBER,
        p_qty         IN NUMBER,
        p_reason      IN VARCHAR2
    ) IS
        l_dtl      HMS_PHARMA_SALE_DTL%ROWTYPE;
        l_returned NUMBER;
        l_store    NUMBER;
        l_branch   NUMBER;
        l_no       VARCHAR2(50);
    BEGIN
        SELECT * INTO l_dtl FROM HMS_PHARMA_SALE_DTL WHERE SALE_DTL_ID = p_sale_dtl_id;
        SELECT NVL(SUM(RETURN_QTY), 0) INTO l_returned FROM HMS_PHARMA_SALE_RETURN WHERE SALE_DTL_ID = p_sale_dtl_id;
        IF l_returned + p_qty > l_dtl.QUANTITY THEN
            RAISE_APPLICATION_ERROR(-20404, 'Return qty sale qty er beshi.');
        END IF;
        SELECT STORE_ID, BRANCH_ID INTO l_store, l_branch FROM HMS_PHARMA_SALE WHERE SALE_ID = l_dtl.SALE_ID;

        l_no := FN_GET_NEXT_NO(l_branch, 'PHARMA_RETURN');
        INSERT INTO HMS_PHARMA_SALE_RETURN (RETURN_NO, SALE_ID, SALE_DTL_ID, RETURN_QTY, REFUND_AMOUNT, RETURN_REASON)
        VALUES (l_no, l_dtl.SALE_ID, p_sale_dtl_id, p_qty,
                ROUND(p_qty * l_dtl.UNIT_PRICE, 2), p_reason);

        UPDATE HMS_PHARMA_STOCK SET QTY_AVAILABLE = QTY_AVAILABLE + p_qty WHERE STOCK_ID = l_dtl.STOCK_ID;

        INSERT INTO HMS_PHARMA_TRANSACTION (STORE_ID, ITEM_ID, STOCK_ID, BATCH_NO, TXN_TYPE, TXN_QTY, REF_TYPE, REF_ID)
        VALUES (l_store, l_dtl.ITEM_ID, l_dtl.STOCK_ID, l_dtl.BATCH_NO, 'SALE_RETURN', p_qty, 'SALE_DTL', p_sale_dtl_id);
    END return_item;

END PKG_PHARMACY;
/
SHOW ERRORS
