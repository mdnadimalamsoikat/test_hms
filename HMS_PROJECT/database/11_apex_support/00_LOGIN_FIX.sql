/*
================================================================================
 File    : database/11_apex_support/00_LOGIN_FIX.sql
 Run As  : HMS_APP   (SQL Developer / SQL*Plus)
 Keno    : APEX e ADMIN diye login hocche na.
           Karon: APEX Authentication Scheme e deya
             - PKG_AUTH.AUTHENTICATE          (function)  ->  ache / INVALID?
             - PKG_APP_SESSION.POST_AUTH       (procedure) ->  DB te NAI
           Post-Auth procedure na thakle password thik holeo login FAIL hoy.
 Ei script:
   1) Dorkari sob object banay (PKG_AUTH, PKG_APP_SESSION, LOV view...)
   2) ADMIN user na thakle banay, thakle password reset + unlock kore
   3) SQL theke login test kore -> "LOGIN TEST : SUCCESS" dekhale APEX eo hobe
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

PROMPT ===== 1. Dependency check =====
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME IN ('FN_HASH_PASSWORD','FN_CURRENT_USER','PKG_AUTH','PKG_APP_SESSION',
                       'HMS_USER','HMS_ROLE','HMS_USER_ROLE','HMS_LOGIN_HISTORY')
 ORDER BY 1, 2;

-- DBMS_CRYPTO grant ache kina (na thakle FN_HASH_PASSWORD INVALID thakbe)
SELECT COUNT(*) AS DBMS_CRYPTO_GRANT_1_HOLE_OK
  FROM ALL_TAB_PRIVS WHERE TABLE_NAME = 'DBMS_CRYPTO' AND GRANTEE IN (USER, 'PUBLIC');

PROMPT ===== 2. PKG_AUTH + PKG_APP_SESSION + APEX helper objects =====
@@../05_packages/PKG_AUTH.sql
@@01_apex_support.sql

PROMPT ===== 3. ADMIN user ensure (password = Admin@12345) =====
DECLARE
    l_cnt    NUMBER;
    l_id     NUMBER;
    l_branch NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM HMS_USER WHERE USERNAME = 'ADMIN';
    IF l_cnt = 0 THEN
        SELECT MIN(BRANCH_ID) INTO l_branch FROM HMS_BRANCH;
        l_id := PKG_AUTH.create_user('ADMIN', 'Admin@12345', l_branch, NULL, 'SUPER_ADMIN');
        DBMS_OUTPUT.PUT_LINE('ADMIN user created. USER_ID = ' || l_id);
    ELSE
        PKG_AUTH.reset_password('ADMIN', 'Admin@12345');
        DBMS_OUTPUT.PUT_LINE('ADMIN password reset done.');
    END IF;

    UPDATE HMS_USER
       SET IS_LOCKED = 'N', IS_ACTIVE = 'Y', FAILED_ATTEMPTS = 0, FORCE_PWD_CHANGE = 'N'
     WHERE USERNAME = 'ADMIN';

    -- SUPER_ADMIN role assign ache kina
    INSERT INTO HMS_USER_ROLE (USER_ID, ROLE_ID)
    SELECT u.USER_ID, r.ROLE_ID
      FROM HMS_USER u, HMS_ROLE r
     WHERE u.USERNAME = 'ADMIN' AND r.ROLE_CODE = 'SUPER_ADMIN'
       AND NOT EXISTS (SELECT 1 FROM HMS_USER_ROLE x WHERE x.USER_ID = u.USER_ID AND x.ROLE_ID = r.ROLE_ID);
    COMMIT;
END;
/

PROMPT ===== 4. LOGIN TEST (APEX chara) =====
DECLARE
    l_ok BOOLEAN;
BEGIN
    l_ok := PKG_AUTH.authenticate('ADMIN', 'Admin@12345');
    DBMS_OUTPUT.PUT_LINE(CASE WHEN l_ok THEN 'LOGIN TEST : SUCCESS  -> ekhon APEX e login korun'
                              ELSE 'LOGIN TEST : FAILED   -> niche HMS_LOGIN_HISTORY dekhun' END);
END;
/

SELECT USERNAME, IS_LOCKED, IS_ACTIVE, FAILED_ATTEMPTS, FORCE_PWD_CHANGE FROM HMS_USER WHERE USERNAME = 'ADMIN';
SELECT * FROM (SELECT USERNAME, LOGIN_STATUS, CREATED_DATE FROM HMS_LOGIN_HISTORY ORDER BY 3 DESC) WHERE ROWNUM <= 5;

PROMPT ===== 5. INVALID object (0 row = OK) =====
SELECT OBJECT_NAME, OBJECT_TYPE FROM USER_OBJECTS WHERE STATUS = 'INVALID';
