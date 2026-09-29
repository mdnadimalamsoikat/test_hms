@echo off
REM ======== Kaj SHURU te double-click (je PC te bosben) ========
cd /d C:\HMS_PROJECT
call sync\config.bat

echo [1/4] Git pull (latest script + dump + APEX) ...
git pull
if errorlevel 1 ( echo GIT PULL FAILED & pause & exit /b 1 )

echo [2/4] Purono HMS_APP object muche fela ...
sqlplus -S %DB% @sync\drop_for_import.sql
if errorlevel 1 ( echo DROP FAILED & pause & exit /b 1 )

echo [3/4] Database import ...
impdp %DB% SCHEMAS=HMS_APP DIRECTORY=HMS_DUMP_DIR DUMPFILE=hms_app.dmp LOGFILE=imp.log

echo [4/4] APEX app import ...
if exist apex\f%APP_ID%.sql ( cd sync & sqlplus -S %DB% @import_apex.sql & cd .. )

echo.
echo ===== READY. Office e je jaygay chilen, sekhan thekei shuru korun =====
pause
