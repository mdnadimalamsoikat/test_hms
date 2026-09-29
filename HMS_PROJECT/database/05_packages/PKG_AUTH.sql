/*
================================================================================
 File    : database/05_packages/PKG_AUTH.sql
 Run As  : HMS_APP
 Purpose : APEX Custom Authentication + user create / password change + menu permission
 APEX    : Shared Components > Authentication Schemes > Create > Custom
           Authentication Function Name :  PKG_AUTH.AUTHENTICATE
================================================================================
*/
SET DEFINE OFF
PROMPT >>> Creating PKG_AUTH ...

CREATE OR REPLACE PACKAGE PKG_AUTH AS

    -- APEX custom auth signature: (p_username, p_password) RETURN BOOLEAN
    FUNCTION authenticate (p_username IN VARCHAR2, p_password IN VARCHAR2) RETURN BOOLEAN;

    FUNCTION create_user (
        p_username    IN VARCHAR2,
        p_password    IN VARCHAR2,
        p_branch_id   IN NUMBER,
        p_employee_id IN NUMBER   DEFAULT NULL,
        p_role_code   IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE change_password (p_username IN VARCHAR2, p_old IN VARCHAR2, p_new IN VARCHAR2);
    PROCEDURE reset_password  (p_username IN VARCHAR2, p_new IN VARCHAR2);

    -- APEX Authorization Scheme e use: PKG_AUTH.has_permission(:APP_USER,'OPD','ADD')
    FUNCTION has_permission (p_username IN VARCHAR2, p_module_code IN VARCHAR2, p_action IN VARCHAR2 DEFAULT 'VIEW')
        RETURN BOOLEAN;

    FUNCTION has_role (p_username IN VARCHAR2, p_role_code IN VARCHAR2) RETURN BOOLEAN;

END PKG_AUTH;
/

CREATE OR REPLACE PACKAGE BODY PKG_AUTH AS

    c_max_attempts CONSTANT NUMBER := 5;

    PROCEDURE log_login (p_user_id NUMBER, p_username VARCHAR2, p_status VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO HMS_LOGIN_HISTORY (USER_ID, USERNAME, LOGIN_STATUS, IP_ADDRESS, BROWSER_INFO)
        VALUES (p_user_id, p_username, p_status,
                OWA_UTIL.GET_CGI_ENV('REMOTE_ADDR'), SUBSTR(OWA_UTIL.GET_CGI_ENV('HTTP_USER_AGENT'), 1, 500));
        COMMIT;
    EXCEPTION WHEN OTHERS THEN   -- OWA context na thakle (SQL Developer theke test)
        INSERT INTO HMS_LOGIN_HISTORY (USER_ID, USERNAME, LOGIN_STATUS) VALUES (p_user_id, p_username, p_status);
        COMMIT;
    END log_login;

    PROCEDURE set_fail (p_user_id NUMBER) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE HMS_USER
           SET FAILED_ATTEMPTS = FAILED_ATTEMPTS + 1,
               IS_LOCKED = CASE WHEN FAILED_ATTEMPTS + 1 >= c_max_attempts THEN 'Y' ELSE IS_LOCKED END
         WHERE USER_ID = p_user_id;
        COMMIT;
    END set_fail;

    PROCEDURE set_success (p_user_id NUMBER) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE HMS_USER SET FAILED_ATTEMPTS = 0, LAST_LOGIN = SYSTIMESTAMP WHERE USER_ID = p_user_id;
        COMMIT;
    END set_success;

    ----------------------------------------------------------------------------
    FUNCTION authenticate (p_username IN VARCHAR2, p_password IN VARCHAR2) RETURN BOOLEAN IS
        l_user HMS_USER%ROWTYPE;
    BEGIN
        SELECT * INTO l_user FROM HMS_USER WHERE USERNAME = UPPER(TRIM(p_username));

        IF l_user.IS_ACTIVE = 'N' OR l_user.IS_LOCKED = 'Y' THEN
            log_login(l_user.USER_ID, l_user.USERNAME, 'LOCKED');
            RETURN FALSE;
        END IF;

        IF l_user.PASSWORD_HASH = FN_HASH_PASSWORD(l_user.USERNAME, p_password) THEN
            set_success(l_user.USER_ID);
            log_login(l_user.USER_ID, l_user.USERNAME, 'SUCCESS');
            RETURN TRUE;
        END IF;

        set_fail(l_user.USER_ID);
        log_login(l_user.USER_ID, l_user.USERNAME, 'FAILED');
        RETURN FALSE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        log_login(NULL, UPPER(p_username), 'FAILED');
        RETURN FALSE;
    END authenticate;

    ----------------------------------------------------------------------------
    FUNCTION create_user (
        p_username    IN VARCHAR2,
        p_password    IN VARCHAR2,
        p_branch_id   IN NUMBER,
        p_employee_id IN NUMBER   DEFAULT NULL,
        p_role_code   IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        l_id NUMBER;
        l_un VARCHAR2(100) := UPPER(TRIM(p_username));
    BEGIN
        IF LENGTH(p_password) < 8 THEN
            RAISE_APPLICATION_ERROR(-20501, 'Password minimum 8 character.');
        END IF;
        INSERT INTO HMS_USER (EMPLOYEE_ID, BRANCH_ID, USERNAME, PASSWORD_HASH, PASSWORD_CHANGED_ON)
        VALUES (p_employee_id, p_branch_id, l_un, FN_HASH_PASSWORD(l_un, p_password), SYSDATE)
        RETURNING USER_ID INTO l_id;

        IF p_role_code IS NOT NULL THEN
            INSERT INTO HMS_USER_ROLE (USER_ID, ROLE_ID)
            SELECT l_id, ROLE_ID FROM HMS_ROLE WHERE ROLE_CODE = UPPER(p_role_code);
        END IF;
        RETURN l_id;
    END create_user;

    ----------------------------------------------------------------------------
    PROCEDURE change_password (p_username IN VARCHAR2, p_old IN VARCHAR2, p_new IN VARCHAR2) IS
        l_un VARCHAR2(100) := UPPER(TRIM(p_username));
    BEGIN
        IF NOT authenticate(l_un, p_old) THEN
            RAISE_APPLICATION_ERROR(-20502, 'Old password vul.');
        END IF;
        reset_password(l_un, p_new);
    END change_password;

    PROCEDURE reset_password (p_username IN VARCHAR2, p_new IN VARCHAR2) IS
        l_un VARCHAR2(100) := UPPER(TRIM(p_username));
    BEGIN
        IF LENGTH(p_new) < 8 THEN
            RAISE_APPLICATION_ERROR(-20501, 'Password minimum 8 character.');
        END IF;
        UPDATE HMS_USER
           SET PASSWORD_HASH = FN_HASH_PASSWORD(l_un, p_new),
               PASSWORD_CHANGED_ON = SYSDATE, FAILED_ATTEMPTS = 0, IS_LOCKED = 'N', FORCE_PWD_CHANGE = 'N'
         WHERE USERNAME = l_un;
    END reset_password;

    ----------------------------------------------------------------------------
    FUNCTION has_permission (p_username IN VARCHAR2, p_module_code IN VARCHAR2, p_action IN VARCHAR2 DEFAULT 'VIEW')
        RETURN BOOLEAN IS
        l_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_cnt
          FROM HMS_USER u
          JOIN HMS_USER_ROLE ur       ON ur.USER_ID = u.USER_ID AND ur.IS_ACTIVE = 'Y'
          JOIN HMS_ROLE r             ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 'Y'
          JOIN HMS_ROLE_PERMISSION rp ON rp.ROLE_ID = r.ROLE_ID AND rp.IS_ACTIVE = 'Y'
          JOIN HMS_APP_MODULE m       ON m.MODULE_ID = rp.MODULE_ID
         WHERE u.USERNAME = UPPER(p_username)
           AND m.MODULE_CODE = UPPER(p_module_code)
           AND CASE UPPER(p_action)
                   WHEN 'VIEW'    THEN rp.CAN_VIEW
                   WHEN 'ADD'     THEN rp.CAN_ADD
                   WHEN 'EDIT'    THEN rp.CAN_EDIT
                   WHEN 'DELETE'  THEN rp.CAN_DELETE
                   WHEN 'PRINT'   THEN rp.CAN_PRINT
                   WHEN 'APPROVE' THEN rp.CAN_APPROVE
               END = 'Y';
        RETURN l_cnt > 0 OR has_role(p_username, 'SUPER_ADMIN');
    END has_permission;

    FUNCTION has_role (p_username IN VARCHAR2, p_role_code IN VARCHAR2) RETURN BOOLEAN IS
        l_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_cnt
          FROM HMS_USER u
          JOIN HMS_USER_ROLE ur ON ur.USER_ID = u.USER_ID AND ur.IS_ACTIVE = 'Y'
          JOIN HMS_ROLE r       ON r.ROLE_ID = ur.ROLE_ID
         WHERE u.USERNAME = UPPER(p_username) AND r.ROLE_CODE = UPPER(p_role_code);
        RETURN l_cnt > 0;
    END has_role;

END PKG_AUTH;
/
SHOW ERRORS
