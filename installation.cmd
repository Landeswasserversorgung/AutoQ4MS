@echo off
setlocal enabledelayedexpansion

:: ===============================================================
::  AutoQ4MS - Installation Script
:: ===============================================================
::  This script:
::    1) Ensures it's running as Administrator (auto-elevates if needed)
::    2) Locates MATLAB (via Registry or default path)
::    3) Runs the AutoQ4MS installation routine in batch mode
:: ===============================================================

title AutoQ4MS Installation
color 0A
echo ===============================================================
echo    Installing AutoQ4MS
echo ===============================================================
echo.

:: ===============================================================
:: 1) Check for Administrator privileges
:: ===============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo ---------------------------------------------------------------
  echo   Administrator privileges required.
  echo Restarting with elevated rights...
  echo ---------------------------------------------------------------
  powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo  Administrator privileges confirmed.
echo.

:: ===============================================================
:: 2) Locate MATLAB executable
:: ===============================================================
set "MATLAB_EXE="

:: Try registry lookup first
for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\MathWorks\MATLAB" /s /v MATLABROOT 2^>nul ^| find "MATLABROOT"') do (
  if exist "%%B\bin\matlab.exe" set "MATLAB_EXE=%%B\bin\matlab.exe"
)

:: Fallback: Default installation path
if not defined MATLAB_EXE (
  if exist "C:\Program Files\MATLAB\R2024a\bin\matlab.exe" (
    set "MATLAB_EXE=C:\Program Files\MATLAB\R2024a\bin\matlab.exe"
  ) else (
    echo X MATLAB executable not found!
    echo Please install MATLAB 2024a or adjust the path in this script.
    pause
    exit /b
  )
)
echo  MATLAB found at: %MATLAB_EXE%
echo.

:: ===============================================================
:: 3) Determine project directories dynamically
:: ===============================================================
:: The CMD file itself is located in the AutoQ_paper root directory.
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "SRC_DIR=%PROJECT_DIR%\src"

if not exist "%SRC_DIR%" (
  echo X Source folder not found: "%SRC_DIR%"
  pause
  exit /b
)

echo Project directory: %PROJECT_DIR%
echo Source directory:  %SRC_DIR%
echo.

:: ===============================================================
:: 4) Run MATLAB silently in batch mode to execute installation.m
:: ===============================================================
echo ---------------------------------------------------------------
echo Running MATLAB (batch mode) to start AutoQ4MS installation...
echo ---------------------------------------------------------------
echo.

:: -batch  : runs the command and exits automatically
:: -sd     : sets MATLAB startup directory
"%MATLAB_EXE%" -sd "%SRC_DIR%" -batch "try, installation; catch ME, disp(getReport(ME,'extended')); exit(1); end"

set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo ===============================================================
  echo  AutoQ4MS installation completed successfully.
  echo ===============================================================
) else (
  echo ===============================================================
  echo X MATLAB returned error code %RC%.
  echo Please review the output above for details.
  echo ===============================================================
)

echo.
pause
endlocal


