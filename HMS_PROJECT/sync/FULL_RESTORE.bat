@echo off
REM ============================================================================
REM  FULL_RESTORE.bat  -  HMS_APP user DROP + notun kore create + .dmp import + APEX import
REM  Kokhon: onno PC te (ba nijer PC te) shob kichu "clean" kore dump theke ferot ante chan.
REM  Age: sync\dump\hms_app.dmp ar apex\f101.sql ei PC te thakte hobe (git pull / pendrive).
REM ============================================================================
cd /d C:\HMS_PROJECT
call sync\config.bat

echo.
echo  !!! WARNING !!!  Ei PC er HMS_APP user er SOB table/data muche jabe,
echo  tarpor sync\dump\hms_app.dmp theke ferot ashbe.
echo  Ei PC te unsaved kaj thakle age oi PC te END_OF_DAY.bat chalan.
echo.
set /p OK=Continue korte YES likhun: 
if /I not "%OK%"=="YES" ( echo Cancelled. & pause & exit /b 1 )

if not exist sync\dump\hms_app.dmp ( echo ERROR: sync\dump\hms_app.dmp nai. & pause & exit /b 1 )

echo.
echo [1/5] Git pull ^(thakle^) ...
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 ( echo Git repo na - skip ) else (
  git pull
  if errorlevel 1 ( echo GIT PULL FAILED & pause & exit /b 1 )
)

echo.
echo [2/5] HMS_APP drop + create  ^(SYS password chaibe - type korle screen e dekha jabe na^)
echo       Toad / SQL tab e HMS_APP connect thakle age Disconnect korun.
sqlplus "sys@%DB_SERVICE% as sysdba" @sync\full_reset_user.sql "%DB_PASS%"
if errorlevel 1 ( echo DROP/CREATE FAILED - upore error dekhun & pause & exit /b 1 )

echo.
echo [3/5] Database import ^(impdp^) ...
impdp %DB% SCHEMAS=HMS_APP DIRECTORY=HMS_DUMP_DIR DUMPFILE=hms_app.dmp LOGFILE=imp.log
echo       impdp warning dekhale imp.log ^(sync\dump folder e^) khulun. Error na thakle thik ache.

echo.
echo [4/5] APEX app import ...
if exist apex\f%APP_ID%.sql (
  cd sync
  sqlplus -S %DB% @import_apex.sql
  cd ..
) else (
  echo apex\f%APP_ID%.sql nai - App Builder ^> Import diye hate import korun.
)

echo.
echo [5/5] Check ...
sqlplus -S %DB% @sync\post_import_check.sql

echo.
echo ===== FULL RESTORE shesh. Upor er "INVALID objects" ar "13 ta must-have" check korun =====
pause
