-- =============================================================================
-- 15_opd_complete_proc.sql   (Sprint 4 - Page 22 Complete Visit)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- PR_COMPLETE_OPD_VISIT : consultation shesh kore visit COMPLETED kore.
--   Check: visit IN_CONSULTATION, complaint + (provisional/final) diagnosis ache.
--   CONSULTATION_END set kore, PKG_OPD.complete_visit (visit + appointment) call kore.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PROCEDURE PR_COMPLETE_OPD_VISIT (
    p_visit_id IN NUMBER
) IS
    l_status    HMS_OPD_VISIT.VISIT_STATUS%TYPE;
    l_cons_id   NUMBER;
    l_complaint HMS_OPD_CONSULTATION.CHIEF_COMPLAINT%TYPE;
    l_prov      HMS_OPD_CONSULTATION.PROVISIONAL_DIAGNOSIS%TYPE;
    l_final     HMS_OPD_CONSULTATION.FINAL_DIAGNOSIS%TYPE;
BEGIN
    BEGIN
        SELECT VISIT_STATUS INTO l_status FROM HMS_OPD_VISIT WHERE VISIT_ID = p_visit_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20340, 'Visit not found.');
    END;

    IF l_status IN ('COMPLETED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20341, 'This visit is already ' || LOWER(l_status) || '.');
    END IF;
    IF l_status <> 'IN_CONSULTATION' THEN
        RAISE_APPLICATION_ERROR(-20342, 'Only a visit that is in consultation can be completed.');
    END IF;

    BEGIN
        SELECT CONSULTATION_ID, CHIEF_COMPLAINT, PROVISIONAL_DIAGNOSIS, FINAL_DIAGNOSIS
          INTO l_cons_id, l_complaint, l_prov, l_final
          FROM (SELECT * FROM HMS_OPD_CONSULTATION
                 WHERE VISIT_ID = p_visit_id ORDER BY CONSULTATION_ID DESC)
         WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20343, 'Consultation notes not found.');
    END;

    IF TRIM(l_complaint) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20344, 'Please enter the chief complaint before completing the visit.');
    END IF;
    IF TRIM(l_prov) IS NULL AND TRIM(l_final) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20345, 'Please enter a provisional or final diagnosis before completing the visit.');
    END IF;

    UPDATE HMS_OPD_CONSULTATION SET CONSULTATION_END = SYSTIMESTAMP WHERE CONSULTATION_ID = l_cons_id;
    PKG_OPD.complete_visit(p_visit_id);
END PR_COMPLETE_OPD_VISIT;
/

SELECT object_name, status FROM user_objects WHERE object_name = 'PR_COMPLETE_OPD_VISIT';
