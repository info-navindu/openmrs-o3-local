# Comprehensive Docker Setup Guide for HMIS Integration

## Project Overview

Your repository contains three integrated healthcare systems:

```
openmrs-o3-local/
├── openmrs-distro-referenceapplication/  # OpenMRS O3 (EMR)
├── OpenELIS-Global-2/                     # OpenELIS (Laboratory Information System)
├── orthanc-pacs/                          # Orthanc PACS (Medical Imaging)
├── docker-compose.integration.yml         # Integration network config
└── INTEGRATION-SETUP-GUIDE.md            # Detailed integration docs
```

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│           HMIS Network (hmis-network)               │
│                                                     │
│  ┌─────────────┐    ┌──────────────┐              │
│  │ OpenMRS O3  │◄──►│  OpenELIS    │              │
│  │   (EMR)     │    │   (LIMS)     │              │
│  │ Port: 80    │    │ Port: 8090   │              │
│  └──────┬──────┘    └──────────────┘              │
│         │                                          │
│         │ DICOM                                    │
│         ▼                                          │
│  ┌─────────────┐                                  │
│  │   Orthanc   │                                  │
│  │    PACS     │                                  │
│  │ Port: 8042  │                                  │
│  └─────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Docker & Docker Compose**
   - Docker Engine 20.10+
   - Docker Compose v2.0+

2. **System Resources**
   - RAM: Minimum 8GB (16GB recommended)
   - Disk Space: 20GB+ free space
   - CPU: 4+ cores recommended

3. **Ports Required** (ensure these are free):
   - 80 (OpenMRS HTTP)
   - 4242 (PACS DICOM)
   - 8042 (PACS Web UI)
   - 8081, 8082, 8090, 8543-8545 (OpenELIS services)
   - 15432 (OpenELIS PostgreSQL)

## Step-by-Step Setup

### Step 1: Create the Shared Network

All three systems communicate via a shared Docker network called `hmis-network`.

```bash
# Navigate to project root
cd C:\Users\NavinduGunawardena\openmrs-o3-local

# Create the shared network
docker network create hmis-network

# Verify network creation
docker network ls | findstr hmis-network
```

**Expected output:**
```
hmis-network   bridge    local
```

### Step 2: Start OpenMRS O3 (EMR System)

OpenMRS is the Electronic Medical Records system.

```bash
# Navigate to OpenMRS directory
cd openmrs-distro-referenceapplication

# Start OpenMRS services
docker compose up -d

# Monitor startup (this takes 3-5 minutes on first run)
docker compose logs -f backend
```

**Wait for this message:**
```
Started OpenMRS successfully
```

Press `Ctrl+C` to exit logs.

**Access OpenMRS:**
- **Modern UI**: http://localhost/openmrs/spa
- **Legacy Admin**: http://localhost/openmrs
- **Credentials**:
  - Username: `admin`
  - Password: `Admin123`

### Step 3: Start OpenELIS (Laboratory System)

OpenELIS handles laboratory orders and results.

```bash
# Navigate back to project root
cd ..

# Go to OpenELIS directory
cd OpenELIS-Global-2

# Start OpenELIS services
docker compose up -d

# Monitor startup (takes 2-3 minutes)
docker compose logs -f oe.openelis.org
```

**Wait for this message:**
```
Server startup in [X] milliseconds
```

Press `Ctrl+C` to exit logs.

**Access OpenELIS:**
- **Web UI**: http://localhost:8090
- **Credentials**:
  - Username: `admin`
  - Password: `adminADMIN!`

### Step 4: Start Orthanc PACS (Medical Imaging)

Orthanc manages medical images (X-rays, CT scans, MRI).

```bash
# Navigate back to project root
cd ..

# Go to PACS directory
cd orthanc-pacs

# Start PACS service
docker compose up -d

# Check logs
docker compose logs -f
```

**Wait for this message:**
```
Orthanc has started
```

Press `Ctrl+C` to exit logs.

**Access PACS:**
- **Web UI**: http://localhost:8042
- **Credentials**:
  - Username: `orthanc`
  - Password: `orthanc`
  - Admin: `admin` / `admin123`
- **DICOM Port**: 4242 (AET: ORTHANC)

## Verification & Health Checks

### Verify All Containers Are Running

