@echo off
REM Patient Verification Script for Windows
REM Usage: verify-patient.bat

echo ================================================
echo   OpenMRS FHIR Patient Verification Tool
echo ================================================
echo.

echo Searching for patient 'TestPatient Integration'...
echo.

curl -s -u admin:Admin123 "http://localhost/openmrs/ws/fhir2/R4/Patient?family=Integration" > temp_response.json

findstr /i "TestPatient" temp_response.json >nul
if %errorlevel% equ 0 (
    echo SUCCESS: Patient found!
    echo.
    echo Patient Data:
    type temp_response.json
    echo.
) else (
    echo FAILED: Patient 'TestPatient Integration' not found
    echo.
    echo Troubleshooting:
    echo 1. Have you registered the patient in OpenMRS?
    echo 2. Did you use exactly these names?
    echo    - Given Name: TestPatient
    echo    - Family Name: Integration
    echo 3. Check if OpenMRS is running: http://localhost/openmrs/spa/
    echo.
)

del temp_response.json >nul 2>&1

echo.
echo ================================================
echo   Quick Commands
echo ================================================
echo.
echo View all patients:
echo   curl -s http://localhost/openmrs/ws/fhir2/R4/Patient
echo.
echo View in browser:
echo   http://localhost/openmrs/ws/fhir2/R4/Patient?family=Integration
echo.

pause
