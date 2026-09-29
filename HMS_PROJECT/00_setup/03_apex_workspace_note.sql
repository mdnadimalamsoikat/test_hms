/*
================================================================================
 File    : 00_setup/03_apex_workspace_note.sql
 Run As  : SYS (optional - APEX Admin UI diyeo kora jay)
 Purpose : APEX 24.2 workspace create kore HMS_APP schema assign kora
================================================================================
 UI diye korte chaile:
   http://localhost:8080/ords/apex_admin  -> Manage Workspaces -> Create Workspace
   Workspace Name : HMS
   Re-use existing schema : YES  ->  HMS_APP
*/
BEGIN
  APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
      p_workspace      => 'HMS',
      p_primary_schema => 'HMS_APP');
  COMMIT;
END;
/
SELECT WORKSPACE_NAME, SCHEMA FROM APEX_WORKSPACE_SCHEMAS WHERE WORKSPACE_NAME = 'HMS';
