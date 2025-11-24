#!/bin/bash
# Patient Verification Script
# Usage: bash verify-patient.sh

echo "================================================"
echo "  OpenMRS FHIR Patient Verification Tool"
echo "================================================"
echo ""

echo "🔍 Searching for patient 'TestPatient Integration'..."
echo ""

RESPONSE=$(curl -s -u admin:Admin123 "http://localhost/openmrs/ws/fhir2/R4/Patient?family=Integration")

# Check if patient exists
if echo "$RESPONSE" | grep -q "TestPatient"; then
    echo "✅ SUCCESS: Patient found!"
    echo ""
    echo "Patient Details:"
    echo "---------------"
    echo "$RESPONSE" | grep -A 5 '"name"' | head -10
    echo ""

    # Extract total count
    TOTAL=$(echo "$RESPONSE" | grep -o '"total"[^,]*' | head -1)
    echo "📊 $TOTAL patients found with family name 'Integration'"

else
    echo "❌ FAILED: Patient 'TestPatient Integration' not found"
    echo ""
    echo "Troubleshooting:"
    echo "1. Have you registered the patient in OpenMRS?"
    echo "2. Did you use exactly these names?"
    echo "   - Given Name: TestPatient"
    echo "   - Family Name: Integration"
    echo "3. Try checking all patients: curl -s http://localhost/openmrs/ws/fhir2/R4/Patient"
    echo ""
fi

echo ""
echo "================================================"
echo "  Additional Commands"
echo "================================================"
echo ""
echo "View all patients:"
echo "  curl -s http://localhost/openmrs/ws/fhir2/R4/Patient | grep '\"total\"'"
echo ""
echo "Search by given name:"
echo "  curl -s \"http://localhost/openmrs/ws/fhir2/R4/Patient?given=TestPatient\""
echo ""
echo "View in browser:"
echo "  http://localhost/openmrs/ws/fhir2/R4/Patient?family=Integration"
echo ""