@echo off
REM ======== Kaj SHESH e double-click (je PC te kaj korlen) ========
cd /d C:\HMS_PROJECT
call sync\config.bat

echo [1/3] Database export (structure + data) ...
expdp %DB% SCHEMAS=HMS_APP DIRECTORY=HMS_DUMP_DIR DUMPFILE=hms_app.dmp LOGFILE=exp.log REUSE_DUMPFILES=YES
if errorlevel 1 ( echo EXPORT FAILED & pause & exit /b 1 )

echo [2/3] APEX app export ...
if exist "%SQLCL%" (
  "%SQLCL%" -S %DB% @sync\apex_export.sql
) else (
  echo.
  echo SQLcl nai. APEX Builder theke HATE export korun:
  echo   App Builder ^> App %APP_ID% ^> Export/Import ^> Export ^> Format: SQL ^> Export Application
  echo   File ta f%APP_ID%.sql naam e C:\HMS_PROJECT\apex folder e save korun ^(purono file replace^)
  echo.
  pause
)

echo [3/3] Git push ...
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 ( echo Git repo na - push skip. HMS_PROJECT folder ta pendrive e copy korun ) else (
  git add -A
  git commit -m "End of day %COMPUTERNAME% %date% %time%"
  git push
)
echo.
echo ===== DONE. Ekhon onno PC te START_OF_DAY.bat chalan =====
pause
