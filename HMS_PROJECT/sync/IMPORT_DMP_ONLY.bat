@echo off
REM ============================================================================
REM  IMPORT_DMP_ONLY.bat  -  shudhu .dmp import (user ager theke create kora, APEX alada)
REM  Ei file ta sync folder e thakbe (dump folder = ei folder er "dump" subfolder).
REM  Age 1 bar SYS diye directory banate hobe (guide e Step 1).
REM ============================================================================
setlocal
REM ---- nijer moto change korun ----
set DB=HMS_APP/HMS123@localhost:1521/PDB
set DUMPFILE=hms_app.dmp
set DIR_NAME=HMS_DUMP_DIR
REM ---------------------------------
set DUMP_DIR=%~dp0dump

echo Dump folder : %DUMP_DIR%
if not exist "%DUMP_DIR%\%DUMPFILE%" (
  echo ERROR: %DUMP_DIR%\%DUMPFILE% pawa jay nai. Folder e ja ache:
  dir /b "%DUMP_DIR%"
  pause
  exit /b 1
)

echo.
echo impdp shuru ^(TABLE_EXISTS_ACTION=REPLACE: table age theke thakle replace^) ...
impdp %DB% SCHEMAS=HMS_APP DIRECTORY=%DIR_NAME% DUMPFILE=%DUMPFILE% LOGFILE=imp.log TABLE_EXISTS_ACTION=REPLACE

echo.
echo Shesh. "ORA-" error dekhle imp.log ^(%DUMP_DIR%\imp.log^) khule pathan.
pause
