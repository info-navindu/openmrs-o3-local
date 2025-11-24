# Orthanc PACS - Standalone Deployment

## Overview
Orthanc is an open-source PACS (Picture Archiving and Communication System) for medical imaging.

## Quick Start

```bash
# Start PACS
docker compose up -d

# View logs
docker compose logs -f

# Stop PACS
docker compose down

# Stop and remove data (⚠️ This deletes all images!)
docker compose down -v
```

## Access

- **Web UI:** http://localhost:8042/
- **Default Credentials:**
  - Username: `orthanc`
  - Password: `orthanc`
  - Admin: `admin` / `admin123`

- **DICOM Port:** 4242
  - AET (Application Entity Title): `ORTHANC`

## Features

- ✅ DICOM image storage and retrieval
- ✅ Web-based DICOM viewer
- ✅ RESTful API for integration
- ✅ DICOM worklist management
- ✅ Multiple user authentication

## Integration with OpenMRS

### Option 1: Using Radiology Module
1. Install OpenMRS Radiology Module
2. Configure PACS connection:
   - PACS Server: `orthanc-pacs` (or `localhost` if on same machine)
   - PACS Port: `4242`
   - PACS AET: `ORTHANC`
   - Viewer URL: `http://localhost:8042/`

### Option 2: Direct REST API Integration
Orthanc provides a REST API for programmatic access:

```bash
# List all studies
curl -u orthanc:orthanc http://localhost:8042/studies

# Get study details
curl -u orthanc:orthanc http://localhost:8042/studies/{study-id}

# Upload DICOM file
curl -u orthanc:orthanc -X POST \
  http://localhost:8042/instances \
  --data-binary @image.dcm
```

## Configuration

### Custom Configuration
To use a custom Orthanc configuration:

1. Create `orthanc.json` in this directory
2. Uncomment the volume mount in `docker-compose.yml`:
   ```yaml
   - ./orthanc.json:/etc/orthanc/orthanc.json:ro
   ```
3. Restart: `docker compose restart`

### Environment Variables
Edit `docker-compose.yml` to customize:

- `ORTHANC__NAME`: PACS server name
- `ORTHANC__REGISTERED_USERS`: User credentials (JSON format)
- `ORTHANC__DICOM_AET`: DICOM Application Entity Title
- `ORTHANC__MAXIMUM_STORAGE_SIZE`: Max storage (0 = unlimited)

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 4242 | DICOM    | DICOM communication (C-STORE, C-FIND, C-MOVE) |
| 8042 | HTTP     | Web UI and REST API |

## Data Storage

DICOM images and database are stored in Docker volume: `orthanc-storage`

### Backup Data
```bash
# Backup
docker run --rm -v orthanc-pacs_orthanc-storage:/data \
  -v $(pwd):/backup alpine tar czf /backup/pacs-backup.tar.gz -C /data .

# Restore
docker run --rm -v orthanc-pacs_orthanc-storage:/data \
  -v $(pwd):/backup alpine tar xzf /backup/pacs-backup.tar.gz -C /data
```

## Troubleshooting

### PACS not accessible
```bash
# Check if container is running
docker compose ps

# View logs
docker compose logs pacs

# Check port conflicts
netstat -ano | findstr :8042
netstat -ano | findstr :4242
```

### Reset PACS (⚠️ Deletes all data)
```bash
docker compose down -v
docker compose up -d
```

## Resources

- **Official Docs:** https://book.orthanc-server.com/
- **REST API:** https://api.orthanc-server.com/
- **Docker Hub:** https://hub.docker.com/r/jodogne/orthanc-plugins

## Version Info

- **Image:** jodogne/orthanc-plugins
- **Plugins Included:**
  - DICOM Web
  - PostgreSQL support
  - MySQL support
  - And more...