-- Photo (BLOB) upload er jonno MIME/Filename column (APEX Image Upload item e lage)
-- Run as HMS_APP. Barbar run safe (column thakle skip).
DECLARE
  PROCEDURE add_col(p_tab VARCHAR2, p_col VARCHAR2, p_def VARCHAR2) IS
    n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO n FROM USER_TAB_COLUMNS WHERE TABLE_NAME = p_tab AND COLUMN_NAME = p_col;
    IF n = 0 THEN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || p_tab || ' ADD (' || p_col || ' ' || p_def || ')';
      DBMS_OUTPUT.PUT_LINE('Added ' || p_tab || '.' || p_col);
    END IF;
  END;
BEGIN
  add_col('HMS_EMPLOYEE', 'PHOTO_MIME',     'VARCHAR2(100)');
  add_col('HMS_EMPLOYEE', 'PHOTO_FILENAME', 'VARCHAR2(255)');
  add_col('HMS_PATIENT',  'PHOTO_MIME',     'VARCHAR2(100)');
  add_col('HMS_PATIENT',  'PHOTO_FILENAME', 'VARCHAR2(255)');
END;
/
