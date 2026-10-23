-- =============================================================================
-- 08_appointment_trigger.sql   (Sprint 4 - Page 30 Appointment Booking)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- Keno trigger? APEX form e `(Auto)` item + process diye number banale
-- unreliable (Employee code e dekha geche). DB trigger sob jaygay ek-i kaj kore.
--   APPOINTMENT_NO : FN_GET_NEXT_NO(branch,'APPOINTMENT')  -> APT-260101-00001
--   SERIAL_NO      : oi doctor + oi din er next serial (1,2,3 ...)
--   PATIENT_NAME   : patient select kora thakle tar full name
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE TRIGGER TRG_APPOINTMENT_BI
BEFORE INSERT ON HMS_APPOINTMENT FOR EACH ROW
BEGIN
    IF :NEW.APPOINTMENT_NO IS NULL OR :NEW.APPOINTMENT_NO = '(Auto)' THEN
        :NEW.APPOINTMENT_NO := FN_GET_NEXT_NO(:NEW.BRANCH_ID, 'APPOINTMENT');
    END IF;

    IF :NEW.SERIAL_NO IS NULL THEN
        SELECT NVL(MAX(SERIAL_NO), 0) + 1
          INTO :NEW.SERIAL_NO
          FROM HMS_APPOINTMENT
         WHERE DOCTOR_ID        = :NEW.DOCTOR_ID
           AND APPOINTMENT_DATE = :NEW.APPOINTMENT_DATE;
    END IF;

    IF :NEW.PATIENT_NAME IS NULL AND :NEW.PATIENT_ID IS NOT NULL THEN
        :NEW.PATIENT_NAME := PKG_PATIENT.get_full_name(:NEW.PATIENT_ID);
    END IF;
END;
/

SELECT object_name, status FROM user_objects WHERE object_name = 'TRG_APPOINTMENT_BI';
