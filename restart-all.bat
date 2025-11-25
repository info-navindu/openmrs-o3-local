@echo off
echo ========================================
echo  HMIS Integration - Restarting All Systems
echo ========================================
echo.

REM Store the current directory
set "SCRIPT_DIR=%~dp0"

echo [1/2] Stopping all systems...
call "%SCRIPT_DIR%stop-all.bat"
echo.

echo Waiting 5 seconds before restart...
timeout /t 5 /nobreak >nul
echo.

echo [2/2] Starting all systems...
call "%SCRIPT_DIR%start-all.bat"