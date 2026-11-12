-- =============================================================================
-- 10_opd_payment_status_trigger.sql   (Sprint 4 - Page 20 OPD Visit)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- Problem: PKG_BILLING.receive_payment sudhu HMS_BILLING.BILL_STATUS update kore.
--          HMS_OPD_VISIT.PAYMENT_STATUS keu update korto na -> payment nilew UNPAID.
-- Fix    : Bill er status bodlale (OPEN / PARTIAL / PAID) OPD visit er
--          PAYMENT_STATUS auto sync hoy (UNPAID / PARTIAL / PAID).
--          Cancelled / refunded bill e visit status ager moto thake.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE TRIGGER TRG_BILLING_SYNC_OPD_PAY
AFTER INSERT OR UPDATE OF BILL_STATUS ON HMS_BILLING
FOR EACH ROW
WHEN (NEW.OPD_VISIT_ID IS NOT NULL AND NEW.BILL_STATUS IN ('OPEN','PARTIAL','PAID'))
BEGIN
    UPDATE HMS_OPD_VISIT
       SET PAYMENT_STATUS = CASE :NEW.BILL_STATUS
                                WHEN 'PAID'    THEN 'PAID'
                                WHEN 'PARTIAL' THEN 'PARTIAL'
                                ELSE 'UNPAID'
                            END
     WHERE VISIT_ID = :NEW.OPD_VISIT_ID;
END;
/

-- Ager visit gulo thik kore dewa (ekbar chalaleii hobe)
UPDATE HMS_OPD_VISIT v
   SET PAYMENT_STATUS = (SELECT CASE b.BILL_STATUS WHEN 'PAID' THEN 'PAID'
                                                   WHEN 'PARTIAL' THEN 'PARTIAL'
                                                   ELSE 'UNPAID' END
                           FROM HMS_BILLING b
                          WHERE b.OPD_VISIT_ID = v.VISIT_ID
                            AND b.BILL_STATUS IN ('OPEN','PARTIAL','PAID')
                            AND ROWNUM = 1)
 WHERE EXISTS (SELECT 1 FROM HMS_BILLING b
                WHERE b.OPD_VISIT_ID = v.VISIT_ID
                  AND b.BILL_STATUS IN ('OPEN','PARTIAL','PAID'));
COMMIT;
