/*
================================================================================
 File    : database/06_triggers/TRG_AUDIT_PATIENT.sql
 Run As  : HMS_APP
 Purpose : Patient er important field change hole HMS_AUDIT_TRAIL e log
================================================================================
*/
PROMPT >>> Creating TRG_AUDIT_PATIENT ...
CREATE OR REPLACE TRIGGER TRG_AUDIT_PATIENT
AFTER INSERT OR UPDATE OR DELETE ON HMS_PATIENT
FOR EACH ROW
DECLARE
    l_user VARCHAR2(100) := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
    l_ip   VARCHAR2(50)  := SYS_CONTEXT('USERENV','IP_ADDRESS');

    PROCEDURE log_change (p_id NUMBER, p_col VARCHAR2, p_old VARCHAR2, p_new VARCHAR2) IS
    BEGIN
        IF (p_old IS NULL AND p_new IS NOT NULL) OR (p_old IS NOT NULL AND p_new IS NULL) OR p_old <> p_new THEN
            INSERT INTO HMS_AUDIT_TRAIL (TABLE_NAME, RECORD_ID, ACTION_TYPE, COLUMN_NAME, OLD_VALUE, NEW_VALUE,
                                         ACTION_BY, IP_ADDRESS, MODULE_NAME)
            VALUES ('HMS_PATIENT', p_id, 'UPDATE', p_col, p_old, p_new, l_user, l_ip, 'PATIENT');
        END IF;
    END;
BEGIN
    IF INSERTING THEN
        INSERT INTO HMS_AUDIT_TRAIL (TABLE_NAME, RECORD_ID, ACTION_TYPE, NEW_VALUE, ACTION_BY, IP_ADDRESS, MODULE_NAME)
        VALUES ('HMS_PATIENT', :NEW.PATIENT_ID, 'INSERT', :NEW.MRN || ' - ' || :NEW.FIRST_NAME, l_user, l_ip, 'PATIENT');
    ELSIF DELETING THEN
        INSERT INTO HMS_AUDIT_TRAIL (TABLE_NAME, RECORD_ID, ACTION_TYPE, OLD_VALUE, ACTION_BY, IP_ADDRESS, MODULE_NAME)
        VALUES ('HMS_PATIENT', :OLD.PATIENT_ID, 'DELETE', :OLD.MRN || ' - ' || :OLD.FIRST_NAME, l_user, l_ip, 'PATIENT');
    ELSE
        log_change(:NEW.PATIENT_ID, 'FIRST_NAME',       :OLD.FIRST_NAME,       :NEW.FIRST_NAME);
        log_change(:NEW.PATIENT_ID, 'LAST_NAME',        :OLD.LAST_NAME,        :NEW.LAST_NAME);
        log_change(:NEW.PATIENT_ID, 'GENDER',           :OLD.GENDER,           :NEW.GENDER);
        log_change(:NEW.PATIENT_ID, 'DATE_OF_BIRTH',    TO_CHAR(:OLD.DATE_OF_BIRTH,'YYYY-MM-DD'), TO_CHAR(:NEW.DATE_OF_BIRTH,'YYYY-MM-DD'));
        log_change(:NEW.PATIENT_ID, 'PHONE_PRIMARY',    :OLD.PHONE_PRIMARY,    :NEW.PHONE_PRIMARY);
        log_change(:NEW.PATIENT_ID, 'NID_NUMBER',       :OLD.NID_NUMBER,       :NEW.NID_NUMBER);
        log_change(:NEW.PATIENT_ID, 'BLOOD_GROUP',      :OLD.BLOOD_GROUP,      :NEW.BLOOD_GROUP);
        log_change(:NEW.PATIENT_ID, 'PATIENT_CATEGORY', :OLD.PATIENT_CATEGORY, :NEW.PATIENT_CATEGORY);
        log_change(:NEW.PATIENT_ID, 'IS_ACTIVE',        :OLD.IS_ACTIVE,        :NEW.IS_ACTIVE);
    END IF;
END;
/
SHOW ERRORS
