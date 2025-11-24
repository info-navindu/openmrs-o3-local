# HMIS Integration Testing Guide

## Overview

This Health Management Information System (HMIS) integrates three independent healthcare systems:

1. **OpenMRS O3** - Electronic Medical Records (EMR)
2. **OpenELIS Global** - Laboratory Information Management System (LIMS)
3. **Orthanc PACS** - Picture Archiving and Communication System (Radiology)

All systems communicate via a shared Docker network (`hmis-network`) for seamless data exchange.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     hmis-network                        │
│  (172.22.0.0/16)                                        │
│                                                         │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────┐ │
│  │  OpenMRS O3  │   │  OpenELIS    │   │  Orthanc   │ │
│  │              │   │              │   │    PACS    │ │
│  │  - Gateway   │   │  - Webapp    │   │            │ │
│  │  - Frontend  │◄──┤  - FHIR API  │   │  - DICOM   │ │
│  │  - Backend   │   │  - Database  │   │  - Web UI  │ │
│  │  - Database  │   │  - Proxy     │   │            │ │
│  └──────────────┘   └──────────────┘   └────────────┘ │
│         │                   │                  │        │
│    Port 80/443         Port 8090         Port 8042     │
│                        Port 8544 (FHIR)  Port 4242     │
│                        HTTPS only        DICOM         │
└─────────────────────────────────────────────────────────┘
```

---

## System Access

### OpenMRS O3 (EMR)

- **Web UI:** http://localhost/openmrs/spa/
- **Login URL:** http://localhost/openmrs/spa/login
- **Default Credentials:**
  - Username: `admin`
  - Password: `Admin123`
- **API Base:** http://localhost/openmrs/ws/rest/v1/
- **Backend Port:** Internal only (8080)

### OpenELIS Global (Lab)

- **Web UI:** http://localhost:8090/
- **Default Credentials:**
  - Username: `admin`
  - Password: `adminADMIN!`
- **FHIR API (HTTPS):** https://localhost:8544/fhir/
  - **Note:** Use `-k` flag with curl to ignore self-signed certificate
  - HTTP port 8081 is mapped but service only listens on HTTPS
- **Internal Webapp:** Port 8082 (container only)
- **Database:** PostgreSQL on port 15432 (external access)

### Orthanc PACS (Radiology)

- **Web UI:** http://localhost:8042/
- **Default Credentials:**
  - Username: `orthanc`
  - Password: `orthanc`
  - Admin: `admin` / `admin123`
- **DICOM Port:** 4242
- **AET (Application Entity Title):** `ORTHANC`
- **REST API:** http://localhost:8042/

---

## Pre-Integration Checks

### 1. Verify All Containers Are Running

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected containers:**
- `openmrs-distro-referenceapplication-gateway-1`
- `openmrs-distro-referenceapplication-frontend-1`
- `openmrs-distro-referenceapplication-backend-1`
- `openmrs-distro-referenceapplication-db-1`
- `openelisglobal-webapp`
- `external-fhir-api`
- `openelisglobal-front-end`
- `openelisglobal-database`
- `openelisglobal-proxy`
- `orthanc-pacs`
- `oe-certs`

### 2. Verify Shared Network Connectivity

```bash
# Check all containers are on hmis-network
docker network inspect hmis-network --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}'
```

### 3. Test Web Access

Open each system in your browser:
- OpenMRS: http://localhost/openmrs/spa/
- OpenELIS: http://localhost:8090/
- PACS: http://localhost:8042/

---

## Integration Testing Scenarios

### Scenario 1: Network Connectivity Test

**Objective:** Verify containers can communicate with each other

**Steps:**

1. **Test OpenMRS → OpenELIS FHIR API**
   ```bash
   docker exec openmrs-distro-referenceapplication-backend-1 curl -s -k https://external-fhir-api:8443/fhir/metadata
   ```
   **Expected:** FHIR CapabilityStatement JSON response
   **Note:** FHIR API uses HTTPS (port 8443), use `-k` to ignore self-signed cert

2. **Test OpenMRS → PACS Web API**
   ```bash
   docker exec openmrs-distro-referenceapplication-backend-1 curl -s -u orthanc:orthanc http://orthanc-pacs:8042/system
   ```
   **Expected:** Orthanc system information JSON

3. **Test OpenELIS → PACS API**
   ```bash
   docker exec openelisglobal-webapp curl -s -u orthanc:orthanc http://orthanc-pacs:8042/patients
   ```
   **Expected:** List of patients (may be empty initially)

**Success Criteria:** All curl commands return JSON responses without connection errors

---

### Scenario 2: Lab Order Workflow (OpenMRS ↔ OpenELIS)

**Objective:** Test lab order creation and result retrieval via FHIR

#### 2.1 Create Patient in OpenMRS

1. Log into OpenMRS: http://localhost/openmrs/spa/
2. Click "Register a patient"
3. Fill in patient details:
   - Given Name: `John`
   - Family Name: `Doe`
   - Gender: `Male`
   - Date of Birth: `1990-01-01`
4. Click "Confirm" to register

#### 2.2 Verify FHIR Patient Resource

```bash
# Get OpenMRS FHIR patients
curl http://localhost/openmrs/ws/fhir2/R4/Patient | jq
```

**Expected:** Patient "John Doe" appears in response

#### 2.3 Test OpenELIS FHIR Connectivity

```bash
# Test OpenELIS FHIR API is accessible (HTTPS only)
curl -k https://localhost:8544/fhir/metadata | jq '.fhirVersion'
```

**Expected:** Returns `"4.0.1"` (FHIR R4)
**Note:** Use `-k` to ignore self-signed certificate warnings

#### 2.4 Create Lab Order in OpenMRS

1. In OpenMRS, search for patient "John Doe"
2. Click "Lab Orders" or "Order Tests"
3. Select a lab test (e.g., "Complete Blood Count")
4. Submit the order

#### 2.5 Verify Order Sent to OpenELIS

1. Log into OpenELIS: http://localhost:8090/
2. Navigate to "Sample Collection" or "Orders"
3. Check if the lab order for "John Doe" appears

**Manual API Check:**
```bash
# Query OpenELIS FHIR for ServiceRequests
curl http://localhost:8081/fhir/ServiceRequest | jq
```

**Success Criteria:**
- Order created in OpenMRS
- Order appears in OpenELIS via FHIR API
- No errors in container logs

---

### Scenario 3: Radiology Workflow (OpenMRS ↔ PACS)

**Objective:** Test radiology order creation and DICOM image storage

#### 3.1 Create Radiology Order in OpenMRS

1. Log into OpenMRS
2. Search for a patient
3. Click "Radiology Orders" or "Order Imaging"
4. Select imaging type (e.g., "Chest X-Ray")
5. Submit the order

#### 3.2 Check DICOM Worklist in PACS

```bash
# Query PACS for worklist items
curl -u orthanc:orthanc http://localhost:8042/modalities/worklist | jq
```

**Note:** This requires OpenMRS Radiology Module configured to send DICOM worklist

#### 3.3 Upload Test DICOM Image

If you have a test DICOM file, upload it to PACS:

```bash
# Upload DICOM file to PACS
curl -u orthanc:orthanc -X POST http://localhost:8042/instances \
  --data-binary @test-image.dcm
