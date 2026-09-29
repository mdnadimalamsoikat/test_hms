/*
================================================================================
 File    : database/06_triggers/TRG_BILLING_CANCEL_CHECK.sql
 Run As  : HMS_APP
 Purpose : Bill delete kora jabe na (cancel korte hobe) + cancel reason mandatory
================================================================================
*/
PROMPT >>> Creating TRG_BILLING_CANCEL_CHECK ...
CREATE OR REPLACE TRIGGER TRG_BILLING_CANCEL_CHECK
BEFORE DELETE OR UPDATE OF BILL_STATUS ON HMS_BILLING
FOR EACH ROW
BEGIN
    IF DELETING THEN
        RAISE_APPLICATION_ERROR(-20120, 'Bill delete allowed na. Cancel korun.');
    END IF;
    IF :NEW.BILL_STATUS = 'CANCELLED' AND :NEW.CANCEL_REASON IS NULL THEN
        RAISE_APPLICATION_ERROR(-20121, 'Cancel reason dorkar.');
    END IF;
END;
/
SHOW ERRORS