```bash
# Navigate to project root
cd C:\Users\NavinduGunawardena\openmrs-o3-local

# Check all running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected containers (11 total):**
1. `openmrs-distro-referenceapplication-gateway-1`
2. `openmrs-distro-referenceapplication-frontend-1`
3. `openmrs-distro-referenceapplication-backend-1`
4. `openmrs-distro-referenceapplication-db-1`
5. `openelisglobal-webapp`
6. `openelisglobal-database`
7. `external-fhir-api`
8. `openelisglobal-front-end`
9. `openelisglobal-proxy`
10. `oe-certs`
11. `orthanc-pacs`

### Verify Network Connectivity

```bash
# Check all containers on hmis-network
docker network inspect hmis-network --format "{{json .Containers}}"
```

### Test FHIR API Endpoints

```bash
# Test OpenMRS FHIR API
curl -u admin:Admin123 "http://localhost/openmrs/ws/fhir2/R4/metadata"

# Test OpenELIS FHIR API (HTTPS only, use -k for self-signed cert)
curl -k "https://localhost:8544/fhir/metadata"

# Test PACS REST API
curl -u orthanc:orthanc "http://localhost:8042/system"
```

## System Access Summary

| System | URL | Username | Password | Purpose |
|--------|-----|----------|----------|---------|
| **OpenMRS O3** | http://localhost/openmrs/spa | admin | Admin123 | Patient records, orders |
| **OpenMRS Legacy** | http://localhost/openmrs | admin | Admin123 | Admin & configuration |
| **OpenELIS** | http://localhost:8090 | admin | adminADMIN! | Lab tests & results |
| **Orthanc PACS** | http://localhost:8042 | orthanc | orthanc | Medical imaging |

## Integration Endpoints

### OpenMRS FHIR API
- **External**: http://localhost/openmrs/ws/fhir2/R4/
- **Inter-container**: http://openmrs-distro-referenceapplication-backend-1:8080/openmrs/ws/fhir2/R4/
- **Auth**: Basic (admin:Admin123)

### OpenELIS FHIR API
- **External**: https://localhost:8544/fhir/
- **Inter-container**: https://external-fhir-api:8443/fhir/
- **Auth**: None (currently)
- **Note**: HTTPS only, use `-k` flag with curl

### PACS REST API
- **External**: http://localhost:8042/
- **Inter-container**: http://orthanc-pacs:8042/
- **Auth**: Basic (orthanc:orthanc)

### PACS DICOM
- **Port**: 4242
- **AET**: ORTHANC
- **Protocol**: DICOM C-STORE, C-FIND, C-MOVE

## Common Operations

### Stop All Systems

```bash
# Stop OpenMRS
cd openmrs-distro-referenceapplication
docker compose down

# Stop OpenELIS
cd ../OpenELIS-Global-2
docker compose down

# Stop PACS
cd ../orthanc-pacs
docker compose down
```

### Start All Systems (After Initial Setup)

```bash
cd C:\Users\NavinduGunawardena\openmrs-o3-local

# Start OpenMRS
cd openmrs-distro-referenceapplication && docker compose up -d && cd ..

# Start OpenELIS
cd OpenELIS-Global-2 && docker compose up -d && cd ..

# Start PACS
cd orthanc-pacs && docker compose up -d && cd ..
```

### View Logs

```bash
# OpenMRS logs
docker logs openmrs-distro-referenceapplication-backend-1 -f

# OpenELIS logs
docker logs openelisglobal-webapp -f

# PACS logs
docker logs orthanc-pacs -f
```

### Restart Individual Systems

```bash
# Restart OpenMRS backend only
docker compose -f openmrs-distro-referenceapplication/docker-compose.yml restart backend

# Restart OpenELIS webapp only
docker compose -f OpenELIS-Global-2/docker-compose.yml restart oe.openelis.org

# Restart PACS
docker compose -f orthanc-pacs/docker-compose.yml restart pacs
```

## Troubleshooting

### Issue: Port Already in Use

```bash
# Find what's using port 80 (example)
netstat -ano | findstr :80

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Issue: Container Won't Start

```bash
# Check container logs
docker logs <container-name>

# Remove and recreate container
docker compose down
docker compose up -d
```

### Issue: Network Connection Failed

```bash
# Verify network exists
docker network ls | findstr hmis-network

# Recreate network if missing
docker network rm hmis-network
docker network create hmis-network

# Restart all services
```

### Issue: Database Initialization Stuck

```bash
# For OpenMRS
docker compose -f openmrs-distro-referenceapplication/docker-compose.yml down -v
docker compose -f openmrs-distro-referenceapplication/docker-compose.yml up -d

# For OpenELIS
docker compose -f OpenELIS-Global-2/docker-compose.yml down -v
docker compose -f OpenELIS-Global-2/docker-compose.yml up -d
```

