/*
================================================================================
 File    : database/DROP_ALL.sql
 Run As  : HMS_APP
 Purpose : !!! DEVELOPMENT ONLY !!!  HMS_APP er SOB object delete (fresh reinstall er jonno)
           Production e KOKHONO run korben na.
================================================================================
*/
SET SERVEROUTPUT ON
PROMPT !!! Dropping ALL objects of current schema in 5 sec... (Ctrl+C to cancel in SQL*Plus)
EXEC DBMS_SESSION.SLEEP(5);
BEGIN
    IF USER <> 'HMS_APP' THEN
        RAISE_APPLICATION_ERROR(-20999, 'Safety: only HMS_APP schema te run kora jabe. Current: ' || USER);
    END IF;
    FOR o IN (SELECT OBJECT_NAME, OBJECT_TYPE FROM USER_OBJECTS
               WHERE OBJECT_TYPE IN ('VIEW','PACKAGE','FUNCTION','PROCEDURE','SEQUENCE','TRIGGER','TYPE')
               ORDER BY DECODE(OBJECT_TYPE,'TRIGGER',1,'VIEW',2,'PACKAGE',3,4)) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || o.OBJECT_TYPE || ' "' || o.OBJECT_NAME || '"';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
    FOR t IN (SELECT TABLE_NAME FROM USER_TABLES) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE "' || t.TABLE_NAME || '" CASCADE CONSTRAINTS PURGE';
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('All HMS objects dropped.');
END;
/
