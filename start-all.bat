@echo off
echo ========================================
echo  HMIS Integration - Starting All Systems
echo ========================================
echo.

REM Store the current directory
set "SCRIPT_DIR=%~dp0"

echo [1/4] Creating shared network (if not exists)...
docker network create hmis-network 2>nul
if %errorlevel% equ 0 (
    echo      Network created successfully
) else (
    echo      Network already exists
)
echo.

echo [2/4] Starting OpenMRS O3 (EMR System)...
pushd "%SCRIPT_DIR%openmrs-distro-referenceapplication"
docker compose up -d
if %errorlevel% equ 0 (
    echo      OpenMRS started successfully
) else (
    echo      ERROR: Failed to start OpenMRS
)
popd
echo.

echo [3/4] Starting OpenELIS (Laboratory System)...
pushd "%SCRIPT_DIR%OpenELIS-Global-2"
docker compose up -d
if %errorlevel% equ 0 (
    echo      OpenELIS started successfully
) else (
    echo      ERROR: Failed to start OpenELIS
)
popd
echo.

echo [4/4] Starting Orthanc PACS (Medical Imaging)...
pushd "%SCRIPT_DIR%orthanc-pacs"
docker compose up -d
if %errorlevel% equ 0 (
    echo      PACS started successfully
) else (
    echo      ERROR: Failed to start PACS
)
popd
echo.

echo ========================================
echo  All Systems Started!
echo ========================================
echo.
echo Please wait 3-5 minutes for all services to initialize.
echo.
echo Access URLs:
echo   - OpenMRS O3:  http://localhost/openmrs/spa
echo     Credentials: admin / Admin123
echo.
echo   - OpenELIS:    http://localhost:8090
echo     Credentials: admin / adminADMIN!
echo.
echo   - PACS:        http://localhost:8042
echo     Credentials: orthanc / orthanc
echo.
echo ========================================
echo.
echo To view logs, run:
echo   docker logs openmrs-distro-referenceapplication-backend-1 -f
echo   docker logs openelisglobal-webapp -f
echo   docker logs orthanc-pacs -f
echo.
echo To stop all systems, run: stop-all.bat
echo ========================================
echo.
pause