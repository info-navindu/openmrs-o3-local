# HMIS Integration Testing Checklist

## ✅ Phase 1: System Health Check - COMPLETED
All containers are running and healthy on the shared network.

---

## 📋 Phase 2: Web Access Verification

### Step 1: Test OpenMRS Access
1. Open browser: http://localhost/openmrs/spa/
2. **Expected:** OpenMRS login page appears
3. **Login:**
   - Username: `admin`
   - Password: `Admin123`
4. **Expected:** OpenMRS dashboard loads successfully

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Step 2: Test OpenELIS Access
1. Open browser: http://localhost:8090/
2. **Expected:** OpenELIS login page appears
3. **Login:**
   - Username: `admin`
   - Password: `adminADMIN!`
4. **Expected:** OpenELIS dashboard loads successfully

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Step 3: Test PACS Access
1. Open browser: http://localhost:8042/
2. **Expected:** Login prompt appears
3. **Login:**
   - Username: `orthanc`
   - Password: `orthanc`
4. **Expected:** Orthanc PACS interface loads

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

## 📋 Phase 3: API Connectivity Tests

### Test 1: OpenMRS FHIR API

Run this command in your terminal:
```bash
curl -s http://localhost/openmrs/ws/fhir2/R4/metadata | grep "fhirVersion"
```

**Expected Output:** `"fhirVersion" : "4.0.1"`

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Test 2: OpenELIS FHIR API

Run this command:
```bash
curl -s -k https://localhost:8544/fhir/metadata | grep "fhirVersion"
```

**Expected Output:** Contains `"fhirVersion": "4.0.1"`

**Note:** OpenELIS FHIR API uses HTTPS only (port 8544). Use `-k` to ignore self-signed certificate.

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Test 3: PACS REST API

Run this command:
```bash
curl -s -u orthanc:orthanc http://localhost:8042/system | grep "Version"
```

**Expected Output:** Orthanc version information

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

## 📋 Phase 4: Patient Registration Test

### Step 1: Register Patient in OpenMRS

