@echo off
REM Administrator hisebe EKBAR chalan. Protidin raat 11:30 e DAILY_BACKUP chalbe,
REM Robibar sokal 10 tay backup validate hobe.
schtasks /Create /TN "HMS_Daily_Backup" /TR "\"%~dp0DAILY_BACKUP.bat\"" /SC DAILY /ST 23:30 /RL HIGHEST /F
schtasks /Create /TN "HMS_Weekly_Validate" /TR "cmd /c rman target / cmdfile=\"%~dp0rman_validate.rcv\" > D:\HMS_BACKUP\logs\validate.log" /SC WEEKLY /D SUN /ST 10:00 /RL HIGHEST /F
schtasks /Query /TN "HMS_Daily_Backup"
