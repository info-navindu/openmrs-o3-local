# HMIS Integration Setup Guide

## Overview

This guide walks you through integrating OpenMRS O3, OpenELIS Global, and Orthanc PACS into a unified Health Management Information System.

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INTEGRATED HMIS                          │
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │  OpenMRS O3  │         │  OpenELIS    │                 │
│  │   (EMR)      │◄───────►│   (LIMS)     │                 │
│  │              │  FHIR   │              │                 │
│  │  - Patients  │  R4     │  - Lab Tests │                 │
│  │  - Encounters│         │  - Results   │                 │
│  │  - Orders    │         │  - Reports   │                 │
│  └──────┬───────┘         └──────────────┘                 │
│         │                                                   │
│         │ DICOM                                            │
│         │                                                   │
│  ┌──────▼───────┐                                          │
│  │   Orthanc    │                                          │
│  │    PACS      │                                          │
│  │              │                                          │
│  │  - X-Rays    │                                          │
│  │  - CT Scans  │                                          │
│  │  - MRI       │                                          │
│  └──────────────┘                                          │
│                                                             │
│         All connected via: hmis-network (172.22.0.0/16)   │
└─────────────────────────────────────────────────────────────┘
```

---

## Integration Methods

### 1. OpenMRS ↔ OpenELIS (Lab Integration)

**Protocol:** FHIR R4 API
**Data Flow:**

```
Order Flow:
OpenMRS → ServiceRequest (FHIR) → OpenELIS FHIR API → OpenELIS Database

Result Flow:
OpenELIS → DiagnosticReport (FHIR) → OpenMRS FHIR API → OpenMRS Database
```

**Endpoints:**
- OpenMRS FHIR: `http://openmrs-distro-referenceapplication-backend-1:8080/openmrs/ws/fhir2/R4/`
- OpenELIS FHIR: `https://external-fhir-api:8443/fhir/` (HTTPS only, use `-k` flag)

### 2. OpenMRS ↔ PACS (Radiology Integration)

**Protocol:** DICOM + REST API
**Data Flow:**

```
Order Flow:
OpenMRS → DICOM Worklist → PACS

Image Flow:
Imaging Device → DICOM C-STORE → PACS → OpenMRS (viewer link)
```

**Endpoints:**
- PACS DICOM: `orthanc-pacs:4242` (AET: ORTHANC)
- PACS REST API: `http://orthanc-pacs:8042/`

---

## Prerequisites Checklist

Before starting, verify:

- [ ] All three systems are running
- [ ] All containers are on `hmis-network`
- [ ] You can access all web interfaces
- [ ] You have admin credentials for all systems
- [ ] FHIR APIs are responding with authentication

**Verify with:**
```bash
# Check all systems
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check network
docker network inspect hmis-network

# Test FHIR APIs
curl -u admin:Admin123 "http://localhost/openmrs/ws/fhir2/R4/metadata"
curl "http://localhost:8081/fhir/metadata"
curl -u orthanc:orthanc "http://localhost:8042/system"
```

---

## Part 1: OpenMRS ↔ OpenELIS Integration

### Step 1: Understanding the Integration Options

There are **3 ways** to integrate OpenMRS with OpenELIS:

#### **Option A: Manual Integration (Current State)** ✅
- Create orders in OpenMRS
- Manually enter orders in OpenELIS
- Manually view results in both systems
- **Best for:** Testing, learning, small clinics

#### **Option B: FHIR Bridge Integration** 🔄
- Use middleware to sync orders/results via FHIR
- Requires custom bridge application
- Semi-automated workflow
- **Best for:** Custom implementations

#### **Option C: OpenELIS Module Integration** ⭐ (Recommended)
- Install OpenELIS module in OpenMRS
- Fully automated order sending
- Automatic result retrieval
- **Best for:** Production environments

---

### Step 2: Option A - Manual Integration (Quick Start)

This is what we'll set up first for testing:

#### 2.1: Create Lab Order in OpenMRS

1. **Login to OpenMRS:**
   - URL: http://localhost/openmrs/spa/
   - User: admin / Admin123

2. **Select a patient** (or register new one)

3. **Click "Start Visit"** if patient doesn't have active visit

4. **Order a lab test:**
   - In patient dashboard, find "Orders" or "Lab Tests"
   - Click "Add Lab Order"
   - Select test (e.g., "Complete Blood Count")
   - Save order

