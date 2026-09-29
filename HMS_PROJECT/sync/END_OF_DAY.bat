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
) else ( echo SQLcl pawa jayni - APEX Builder theke manually f%APP_ID%.sql export kore apex folder e rakhun )

echo [3/3] Git push ...
git add -A
git commit -m "End of day %COMPUTERNAME% %date% %time%"
git push
echo.
echo ===== DONE. Ekhon onno PC te START_OF_DAY.bat chalan =====
pause