⚠️ **Warning**: Using `-v` flag deletes all data volumes!

### Issue: Out of Memory

```bash
# Check Docker resource usage
docker stats

# Increase Docker Desktop memory allocation:
# Docker Desktop → Settings → Resources → Memory → Increase to 8GB+
```

## Data Persistence

All systems use Docker volumes for data persistence:

```bash
# List all volumes
docker volume ls | findstr -i "openmrs\|openelis\|orthanc"

# Backup a volume (example: PACS storage)
docker run --rm -v orthanc-pacs_orthanc-storage:/data -v %cd%:/backup alpine tar czf /backup/pacs-backup.tar.gz -C /data .

# Restore a volume
docker run --rm -v orthanc-pacs_orthanc-storage:/data -v %cd%:/backup alpine tar xzf /backup/pacs-backup.tar.gz -C /data
```

## Quick Test Workflow

### 1. Create a Patient in OpenMRS

1. Go to http://localhost/openmrs/spa
2. Login (admin/Admin123)
3. Click "Register Patient"
4. Fill in patient details
5. Save

### 2. Create Lab Order in OpenMRS

1. Select the patient
2. Click "Start Visit"
3. Go to Orders section
4. Add lab order (e.g., "Complete Blood Count")
5. Save order

### 3. View in OpenELIS

1. Go to http://localhost:8090
2. Login (admin/adminADMIN!)
3. Navigate to "Sample Collection"
4. Manually enter sample matching OpenMRS patient

### 4. Upload Medical Image to PACS

1. Go to http://localhost:8042
2. Login (orthanc/orthanc)
3. Click "Upload" button
4. Upload any DICOM file (or use test data)

## Additional Resources

- **Integration Guide**: INTEGRATION-SETUP-GUIDE.md
- **Testing Checklist**: TESTING-CHECKLIST.md
- **OpenMRS Docs**: https://wiki.openmrs.org/
- **OpenELIS Docs**: https://docs.openelis-global.org/
- **Orthanc Docs**: https://book.orthanc-server.com/

## Automated Startup Scripts

For convenience, you can create startup scripts:

### Windows Batch Script (start-all.bat)

```batch
@echo off
echo Starting HMIS Integration...
echo.

echo Creating network (if not exists)...
docker network create hmis-network 2>nul

echo Starting OpenMRS...
cd openmrs-distro-referenceapplication
docker compose up -d
cd ..

echo Starting OpenELIS...
cd OpenELIS-Global-2
docker compose up -d
cd ..

echo Starting PACS...
cd orthanc-pacs
docker compose up -d
cd ..

echo.
echo All systems started!
echo.
echo Access URLs:
echo - OpenMRS: http://localhost/openmrs/spa
echo - OpenELIS: http://localhost:8090
echo - PACS: http://localhost:8042
echo.
pause
```

### Windows Batch Script (stop-all.bat)

```batch
@echo off
echo Stopping HMIS Integration...
echo.

echo Stopping OpenMRS...
cd openmrs-distro-referenceapplication
docker compose down
cd ..

echo Stopping OpenELIS...
cd OpenELIS-Global-2
docker compose down
cd ..

echo Stopping PACS...
cd orthanc-pacs
docker compose down
cd ..

echo.
echo All systems stopped!
pause
```

## Performance Optimization

### For Development

If you're experiencing slow performance:

1. **Reduce resource usage**:
   ```bash
   # Limit OpenMRS memory
   # Add to openmrs-distro-referenceapplication/docker-compose.yml under backend:
   mem_limit: 2g
   memswap_limit: 2g
   ```

2. **Use faster disk I/O**:
   - Move Docker data directory to SSD
   - Enable WSL2 for Docker Desktop on Windows

3. **Disable unnecessary services**:
   - Stop services you're not actively using
   - Only run what you need for current development

### For Production

1. **Enable health checks**: Already configured in docker-compose files
2. **Set up monitoring**: Use Prometheus + Grafana
3. **Configure backups**: Automate volume backups (see Data Persistence section)
4. **Enable SSL**: Use docker-compose.ssl.yml for OpenMRS
5. **Resource limits**: Set appropriate CPU and memory limits

---

**Version**: 1.0
**Last Updated**: 2025-11-25
**Maintainer**: Project Team
**Status**: Tested on Windows 11 with Docker Desktop

**Summary**: You now have a fully integrated HMIS with EMR (OpenMRS), LIMS (OpenELIS), and PACS (Orthanc) running on Docker, all connected via the `hmis-network` for seamless communication.