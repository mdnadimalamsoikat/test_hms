@echo off
REM ============================================================
REM  HMS_APP schema ke kono ekta din er dump theke ferot ana
REM  Use:  RESTORE_SCHEMA.bat hms_20260926_2330.dmp
REM  ⚠ HMS_APP er BORTOMAN shob data replace hobe!
REM ============================================================
call "%~dp0config.bat"
if "%~1"=="" (echo Dump file name din. Available:& dir /b "%BK_ROOT%\dump\*.dmp" & exit /b 1)
echo HMS_APP er current data %1 diye REPLACE hobe.
set /p OK=Nishchit? (YES likhun): 
if not "%OK%"=="YES" exit /b 1
REM Age safety copy
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm"') do set TS=%%i
expdp %DB_USER%/"%DB_PASS%"@%DB_CONN% SCHEMAS=%DB_USER% DIRECTORY=HMS_BACKUP_DIR DUMPFILE=before_restore_%TS%.dmp LOGFILE=before_restore_%TS%.log
impdp %DB_USER%/"%DB_PASS%"@%DB_CONN% SCHEMAS=%DB_USER% DIRECTORY=HMS_BACKUP_DIR DUMPFILE=%1 LOGFILE=restore_%TS%.log TABLE_EXISTS_ACTION=REPLACE
sqlplus -S %DB_USER%/"%DB_PASS%"@%DB_CONN% @"%~dp0..\database\VERIFY.sql"
echo Restore shesh. Invalid object thakle upore dekhun.
