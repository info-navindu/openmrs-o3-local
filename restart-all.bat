@echo off
echo ========================================
echo  HMIS Integration - Restarting All Systems
echo ========================================
echo.

echo [1/2] Stopping all systems...
call stop-all.bat
echo.

echo Waiting 5 seconds before restart...
timeout /t 5 /nobreak >nul
echo.

echo [2/2] Starting all systems...
call start-all.bat