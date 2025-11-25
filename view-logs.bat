@echo off
echo ========================================
echo  HMIS Integration - Log Viewer
echo ========================================
echo.
echo Select which system logs to view:
echo.
echo   1. OpenMRS Backend
echo   2. OpenMRS Gateway
echo   3. OpenELIS WebApp
echo   4. OpenELIS FHIR API
echo   5. Orthanc PACS
echo   6. All Systems (combined)
echo   7. Exit
echo.
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" (
    echo.
    echo Viewing OpenMRS Backend logs (Ctrl+C to exit)...
    echo.
    docker logs openmrs-distro-referenceapplication-backend-1 -f
)

if "%choice%"=="2" (
    echo.
    echo Viewing OpenMRS Gateway logs (Ctrl+C to exit)...
    echo.
    docker logs openmrs-distro-referenceapplication-gateway-1 -f
)

if "%choice%"=="3" (
    echo.
    echo Viewing OpenELIS WebApp logs (Ctrl+C to exit)...
    echo.
    docker logs openelisglobal-webapp -f
)

if "%choice%"=="4" (
    echo.
    echo Viewing OpenELIS FHIR API logs (Ctrl+C to exit)...
    echo.
    docker logs external-fhir-api -f
)

if "%choice%"=="5" (
    echo.
    echo Viewing Orthanc PACS logs (Ctrl+C to exit)...
    echo.
    docker logs orthanc-pacs -f
)

if "%choice%"=="6" (
    echo.
    echo Viewing ALL system logs (Ctrl+C to exit)...
    echo.
    echo Starting log streams in separate windows...
    start "OpenMRS Backend" docker logs openmrs-distro-referenceapplication-backend-1 -f
    start "OpenELIS WebApp" docker logs openelisglobal-webapp -f
    start "PACS" docker logs orthanc-pacs -f
    echo.
    echo Log windows opened. Close them when done.
    pause
)

if "%choice%"=="7" (
    exit
)

echo.
pause