-- ============================================================================
-- FIX: ORA-01400 cannot insert NULL into (HMS_xxx.DEPT_ID / CREATED_DATE / IS_ACTIVE ...)
--
-- Karon : APEX Form/Grid insert e protita column er jonno item thakle NULL pathay.
--         Column e  DEFAULT ...  thakleo NULL explicit gele DEFAULT kaj kore NA.
-- Fix   : DEFAULT ON NULL ...  (NULL ashle o default boshe).
--
-- Ei script ja kore (sob HMS_ table e):
--   1) ID column  DEFAULT SEQ_x.NEXTVAL            -> DEFAULT ON NULL
--   2) CREATED_DATE / CREATED_BY                   -> DEFAULT ON NULL
--   3) Jekono NOT NULL column jar DEFAULT ache (IS_ACTIVE 'Y' ...) -> DEFAULT ON NULL
--
-- Run as HMS_APP (SQL Developer > Run Script F5). Barbar run safe.
-- ============================================================================
SET SERVEROUTPUT ON
DECLARE
  l_def   VARCHAR2(4000);
  l_cnt   NUMBER := 0;
BEGIN
  FOR r IN (SELECT table_name, column_name, data_default, nullable
              FROM user_tab_columns
             WHERE table_name LIKE 'HMS\_%' ESCAPE '\'
               AND data_default IS NOT NULL
               AND default_on_null = 'NO'
               AND identity_column = 'NO'
               AND virtual_column  = 'NO'
               AND table_name IN (SELECT table_name FROM user_tables)
             ORDER BY table_name, column_id)
  LOOP
    l_def := TRIM(SUBSTR(r.data_default, 1, 4000));
    IF UPPER(l_def) LIKE '%.NEXTVAL%'
       OR r.column_name IN ('CREATED_DATE', 'CREATED_BY')
       OR r.nullable = 'N'
    THEN
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

-- Check: HMS_DEPARTMENT er sob column e DEFAULT_ON_NULL = YES dekhabe
SELECT table_name, column_name, default_on_null
  FROM user_tab_columns
 WHERE table_name = 'HMS_DEPARTMENT' AND data_default IS NOT NULL;