```

**Or use the Web UI:**
1. Go to http://localhost:8042/
2. Click "Upload"
3. Select a DICOM file
4. View the uploaded image in the PACS viewer

#### 3.4 View Images from OpenMRS

Configure OpenMRS to display PACS images:
1. Install OpenMRS Radiology Module (if not installed)
2. Configure PACS viewer URL: `http://localhost:8042/`
3. Click on radiology order to view images

**Success Criteria:**
- Radiology order created in OpenMRS
- DICOM images viewable in PACS
- Images accessible from OpenMRS interface

---

### Scenario 4: End-to-End Patient Journey

**Objective:** Test complete workflow from registration to results

1. **Register patient in OpenMRS**
2. **Create encounter** (e.g., Outpatient Visit)
3. **Order lab tests** → Verify in OpenELIS
4. **Order X-ray** → Verify in PACS
5. **Process lab sample in OpenELIS** → Enter results
6. **Upload X-ray to PACS** → View image
7. **Check results in OpenMRS** → Verify lab and radiology results appear

---

## Troubleshooting

### Issue: Cannot Access OpenELIS (http://localhost:8090/)

**Check:**
```bash
docker ps | grep openelis
docker logs openelisglobal-proxy
docker logs openelisglobal-webapp
```

**Solution:**
- Ensure all OpenELIS containers are running
- Check if port 8090 is available: `netstat -ano | findstr :8090`
- Restart OpenELIS: `cd OpenELIS-Global-2 && docker compose restart`

---

