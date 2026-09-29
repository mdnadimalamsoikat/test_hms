/*
 File   : database/11_apex_support/04_pharmacy_cart.sql
 Run As : HMS_APP
 Purpose: POS (Page 60) e DRAFT sale theke line remove -> stock ferot + line inactive
          (return_item completed sale er jonno; draft cart er jonno eta)
*/
SET DEFINE OFF
CREATE OR REPLACE PROCEDURE PR_PHARMA_REMOVE_LINE (p_sale_dtl_id IN NUMBER) IS
    l_dtl    HMS_PHARMA_SALE_DTL%ROWTYPE;
    l_status VARCHAR2(20);
    l_store  NUMBER;
BEGIN
    SELECT * INTO l_dtl FROM HMS_PHARMA_SALE_DTL WHERE SALE_DTL_ID = p_sale_dtl_id AND IS_ACTIVE = 'Y' FOR UPDATE;
    SELECT SALE_STATUS, STORE_ID INTO l_status, l_store FROM HMS_PHARMA_SALE WHERE SALE_ID = l_dtl.SALE_ID;
    IF l_status <> 'DRAFT' THEN
        RAISE_APPLICATION_ERROR(-20405, 'Shudhu DRAFT sale theke line remove kora jay. Complete sale hole Return (Page 65) use korun.');
    END IF;

    UPDATE HMS_PHARMA_STOCK SET QTY_AVAILABLE = QTY_AVAILABLE + l_dtl.QUANTITY WHERE STOCK_ID = l_dtl.STOCK_ID;
    UPDATE HMS_PHARMA_SALE_DTL SET IS_ACTIVE = 'N' WHERE SALE_DTL_ID = p_sale_dtl_id;

    INSERT INTO HMS_PHARMA_TRANSACTION (STORE_ID, ITEM_ID, STOCK_ID, BATCH_NO, TXN_TYPE, TXN_QTY, REF_TYPE, REF_ID)
    VALUES (l_store, l_dtl.ITEM_ID, l_dtl.STOCK_ID, l_dtl.BATCH_NO, 'SALE_RETURN', l_dtl.QUANTITY, 'CART_REMOVE', p_sale_dtl_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20406, 'Line pawa jay nai ba age-i remove hoyeche.');
END PR_PHARMA_REMOVE_LINE;
/
SHOW ERRORS PROCEDURE PR_PHARMA_REMOVE_LINE