5. **Note the Order ID**

#### 2.2: Manually Enter Sample in OpenELIS

1. **Login to OpenELIS:**
   - URL: http://localhost:8090/
   - User: admin / adminADMIN!

2. **Navigate to "Sample Collection"**

3. **Create new sample:**
   - Enter patient details (matching OpenMRS)
   - Select test type (matching order)
   - Generate sample ID
   - Save

4. **Process sample:**
   - Go to "Results Entry"
   - Find the sample
   - Enter results
   - Validate results

#### 2.3: View Results in OpenELIS

- Navigate to "Reports"
- View/print diagnostic report
- Note the accession number

#### 2.4: Verify Order via FHIR

```bash
# Check ServiceRequest in OpenMRS
curl -u admin:Admin123 "http://localhost/openmrs/ws/fhir2/R4/ServiceRequest" | grep -A 20 "Blood"

# Check if OpenELIS has the order (if FHIR sync is working) - HTTPS only
curl -k "https://localhost:8544/fhir/ServiceRequest"
```

---

### Step 3: Option C - Automated Integration (Advanced)

To fully automate the lab integration, you need to install the OpenELIS module:

#### 3.1: Access OpenMRS Admin Panel

1. **Login to OpenMRS Legacy Admin:**
   - URL: http://localhost/openmrs/admin
   - User: admin / Admin123

2. **Navigate to "Manage Modules"**

#### 3.2: Install OpenELIS Module

**Method 1: Via Module Manager (if available)**
- Click "Add or Upgrade Module"
- Upload `.omod` file or enter URL
- Start module

**Method 2: Via Docker Volume (Recommended)**

The OpenELIS module needs to be added to your OpenMRS backend. Let me create a setup script:

```bash
# Download OpenELIS module (you'll need to find the .omod file)
# Place it in: openmrs-distro-referenceapplication/modules/

# Restart OpenMRS backend
cd openmrs-distro-referenceapplication
docker compose restart backend
```

#### 3.3: Configure OpenELIS Module

After installing the module, configure it:

1. **Go to:** Administration → OpenELIS Configuration

2. **Set OpenELIS FHIR API URL:**
   ```
   https://external-fhir-api:8443/fhir/
   ```
   **Note:** Use HTTPS URL (port 8443), not HTTP. Configure module to ignore self-signed certificates.

3. **Configure Authentication:**
   - If OpenELIS FHIR requires auth, add credentials
   - For now, it may work without auth

4. **Map Lab Tests:**
   - Map OpenMRS concepts to OpenELIS tests
   - Example: OpenMRS "CBC" → OpenELIS "Complete Blood Count"

5. **Enable Auto-Send:**
   - Check "Automatically send orders to OpenELIS"
   - Save configuration

---

## Part 2: OpenMRS ↔ PACS Integration

### Step 1: Understanding PACS Integration Options

#### **Option A: Manual Integration (Current State)** ✅
- View images directly in PACS web interface
- Manually link to patient records
- **Best for:** Testing, small clinics

#### **Option B: Radiology Module Integration** ⭐ (Recommended)
- Install OpenMRS Radiology module
- DICOM worklist integration
- Embedded PACS viewer in OpenMRS
- **Best for:** Production environments

---

### Step 2: Option A - Manual PACS Integration

#### 2.1: Upload Test Image to PACS

**If you have a DICOM file:**
```bash
# Upload via command line
curl -u orthanc:orthanc -X POST http://localhost:8042/instances \
  --data-binary @sample.dcm
```

**Or via Web UI:**
1. Go to: http://localhost:8042/
2. Login: orthanc / orthanc
3. Click "Upload" button
4. Select DICOM file
5. View uploaded image

#### 2.2: Link to Patient

1. **Note PACS Patient ID** from uploaded image

2. **In OpenMRS:**
   - Find corresponding patient
   - Add a "Radiology Note" or clinical note
   - Include link to PACS: `http://localhost:8042/app/explorer.html#patient?uuid={patient-id}`

---

### Step 3: Option B - Automated PACS Integration (Advanced)

#### 3.1: Install Radiology Module

1. **Download Radiology Module:**
   - From: https://addons.openmrs.org/
   - Search for "Radiology" module
   - Download `.omod` file

