@echo off
REM ====== PROTI PC TE NIJER MOTO SET KORUN ======
set DB_PASS=Hms#Strong2026
set DB_SERVICE=localhost:1521/ORCL
set APP_ID=101
REM SQLcl optional (nai thakle END_OF_DAY e APEX hate export korte bolbe). SQLcl: sqldeveloper\sqlcl\bin\sql.exe
REM (old note) SQLcl (SQL Developer er sathe ase): sqldeveloper\sqlcl\bin\sql.exe
set SQLCL=C:\sqldeveloper\sqlcl\bin\sql.exe
set DB=HMS_APP/%DB_PASS%@%DB_SERVICE%
