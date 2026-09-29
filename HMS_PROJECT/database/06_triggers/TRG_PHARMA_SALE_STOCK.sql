/*
================================================================================
 File    : database/06_triggers/TRG_PHARMA_SALE_STOCK.sql
 Run As  : HMS_APP
 Purpose : Sale detail insert -> stock minus + stock ledger entry
================================================================================
*/
PROMPT >>> Creating TRG_PHARMA_SALE_STOCK ...
CREATE OR REPLACE TRIGGER TRG_PHARMA_SALE_STOCK
AFTER INSERT ON HMS_PHARMA_SALE_DTL
FOR EACH ROW
DECLARE
    l_store NUMBER;
BEGIN
    UPDATE HMS_PHARMA_STOCK
       SET QTY_AVAILABLE = QTY_AVAILABLE - :NEW.QUANTITY
     WHERE STOCK_ID = :NEW.STOCK_ID
       AND QTY_AVAILABLE >= :NEW.QUANTITY
    RETURNING STORE_ID INTO l_store;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20410, 'Insufficient stock (stock_id ' || :NEW.STOCK_ID || ')');
    END IF;

    INSERT INTO HMS_PHARMA_TRANSACTION (STORE_ID, ITEM_ID, STOCK_ID, BATCH_NO, TXN_TYPE, TXN_QTY, REF_TYPE, REF_ID)
    VALUES (l_store, :NEW.ITEM_ID, :NEW.STOCK_ID, :NEW.BATCH_NO, 'SALE', -:NEW.QUANTITY, 'SALE_DTL', :NEW.SALE_DTL_ID);
END;
/
SHOW ERRORS
