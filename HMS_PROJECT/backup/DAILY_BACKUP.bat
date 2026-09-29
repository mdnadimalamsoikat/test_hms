@echo off
REM ============================================================
REM  Protidin raat e auto chalbe (SCHEDULE_TASKS.bat dekhun)
REM  1) RMAN incremental (Shukrobar e FULL)   -> puro DB
REM  2) Data Pump export HMS_APP schema       -> logical copy
REM  3) APEX app export                       -> app copy
REM  4) 14 diner purono file muche fela + offsite copy
REM ============================================================
call "%~dp0config.bat"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm"') do set TS=%%i
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).DayOfWeek"') do set DOW=%%i
if not exist "%BK_ROOT%\logs" mkdir "%BK_ROOT%\logs"
if not exist "%BK_ROOT%\apex" mkdir "%BK_ROOT%\apex"
if not exist "%BK_ROOT%\rman" mkdir "%BK_ROOT%\rman"
set LOG=%BK_ROOT%\logs\backup_%TS%.log
echo ==== HMS BACKUP %TS% (%DOW%) ==== > "%LOG%"

echo [1/4] RMAN ...
if /I "%DOW%"=="Friday" (
  rman target / cmdfile="%~dp0rman_full.rcv" >> "%LOG%" 2>&1
) else (
  rman target / cmdfile="%~dp0rman_incr.rcv" >> "%LOG%" 2>&1
)
if errorlevel 1 echo *** RMAN FAILED *** >> "%LOG%"

echo [2/4] Data Pump export ...
expdp %DB_USER%/"%DB_PASS%"@%DB_CONN% SCHEMAS=%DB_USER% DIRECTORY=HMS_BACKUP_DIR DUMPFILE=hms_%TS%.dmp LOGFILE=hms_%TS%_exp.log COMPRESSION=METADATA_ONLY FLASHBACK_TIME=SYSTIMESTAMP >> "%LOG%" 2>&1
if errorlevel 1 echo *** EXPDP FAILED *** >> "%LOG%"

echo [3/4] APEX export ...
if exist "%SQLCL%" (
  pushd "%BK_ROOT%\apex"
  echo apex export -workspace HMS -expOriginalIds > "%TEMP%\hms_apex.sql"
  echo exit >> "%TEMP%\hms_apex.sql"
  "%SQLCL%" -S %DB_USER%/"%DB_PASS%"@%DB_CONN% @"%TEMP%\hms_apex.sql" >> "%LOG%" 2>&1
  for %%f in (f*.sql) do move /Y "%%f" "%%~nf_%TS%.sql" >nul
  popd
) else echo SQLcl pawa jay nai - APEX export skip >> "%LOG%"

echo [4/4] Cleanup + offsite ...
forfiles /p "%BK_ROOT%\dump" /m *.* /d -%KEEP_DAYS% /c "cmd /c del @path" 2>nul
forfiles /p "%BK_ROOT%\apex" /m *.sql /d -%KEEP_DAYS% /c "cmd /c del @path" 2>nul
forfiles /p "%BK_ROOT%\logs" /m *.log /d -30 /c "cmd /c del @path" 2>nul
if not "%OFFSITE%"=="" if exist "%OFFSITE%\.." (
  robocopy "%BK_ROOT%\dump" "%OFFSITE%\dump" hms_%TS%* /NJH /NJS >> "%LOG%"
  robocopy "%BK_ROOT%\apex" "%OFFSITE%\apex" *_%TS%.sql /NJH /NJS >> "%LOG%"
)
findstr /C:"FAILED" "%LOG%" >nul && (echo !!! KICHU FAIL HOYECHE - log dekhun: %LOG%) || (echo DONE. Log: %LOG%)