2. **Install Module:**
   - Go to: http://localhost/openmrs/admin
   - Navigate to: Manage Modules
   - Upload `.omod` file
   - Start module

#### 3.2: Configure PACS Connection

1. **Go to:** Administration → Radiology → Settings

2. **PACS Configuration:**
   ```
   PACS Server: orthanc-pacs
   PACS Port: 4242
   PACS AET: ORTHANC
   Local AET: OPENMRS
   DICOM Web Viewer: http://orthanc-pacs:8042/
   ```

3. **Test Connection:**
   - Click "Test Connection"
   - Should show "Connected successfully"

4. **Configure Modalities:**
   - Add imaging modalities (X-Ray, CT, MRI)
   - Map to PACS

---

## Part 3: Testing Integrated Workflows

### Test 1: Lab Order End-to-End

#### Automated Flow (if OpenELIS module installed):

1. **In OpenMRS:**
   - Register patient: "Test Integration"
   - Start visit
   - Order lab test: "Complete Blood Count"
   - Save order

2. **Verify in OpenELIS:**
   - Login to OpenELIS
   - Check "Sample Collection" or "Orders"
   - **Expected:** Order appears automatically with patient details

3. **Process in OpenELIS:**
   - Enter results
   - Validate results
   - Mark as complete

4. **Check Results in OpenMRS:**
   - Go back to patient dashboard
   - **Expected:** Results appear in "Lab Results" section

#### Manual Flow (current state):

Follow Steps 2.1 - 2.4 from Part 1 above.

---

### Test 2: Radiology Order End-to-End

#### Automated Flow (if Radiology module installed):

1. **In OpenMRS:**
   - Select patient
   - Order imaging: "Chest X-Ray"
   - Save order

2. **PACS Worklist:**
   - Order appears in PACS worklist
   - Technician selects from worklist

3. **Imaging Device:**
   - Performs X-Ray
   - Sends DICOM to PACS (C-STORE)

4. **View in OpenMRS:**
   - Click on radiology order
   - Embedded viewer shows image from PACS

#### Manual Flow (current state):

1. **Upload image to PACS** (see Part 2, Step 2.1)
2. **View in PACS:** http://localhost:8042/
3. **Manually note in OpenMRS** patient record

---

## Quick Reference: API Endpoints

### OpenMRS FHIR API

```bash
# Base URL (from host)
http://localhost/openmrs/ws/fhir2/R4/

# Base URL (inter-container)
http://openmrs-distro-referenceapplication-backend-1:8080/openmrs/ws/fhir2/R4/

# Authentication
-u admin:Admin123

# Example: Get all patients
curl -u admin:Admin123 "http://localhost/openmrs/ws/fhir2/R4/Patient"

# Example: Create ServiceRequest (lab order)
curl -u admin:Admin123 -X POST \
  "http://localhost/openmrs/ws/fhir2/R4/ServiceRequest" \
  -H "Content-Type: application/fhir+json" \
  -d @service-request.json
```

### OpenELIS FHIR API

```bash
# Base URL (from host) - HTTPS only
https://localhost:8544/fhir/

# Base URL (inter-container) - HTTPS only
https://external-fhir-api:8443/fhir/

# Authentication
# Currently no auth required for FHIR endpoints

# Important: Always use -k flag to ignore self-signed certificates

# Example: Get capability statement
curl -k "https://localhost:8544/fhir/metadata"

# Example: Get ServiceRequests
curl -k "https://localhost:8544/fhir/ServiceRequest"

# Example: Get DiagnosticReports
curl -k "https://localhost:8544/fhir/DiagnosticReport"
```

**⚠️ Important Notes:**
- OpenELIS FHIR API **only responds on HTTPS** (ports 8544 host, 8443 container)
- HTTP port 8081 is mapped but service doesn't listen on it
- Always use `-k` flag with curl to ignore self-signed certificates
- For inter-container communication, use `https://external-fhir-api:8443/fhir/`

### PACS REST API

```bash
# Base URL (from host)
http://localhost:8042/

# Base URL (inter-container)
http://orthanc-pacs:8042/

# Authentication
-u orthanc:orthanc

# Example: Get all patients
curl -u orthanc:orthanc "http://localhost:8042/patients"

# Example: Upload DICOM
curl -u orthanc:orthanc -X POST \
  "http://localhost:8042/instances" \
  --data-binary @image.dcm

# Example: Get studies
curl -u orthanc:orthanc "http://localhost:8042/studies"
```