### Issue: Cannot Access PACS (http://localhost:8042/)

**Check:**
```bash
docker ps | grep orthanc
docker logs orthanc-pacs
```

**Solution:**
- Verify container is running
- Check port 8042: `netstat -ano | findstr :8042`
- Restart PACS: `cd orthanc-pacs && docker compose restart`

---

### Issue: Containers Cannot Communicate

**Check Network:**
```bash
docker network inspect hmis-network
```

**Verify Container Names:**
```bash
docker ps --format "{{.Names}}"
```

**Test Connectivity:**
```bash
# From OpenMRS backend to OpenELIS FHIR
docker exec openmrs-distro-referenceapplication-backend-1 ping -c 3 external-fhir-api

# From OpenMRS backend to PACS
docker exec openmrs-distro-referenceapplication-backend-1 ping -c 3 orthanc-pacs
```

**Solution:**
- Recreate network: `docker network rm hmis-network && docker network create hmis-network`
- Restart all systems

---

### Issue: FHIR API Not Accessible

**Check OpenELIS FHIR API:**
```bash
# Try HTTPS (correct)
curl -k https://localhost:8544/fhir/metadata

# HTTP port 8081 won't work - service only listens on HTTPS
```

**Check Container:**
```bash
docker logs external-fhir-api
```

**Solution:**
- FHIR API only responds on HTTPS port 8544 (or 8443 internally)
- Always use `-k` flag to ignore self-signed certificates
- HTTP port 8081 is mapped but service doesn't bind to it
- Restart if needed: `cd OpenELIS-Global-2 && docker compose restart fhir.openelis.org`

---

## Container Inter-Communication Reference

### From OpenMRS Backend

```bash
# Access OpenELIS FHIR API (HTTPS only)
https://external-fhir-api:8443/fhir/

# Access OpenELIS Webapp
http://openelisglobal-webapp:8080/

# Access PACS REST API
http://orthanc-pacs:8042/

# Access PACS DICOM
orthanc-pacs:4242 (AET: ORTHANC)
```

**Note:** OpenELIS FHIR uses HTTPS (port 8443). Use `-k` with curl to ignore self-signed certificates.

### From OpenELIS

```bash
# Access OpenMRS FHIR API
http://openmrs-distro-referenceapplication-backend-1:8080/openmrs/ws/fhir2/R4/

# Access PACS
http://orthanc-pacs:8042/
```

### From PACS

```bash
# Access OpenMRS
http://openmrs-distro-referenceapplication-backend-1:8080/openmrs/

# Access OpenELIS
http://openelisglobal-webapp:8080/
```

---

## API Testing Examples

### OpenMRS FHIR API

```bash
# Get all patients
curl http://localhost/openmrs/ws/fhir2/R4/Patient | jq

# Get patient by ID
curl http://localhost/openmrs/ws/fhir2/R4/Patient/{uuid} | jq

# Get encounters
curl http://localhost/openmrs/ws/fhir2/R4/Encounter | jq

# Get observations (lab results)
curl http://localhost/openmrs/ws/fhir2/R4/Observation | jq
```

### OpenELIS FHIR API

```bash
# Get FHIR capability statement (HTTPS only)
curl -k https://localhost:8544/fhir/metadata | jq

# Get patients
curl -k https://localhost:8544/fhir/Patient | jq

# Get service requests (lab orders)
curl -k https://localhost:8544/fhir/ServiceRequest | jq

# Get diagnostic reports (lab results)
curl -k https://localhost:8544/fhir/DiagnosticReport | jq

# Get observations
curl -k https://localhost:8544/fhir/Observation | jq
```

**Note:** OpenELIS FHIR API only responds on HTTPS (port 8544). Use `-k` flag to ignore self-signed certificates.

### Orthanc PACS REST API

```bash
# Get system info
curl -u orthanc:orthanc http://localhost:8042/system | jq

# List all patients
curl -u orthanc:orthanc http://localhost:8042/patients | jq

# List all studies
curl -u orthanc:orthanc http://localhost:8042/studies | jq

# Get study details
curl -u orthanc:orthanc http://localhost:8042/studies/{study-id} | jq

# List all instances
curl -u orthanc:orthanc http://localhost:8042/instances | jq
```

---

## Monitoring and Logs

### View All Container Logs

```bash
# OpenMRS
cd openmrs-distro-referenceapplication
docker compose logs -f

# OpenELIS
cd ../OpenELIS-Global-2
docker compose logs -f

# PACS
cd ../orthanc-pacs
docker compose logs -f
```

