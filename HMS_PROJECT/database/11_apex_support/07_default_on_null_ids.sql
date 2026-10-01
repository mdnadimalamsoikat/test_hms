-- ============================================================================
-- FIX: ORA-01400 cannot insert NULL into (...._ID)  — APEX Form/IG theke insert e
-- ID column e NULL pathay, ar  DEFAULT SEQ_x.NEXTVAL  tokhon kaj kore na.
-- Solution: DEFAULT ON NULL SEQ_x.NEXTVAL  (NULL gele o sequence number boshe).
--
-- Run as HMS_APP (SQL Developer ▸ Run Script F5). Barbar run safe.
-- ============================================================================
SET SERVEROUTPUT ON
DECLARE
  l_def   VARCHAR2(4000);
  l_cnt   NUMBER := 0;
BEGIN
  FOR r IN (SELECT table_name, column_name, data_default, default_on_null
              FROM user_tab_columns
             WHERE table_name LIKE 'HMS\_%' ESCAPE '\'
               AND data_default IS NOT NULL
               AND default_on_null = 'NO'
             ORDER BY table_name, column_id)
  LOOP
    l_def := TRIM(SUBSTR(r.data_default, 1, 4000));
    IF UPPER(l_def) LIKE '%.NEXTVAL%' THEN
      BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE ' || r.table_name ||
                          ' MODIFY (' || r.column_name || ' DEFAULT ON NULL ' || l_def || ')';
        l_cnt := l_cnt + 1;
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SKIP ' || r.table_name || '.' || r.column_name || ' : ' || SQLERRM);
      END;
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Done. Columns changed: ' || l_cnt);
END;
/

-- Check (HMS_DEPARTMENT.DEPT_ID er DEFAULT_ON_NULL = YES hobe):
SELECT table_name, column_name, default_on_null
  FROM user_tab_columns
 WHERE table_name = 'HMS_DEPARTMENT' AND column_name = 'DEPT_ID';
