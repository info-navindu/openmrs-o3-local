@echo off
echo ========================================
echo  HMIS Integration - Stopping All Systems
echo ========================================
echo.

REM Store the current directory
set "SCRIPT_DIR=%~dp0"

echo [1/3] Stopping OpenMRS O3...
pushd "%SCRIPT_DIR%openmrs-distro-referenceapplication"
docker compose down
if %errorlevel% equ 0 (
    echo      OpenMRS stopped successfully
) else (
    echo      ERROR: Failed to stop OpenMRS
)
popd
echo.

echo [2/3] Stopping OpenELIS...
pushd "%SCRIPT_DIR%OpenELIS-Global-2"
docker compose down
if %errorlevel% equ 0 (
    echo      OpenELIS stopped successfully
) else (
    echo      ERROR: Failed to stop OpenELIS
)
popd
echo.

echo [3/3] Stopping Orthanc PACS...
pushd "%SCRIPT_DIR%orthanc-pacs"
docker compose down
if %errorlevel% equ 0 (
    echo      PACS stopped successfully
) else (
    echo      ERROR: Failed to stop PACS
)
popd
echo.

echo ========================================
echo  All Systems Stopped!
echo ========================================
echo.
echo Note: The hmis-network is still available for quick restart.
echo Data volumes are preserved.
echo.
echo To restart all systems, run: start-all.bat
echo.
echo To remove all data volumes (WARNING - DELETES DATA):
echo   docker volume prune
echo ========================================
echo.
pause