1. In OpenMRS (http://localhost/openmrs/spa/), click **"Register Patient"**
2. Fill in patient details:
   - **Given Name:** TestPatient
   - **Family Name:** Integration
   - **Gender:** Male
   - **Date of Birth:** 1990-01-01
3. Click **"Confirm"** to register
4. **Note the Patient ID** (appears at top of patient page)

**Patient ID:** ________________

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Step 2: Verify Patient in OpenMRS FHIR

Run this command (replace {patient-uuid} with actual UUID from patient page URL):
```bash
curl -s "http://localhost/openmrs/ws/fhir2/R4/Patient?family=Integration" | grep "TestPatient"
```

**Expected:** Patient "TestPatient Integration" appears in results

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

## 📋 Phase 5: Lab Order Workflow Test

### Step 1: Create Lab Order in OpenMRS

1. Search for patient "TestPatient Integration"
2. Click on patient to view dashboard
3. Click **"Order Lab Tests"** or **"Add Lab Order"**
4. Select a test (e.g., "Complete Blood Count" or "Hemoglobin")
5. Click **"Order"** or **"Save"**
6. **Note the Order Number:** ________________

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Step 2: Verify Order in OpenELIS

1. Log into OpenELIS: http://localhost:8090/
2. Navigate to **"Sample Collection"** or **"Lab Orders"**
3. Search for patient "TestPatient Integration"
4. **Expected:** Lab order should appear (if integration is configured)

**Note:** *Full integration requires OpenMRS OpenELIS module configured. If order doesn't appear automatically, this is expected at this stage.*

**Status:** ⬜ Not tested | ✅ Success | ⚠️ Manual entry needed | ❌ Failed

---

### Step 3: Manual Lab Order Entry in OpenELIS

If automatic integration isn't configured yet, manually create a lab order:

1. In OpenELIS, click **"Sample Collection"** or **"Add Sample"**
2. Create new patient or search for existing
3. Enter sample details:
   - **Sample Type:** Blood
   - **Test:** Select any available test (e.g., CBC)
4. Click **"Save"**
5. **Note Sample/Accession Number:** ________________

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

### Step 4: Enter Lab Results in OpenELIS

1. Navigate to **"Results Entry"** or **"Result Entry"**
2. Find the sample you created
3. Enter test results:
   - Enter values for the test panels
   - Mark as **"Complete"** or **"Validated"**
4. Save results

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

## 📋 Phase 6: Radiology Workflow Test

### Step 1: Upload Test Image to PACS

1. Go to PACS: http://localhost:8042/
2. Click **"Upload"** button (top right)
3. If you have a DICOM file (.dcm), upload it
4. **OR** Use test mode: Just verify the interface loads

**Status:** ⬜ Not tested | ✅ Success | ⚠️ No DICOM file | ❌ Failed

---

### Step 2: View Images in PACS

1. In PACS interface, you should see uploaded studies
2. Click on any study to view details
3. Click on series to view images
4. **Expected:** DICOM viewer shows medical images

**Status:** ⬜ Not tested | ✅ Success | ⚠️ No images | ❌ Failed

---

### Step 3: Test PACS API

Run this command:
```bash
curl -s -u orthanc:orthanc http://localhost:8042/patients | head -20
```

**Expected:** JSON array of patients (may be empty `[]` if no images uploaded)

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

## 📋 Phase 7: Network Communication Test

### Test Inter-Container Communication

Run these commands to verify containers can reach each other:

```bash
# Test 1: Check all containers on shared network
docker network inspect hmis-network --format '{{range .Containers}}{{.Name}}{{println}}{{end}}'
```

**Expected:** Lists all 11 containers

```bash
# Test 2: DNS resolution from OpenMRS to FHIR API
docker exec openmrs-distro-referenceapplication-backend-1 getent hosts external-fhir-api
```

**Expected:** Shows IP address like `172.22.0.9 external-fhir-api`

```bash
# Test 3: DNS resolution from OpenMRS to PACS
docker exec openmrs-distro-referenceapplication-backend-1 getent hosts orthanc-pacs
```

**Expected:** Shows IP address like `172.22.0.7 orthanc-pacs`

**Status:** ⬜ Not tested | ✅ Success | ❌ Failed

---

## 📋 Summary Checklist

| Test Phase | Status | Notes |
|------------|--------|-------|
| System Health Check | ✅ | All containers running |
| OpenMRS Web Access | ⬜ | |
| OpenELIS Web Access | ⬜ | |
| PACS Web Access | ⬜ | |
| OpenMRS FHIR API | ⬜ | |
| OpenELIS FHIR API | ⬜ | |
| PACS REST API | ⬜ | |
| Patient Registration | ⬜ | |
| Lab Order Workflow | ⬜ | |
| Radiology Workflow | ⬜ | |
| Network Communication | ✅ | DNS working |

---

## 🔍 Troubleshooting Commands

### View Container Logs
```bash
# OpenMRS Backend
docker logs -f openmrs-distro-referenceapplication-backend-1

# OpenELIS Webapp
docker logs -f openelisglobal-webapp

# OpenELIS FHIR API
docker logs -f external-fhir-api

# PACS
docker logs -f orthanc-pacs
```

### Restart Individual Systems
```bash
# Restart OpenMRS
cd C:/Users/NavinduGunawardena/openmrs-o3-local/openmrs-distro-referenceapplication
docker compose restart

# Restart OpenELIS
cd ../OpenELIS-Global-2
docker compose restart

# Restart PACS
cd ../orthanc-pacs
docker compose restart
```

### Check Container Stats
```bash
docker stats --no-stream
```

---

## ✨ Next Steps After Testing

1. **If all tests pass:** Your HMIS integration is working! Proceed to configure full integration modules.

2. **Configure OpenMRS Modules:**
   - Install OpenELIS module for automated lab orders
   - Install Radiology module for PACS integration

3. **Set up authentication:**
   - Configure FHIR authentication between systems
   - Set up shared patient identifiers

4. **Production considerations:**
   - Change all default passwords
   - Enable HTTPS for all services
   - Set up proper backup procedures

---

**Testing Date:** ________________

**Tested By:** ________________

**Overall Status:** ⬜ Pass | ⬜ Partial | ⬜ Fail

**Notes:**