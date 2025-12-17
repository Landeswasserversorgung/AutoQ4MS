@echo off

cd /d "%PROJECT_PATH%"

echo [AutoQ4MS] Processing is executed...

REM Extract method (file name without path and extension)
for %%f in ("%METHOD_PATH%") do set "METHOD_NAME=%%~nf"

REM create time stamp (Format: YYYYMMDD-HHMM)
for /f %%a in ('powershell -command "Get-Date -Format yyyyMMdd-HHmm"') do set "TS=%%a"

REM Compose log file path
set LOG_PATH=%LOGS_PATH%\logs\%METHOD_NAME%_%TS%.log

REM Delete previous log file (optional)
if exist "%LOG_PATH%" del "%LOG_PATH%"

"%MATLAB_EXE%" -batch "try,  setup(); processing('%METHOD_PATH%'); disp('[AutoQ4MS] processing finished successfully.'); exit(0); catch e, fid = fopen('%LOG_PATH%', 'w'); msg = getReport(e, 'extended', 'hyperlinks', 'off'); fprintf(fid, 'FAIL\n%%s\n', msg); fclose(fid); exit(1); end"

REM Check errors using log
findstr /C:"FAIL" "%LOG_PATH%" >nul
IF %ERRORLEVEL% EQU 0 (
    echo Fehler beim Ausführen von MATLAB! Siehe log:
    echo %LOG_PATH%
)

exit
