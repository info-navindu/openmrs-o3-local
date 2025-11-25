@echo off
echo ========================================
echo  HMIS Integration - Stopping All Systems
echo ========================================
echo.

echo [1/3] Stopping OpenMRS O3...
cd openmrs-distro-referenceapplication
docker compose down
if %errorlevel% equ 0 (
    echo      OpenMRS stopped successfully
) else (
    echo      ERROR: Failed to stop OpenMRS
)
cd ..
echo.

echo [2/3] Stopping OpenELIS...
cd OpenELIS-Global-2
docker compose down
if %errorlevel% equ 0 (
    echo      OpenELIS stopped successfully
) else (
    echo      ERROR: Failed to stop OpenELIS
)
cd ..
echo.

echo [3/3] Stopping Orthanc PACS...
cd orthanc-pacs
docker compose down
if %errorlevel% equ 0 (
    echo      PACS stopped successfully
) else (
    echo      ERROR: Failed to stop PACS
)
cd ..
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