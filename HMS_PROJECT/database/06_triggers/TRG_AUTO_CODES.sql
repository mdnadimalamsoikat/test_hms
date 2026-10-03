/*
================================================================================
 File    : TRG_AUTO_CODES.sql
 Purpose : Employee / Doctor code DB theke auto (APEX process er upor nirbhor kore na)
           - HMS_EMPLOYEE.EMPLOYEE_CODE : NULL ba '(Auto)' hole  FN_GET_NEXT_NO(branch,'EMPLOYEE')  -> EMP-00001
           - HMS_DOCTOR.DOCTOR_CODE     : NULL ba '(Auto)' hole  'DR-' || employee code
 Benefit : Insert rollback hole number o rollback (gap hoy na). Cancel e number kharach hoy na.
 Run As  : HMS_APP  (SQL Developer > Run Script F5). Barbar run safe.
================================================================================
*/
SET DEFINE OFF

CREATE OR REPLACE TRIGGER TRG_EMPLOYEE_CODE_BI
BEFORE INSERT ON HMS_EMPLOYEE FOR EACH ROW
BEGIN
    IF :NEW.EMPLOYEE_CODE IS NULL OR :NEW.EMPLOYEE_CODE = '(Auto)' THEN
        :NEW.EMPLOYEE_CODE := FN_GET_NEXT_NO(:NEW.BRANCH_ID, 'EMPLOYEE');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_DOCTOR_CODE_BI
BEFORE INSERT ON HMS_DOCTOR FOR EACH ROW
DECLARE
    l_emp_code HMS_EMPLOYEE.EMPLOYEE_CODE%TYPE;
BEGIN
    IF :NEW.DOCTOR_CODE IS NULL OR :NEW.DOCTOR_CODE = '(Auto)' THEN
        SELECT EMPLOYEE_CODE INTO l_emp_code FROM HMS_EMPLOYEE WHERE EMPLOYEE_ID = :NEW.EMPLOYEE_ID;
        :NEW.DOCTOR_CODE := 'DR-' || l_emp_code;
    END IF;
END;
/

-- Age jei row e '(Auto)' boshe geche ta thik kore din (ekbar):
UPDATE HMS_EMPLOYEE
   SET EMPLOYEE_CODE = FN_GET_NEXT_NO(BRANCH_ID, 'EMPLOYEE')
 WHERE EMPLOYEE_CODE = '(Auto)';
COMMIT;

SELECT EMPLOYEE_ID, EMPLOYEE_CODE, FIRST_NAME FROM HMS_EMPLOYEE ORDER BY EMPLOYEE_ID;
