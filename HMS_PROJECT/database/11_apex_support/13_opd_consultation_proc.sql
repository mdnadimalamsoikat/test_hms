-- =============================================================================
-- 13_opd_consultation_proc.sql   (Sprint 4 - Page 22 Consultation notes)
-- Schema: HMS_APP   |  Re-runnable (CREATE OR REPLACE)
--
-- Doctor er likha notes (complaint, history, exam, diagnosis, advice, follow-up,
-- admission advised) HMS_OPD_CONSULTATION e save kore.
-- Completed / cancelled visit e notes bodlano jabe na.
-- =============================================================================
SET DEFINE OFF

CREATE OR REPLACE PROCEDURE PR_SAVE_OPD_CONSULTATION (
    p_consultation_id   IN NUMBER,
    p_complaint         IN VARCHAR2 DEFAULT NULL,
    p_history           IN VARCHAR2 DEFAULT NULL,
    p_exam              IN VARCHAR2 DEFAULT NULL,
    p_prov_diag         IN VARCHAR2 DEFAULT NULL,
    p_final_diag        IN VARCHAR2 DEFAULT NULL,
    p_advice            IN VARCHAR2 DEFAULT NULL,
    p_followup_date     IN DATE     DEFAULT NULL,
    p_admission_advised IN VARCHAR2 DEFAULT 'N'
) IS
    l_status VARCHAR2(20);
BEGIN
    BEGIN
        SELECT v.VISIT_STATUS
          INTO l_status
          FROM HMS_OPD_CONSULTATION c
          JOIN HMS_OPD_VISIT v ON v.VISIT_ID = c.VISIT_ID
         WHERE c.CONSULTATION_ID = p_consultation_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20310, 'Consultation not found.');
    END;

    IF l_status IN ('COMPLETED', 'CANCELLED') THEN
        RAISE_APPLICATION_ERROR(-20311, 'This visit is already ' || LOWER(l_status) || '. Notes cannot be changed.');
    END IF;
    IF p_followup_date IS NOT NULL AND p_followup_date < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20312, 'Follow-up date cannot be in the past.');
    END IF;

    UPDATE HMS_OPD_CONSULTATION
       SET CHIEF_COMPLAINT       = p_complaint,
           HISTORY_OF_ILLNESS    = p_history,
           EXAMINATION_NOTES     = p_exam,
           PROVISIONAL_DIAGNOSIS = p_prov_diag,
           FINAL_DIAGNOSIS       = p_final_diag,
           ADVICE                = p_advice,
           FOLLOWUP_DATE         = p_followup_date,
           ADMISSION_ADVISED     = NVL(p_admission_advised, 'N')
     WHERE CONSULTATION_ID = p_consultation_id;
END PR_SAVE_OPD_CONSULTATION;
/

SELECT object_name, status FROM user_objects WHERE object_name = 'PR_SAVE_OPD_CONSULTATION';
