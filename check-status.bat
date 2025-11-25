@echo off
echo ========================================
echo  HMIS Integration - System Status Check
echo ========================================
echo.

echo [Network Status]
docker network inspect hmis-network >nul 2>&1
if %errorlevel% equ 0 (
    echo   hmis-network: EXISTS
) else (
    echo   hmis-network: NOT FOUND (run start-all.bat)
)
echo.

echo [Running Containers]
echo.
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr "openmrs\|openelis\|orthanc\|NAMES"
echo.

echo ========================================
echo [Expected Containers - 11 total]
echo ========================================
echo.
echo OpenMRS (4 containers):
docker ps -q -f name=openmrs-distro-referenceapplication-gateway-1 >nul 2>&1 && echo   [OK] openmrs-distro-referenceapplication-gateway-1 || echo   [--] openmrs-distro-referenceapplication-gateway-1
docker ps -q -f name=openmrs-distro-referenceapplication-frontend-1 >nul 2>&1 && echo   [OK] openmrs-distro-referenceapplication-frontend-1 || echo   [--] openmrs-distro-referenceapplication-frontend-1
docker ps -q -f name=openmrs-distro-referenceapplication-backend-1 >nul 2>&1 && echo   [OK] openmrs-distro-referenceapplication-backend-1 || echo   [--] openmrs-distro-referenceapplication-backend-1
docker ps -q -f name=openmrs-distro-referenceapplication-db-1 >nul 2>&1 && echo   [OK] openmrs-distro-referenceapplication-db-1 || echo   [--] openmrs-distro-referenceapplication-db-1
echo.

echo OpenELIS (6 containers):
docker ps -q -f name=openelisglobal-webapp >nul 2>&1 && echo   [OK] openelisglobal-webapp || echo   [--] openelisglobal-webapp
docker ps -q -f name=openelisglobal-database >nul 2>&1 && echo   [OK] openelisglobal-database || echo   [--] openelisglobal-database
docker ps -q -f name=external-fhir-api >nul 2>&1 && echo   [OK] external-fhir-api || echo   [--] external-fhir-api
docker ps -q -f name=openelisglobal-front-end >nul 2>&1 && echo   [OK] openelisglobal-front-end || echo   [--] openelisglobal-front-end
docker ps -q -f name=openelisglobal-proxy >nul 2>&1 && echo   [OK] openelisglobal-proxy || echo   [--] openelisglobal-proxy
docker ps -q -f name=oe-certs >nul 2>&1 && echo   [OK] oe-certs || echo   [--] oe-certs
echo.

echo Orthanc PACS (1 container):
docker ps -q -f name=orthanc-pacs >nul 2>&1 && echo   [OK] orthanc-pacs || echo   [--] orthanc-pacs
echo.

echo ========================================
echo [Service URLs]
echo ========================================
echo.
curl -s http://localhost/openmrs/spa >nul 2>&1 && echo   [OK] OpenMRS:  http://localhost/openmrs/spa || echo   [--] OpenMRS:  http://localhost/openmrs/spa (not responding)
curl -s http://localhost:8090 >nul 2>&1 && echo   [OK] OpenELIS: http://localhost:8090 || echo   [--] OpenELIS: http://localhost:8090 (not responding)
curl -s http://localhost:8042 >nul 2>&1 && echo   [OK] PACS:     http://localhost:8042 || echo   [--] PACS:     http://localhost:8042 (not responding)
echo.

echo ========================================
echo [Quick Actions]
echo ========================================
echo.
echo   start-all.bat   - Start all systems
echo   stop-all.bat    - Stop all systems
echo   restart-all.bat - Restart all systems
echo.
echo View logs:
echo   docker logs openmrs-distro-referenceapplication-backend-1 -f
echo   docker logs openelisglobal-webapp -f
echo   docker logs orthanc-pacs -f
echo.
echo ========================================
pause