---

## Troubleshooting Integration Issues

### Issue: Orders not appearing in OpenELIS

**Check:**
1. Is OpenELIS FHIR API accessible?
   ```bash
   curl "http://localhost:8081/fhir/metadata"
   ```

2. Is OpenELIS module installed in OpenMRS?
   - Go to: http://localhost/openmrs/admin/modules/module.list
   - Look for "OpenELIS" module

3. Check OpenMRS logs:
   ```bash
   docker logs openmrs-distro-referenceapplication-backend-1 | grep -i "openelis\|fhir"
   ```

4. Check OpenELIS FHIR logs:
   ```bash
   docker logs external-fhir-api | tail -50
   ```

**Solution:**
- Verify FHIR endpoint configuration
- Check network connectivity
- Ensure authentication is correct

---

### Issue: PACS not receiving images

**Check:**
1. Is PACS accessible?
   ```bash
   curl -u orthanc:orthanc "http://localhost:8042/system"
   ```

2. Is DICOM port open?
   ```bash
   netstat -an | findstr :4242
   ```

3. Check PACS logs:
   ```bash
   docker logs orthanc-pacs | tail -50
   ```

**Solution:**
- Verify DICOM AET configuration
- Check firewall rules
- Ensure imaging device is configured with correct AET

---

### Issue: Results not syncing back to OpenMRS

**Check:**
1. Does OpenELIS have correct OpenMRS FHIR endpoint?
2. Is authentication configured for result push?
3. Check if DiagnosticReport is created in OpenELIS:
   ```bash
   curl "http://localhost:8081/fhir/DiagnosticReport"
   ```

**Solution:**
- Configure OpenELIS to push results to OpenMRS FHIR API
- May require custom integration layer

---

## Integration Roadmap

### Phase 1: Manual Integration (Current)
- ✅ All systems running on shared network
- ✅ Manual order entry
- ✅ Manual result viewing
- ⏱️ **Estimated time:** Completed

### Phase 2: Semi-Automated Integration
- ⬜ Install OpenELIS module in OpenMRS
- ⬜ Configure FHIR endpoints
- ⬜ Test automated order sending
- ⏱️ **Estimated time:** 2-4 hours

### Phase 3: Full Integration
- ⬜ Install Radiology module
- ⬜ Configure PACS DICOM integration
- ⬜ Set up result auto-retrieval
- ⬜ Configure patient matching
- ⏱️ **Estimated time:** 4-8 hours

### Phase 4: Production Hardening
- ⬜ Enable HTTPS for all services
- ⬜ Configure proper authentication
- ⬜ Set up database backups
- ⬜ Configure monitoring/alerting
- ⬜ Security audit
- ⏱️ **Estimated time:** 1-2 days

---

## Next Steps

### For Testing (Current Phase):

1. **Test manual workflows:**
   - Create lab order in OpenMRS
   - Manually enter in OpenELIS
   - Upload image to PACS
   - View results in each system

2. **Verify FHIR APIs:**
   - Check ServiceRequests in both systems
   - Verify DiagnosticReports
   - Test Patient sync

### For Full Integration:

1. **Download required modules:**
   - OpenELIS module for OpenMRS
   - Radiology module for OpenMRS

2. **Follow installation guides** in this document

3. **Test automated workflows**

4. **Configure production settings**

---

## Resources

### Documentation
- **OpenMRS O3:** https://wiki.openmrs.org/
- **OpenELIS:** https://docs.openelis-global.org/
- **Orthanc PACS:** https://book.orthanc-server.com/
- **FHIR R4:** https://hl7.org/fhir/R4/

### Module Downloads
- **OpenMRS Add-ons:** https://addons.openmrs.org/
- **OpenELIS GitHub:** https://github.com/I-TECH-UW/OpenELIS-Global-2

### Support
- **OpenMRS Talk:** https://talk.openmrs.org/
- **OpenELIS Issues:** https://github.com/I-TECH-UW/OpenELIS-Global-2/issues
- **Orthanc Forum:** https://discourse.orthanc-server.org/

---

**Last Updated:** 2025-11-24
**Integration Status:** Phase 1 Complete (Manual Integration)
**Next Milestone:** Phase 2 (Semi-Automated Integration)