### View Specific Container Logs

```bash
# OpenMRS backend
docker logs -f openmrs-distro-referenceapplication-backend-1

# OpenELIS webapp
docker logs -f openelisglobal-webapp

# OpenELIS FHIR API
docker logs -f external-fhir-api

# PACS
docker logs -f orthanc-pacs
```

### Monitor Network Traffic

```bash
# Monitor network connections
docker network inspect hmis-network

# Check container stats
docker stats
```

---

## Starting and Stopping the Integrated HMIS

### Start All Systems

```bash
# Start OpenMRS
cd C:/Users/NavinduGunawardena/openmrs-o3-local/openmrs-distro-referenceapplication
docker compose up -d

# Start OpenELIS
cd ../OpenELIS-Global-2
docker compose up -d

# Start PACS
cd ../orthanc-pacs
docker compose up -d
```

### Stop All Systems

```bash
# Stop OpenMRS
cd C:/Users/NavinduGunawardena/openmrs-o3-local/openmrs-distro-referenceapplication
docker compose down

# Stop OpenELIS
cd ../OpenELIS-Global-2
docker compose down

# Stop PACS
cd ../orthanc-pacs
docker compose down
```

### Restart All Systems

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

---

## Next Steps for Full Integration

### 1. Configure OpenMRS Modules

Install and configure OpenMRS modules for integration:

**OpenELIS Module:**
- Install OpenELIS module in OpenMRS
- Configure FHIR endpoint: `https://external-fhir-api:8443/fhir/`
- **Important:** Use HTTPS URL, not HTTP
- Configure to ignore self-signed certificates in module settings
- Map lab tests between OpenMRS and OpenELIS

**Radiology Module:**
- Install Radiology module in OpenMRS
- Configure PACS connection:
  - Server: `orthanc-pacs`
  - Port: `4242`
  - AET: `ORTHANC`
  - Viewer URL: `http://orthanc-pacs:8042/`

### 2. Configure OpenELIS Integration

- Configure OpenELIS to receive orders from OpenMRS
- Set up result reporting back to OpenMRS via FHIR
- Configure analyzer integration if using lab equipment

### 3. Configure PACS Integration

- Set up DICOM worklist in Orthanc
- Configure imaging devices to send images to PACS
- Set up DICOM query/retrieve for OpenMRS

### 4. Test Data Synchronization

- Create test patients across all systems
- Verify patient matching/linking
- Test order → result workflows
- Monitor for errors and latency

---

## Security Considerations

### Production Deployment

**⚠️ IMPORTANT: This is a development setup. For production:**

1. **Change all default passwords**
   - OpenMRS admin password
   - OpenELIS admin password
   - PACS orthanc/admin passwords
   - Database passwords

2. **Enable HTTPS**
   - Configure SSL certificates for all services
   - Enable HTTPS-only access
   - Update nginx configurations

3. **Restrict network access**
   - Use firewall rules to limit external access
   - Expose only necessary ports
   - Use VPN for administrative access

4. **Database security**
   - Use strong database passwords
   - Enable database encryption
   - Set up regular backups
   - Restrict database port access

5. **Authentication**
   - Integrate with hospital AD/LDAP
   - Enable MFA for admin accounts
   - Implement role-based access control

6. **Audit logging**
   - Enable audit logs in all systems
   - Set up centralized log monitoring
   - Configure alerts for suspicious activity

---

## Support and Resources

### Documentation

- **OpenMRS:** https://wiki.openmrs.org/
- **OpenELIS:** https://docs.openelis-global.org/
- **Orthanc PACS:** https://book.orthanc-server.com/

### API Documentation

- **OpenMRS FHIR:** https://wiki.openmrs.org/display/projects/FHIR+Module
- **OpenELIS FHIR:** https://localhost:8544/fhir/ (HTTPS only)
- **Orthanc REST:** https://api.orthanc-server.com/

### Community

- **OpenMRS Talk:** https://talk.openmrs.org/
- **OpenELIS GitHub:** https://github.com/I-TECH-UW/OpenELIS-Global-2
- **Orthanc Forum:** https://discourse.orthanc-server.org/

---

**Last Updated:** 2025-11-24
**System Version:**
- OpenMRS O3: qa (reference application)
- OpenELIS Global: develop
- Orthanc PACS: latest (jodogne/orthanc-plugins)