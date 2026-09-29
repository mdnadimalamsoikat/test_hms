/*
================================================================================
 File    : database/09_grants/grant_permissions.sql
 Run As  : HMS_APP
 Purpose : Report user / onno schema ke read-only access (role diye)
           Roles 00_setup/02_create_user.sql e create hoyeche.
================================================================================
*/
SET SERVEROUTPUT ON
PROMPT >>> Granting object privileges to roles ...
BEGIN
    FOR v IN (SELECT VIEW_NAME FROM USER_VIEWS) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || v.VIEW_NAME || ' TO HMS_READONLY_ROLE';
    END LOOP;
    FOR t IN (SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME LIKE 'HMS\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON ' || t.TABLE_NAME || ' TO HMS_APP_USER_ROLE';
    END LOOP;
    FOR p IN (SELECT OBJECT_NAME FROM USER_OBJECTS WHERE OBJECT_TYPE IN ('PACKAGE','FUNCTION','PROCEDURE')) LOOP
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || p.OBJECT_NAME || ' TO HMS_APP_USER_ROLE';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Grants done.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Grant skipped (role na thakle ignore korun): ' || SQLERRM);
END;
/
