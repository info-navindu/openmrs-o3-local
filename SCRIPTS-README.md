# Management Scripts - Quick Reference

This directory contains convenient batch scripts for managing the HMIS integration.

## Available Scripts

### Core Operations

| Script | Description | Usage |
|--------|-------------|-------|
| **start-all.bat** | Starts all three systems (OpenMRS, OpenELIS, PACS) | Double-click or run from command line |
| **stop-all.bat** | Stops all three systems gracefully | Double-click or run from command line |
| **restart-all.bat** | Restarts all systems (stop + start) | Double-click or run from command line |

### Monitoring & Diagnostics

| Script | Description | Usage |
|--------|-------------|-------|
| **check-status.bat** | Shows status of all containers and services | Double-click or run from command line |
| **view-logs.bat** | Interactive menu to view logs from any system | Double-click and select option |

## Quick Start

1. **First Time Setup**:
   ```bash
   # Just run this script - it will create the network automatically
   start-all.bat
   ```

2. **Daily Usage**:
   ```bash
   # Morning: Start all systems
   start-all.bat

   # Check if everything is running
   check-status.bat

   # Evening: Stop all systems
   stop-all.bat
   ```

3. **Troubleshooting**:
   ```bash
   # Check system status
   check-status.bat

   # View logs to diagnose issues
   view-logs.bat

   # Restart if needed
   restart-all.bat
   ```

## Script Details

### start-all.bat

**What it does:**
1. Creates `hmis-network` (if not exists)
2. Starts OpenMRS (4 containers)
3. Starts OpenELIS (6 containers)
4. Starts Orthanc PACS (1 container)
5. Shows access URLs and credentials

**Expected startup time:** 3-5 minutes

**Output:** Shows status for each step with success/error messages

### stop-all.bat

**What it does:**
1. Stops OpenMRS containers
2. Stops OpenELIS containers
3. Stops PACS container
4. Preserves data volumes and network

**Note:** Does NOT delete any data

### restart-all.bat

**What it does:**
1. Calls `stop-all.bat`
2. Waits 5 seconds
3. Calls `start-all.bat`

**Use when:** Services are not responding or after configuration changes

### check-status.bat

**What it does:**
1. Checks if `hmis-network` exists
2. Lists all running containers
3. Shows status of expected 11 containers
4. Tests if web UIs are responding
5. Shows quick action commands

**Use when:** You want to verify everything is running correctly

### view-logs.bat

**What it does:**
1. Shows interactive menu
2. Allows viewing logs from any system
3. Can open all logs in separate windows

**Options:**
- OpenMRS Backend logs
- OpenMRS Gateway logs
- OpenELIS WebApp logs
- OpenELIS FHIR API logs
- Orthanc PACS logs
- All systems (opens multiple windows)

**Use when:** Troubleshooting issues or monitoring startup

## System URLs & Credentials

After running `start-all.bat`, access:

### OpenMRS O3
- **URL**: http://localhost/openmrs/spa
- **Username**: `admin`
- **Password**: `Admin123`

### OpenELIS
- **URL**: http://localhost:8090
- **Username**: `admin`
- **Password**: `adminADMIN!`

### Orthanc PACS
- **URL**: http://localhost:8042
- **Username**: `orthanc`
- **Password**: `orthanc`

## Troubleshooting

### Script Issues

**Problem:** "Access Denied" error
```bash
# Run Command Prompt as Administrator
Right-click Command Prompt → Run as administrator
```

**Problem:** Scripts won't run
```bash
# Check if Docker is running
docker version

# If Docker isn't running, start Docker Desktop
```

**Problem:** Containers already exist
```bash
# Stop existing containers first
stop-all.bat

# Then start again
start-all.bat
```

### Container Issues

**Problem:** Container keeps restarting
```bash
# View logs to see the error
view-logs.bat

# Then select the problematic container
```

**Problem:** Port already in use
```bash
# Find what's using the port (example: port 80)
netstat -ano | findstr :80

# Kill the process
taskkill /PID <PID> /F
```

**Problem:** Out of memory
```bash
# Check Docker resource usage
docker stats

# Increase Docker Desktop memory:
# Docker Desktop → Settings → Resources → Memory → Set to 8GB+
```

## Advanced Usage

### Start Individual Systems

```bash
# Start only OpenMRS
cd openmrs-distro-referenceapplication
docker compose up -d

# Start only OpenELIS
cd OpenELIS-Global-2
docker compose up -d

# Start only PACS
cd orthanc-pacs
docker compose up -d
```

### View Specific Container Logs

```bash
# OpenMRS Backend
docker logs openmrs-distro-referenceapplication-backend-1 -f

# OpenELIS WebApp
docker logs openelisglobal-webapp -f

# PACS
docker logs orthanc-pacs -f
```

### Check Container Resource Usage

```bash
docker stats
```

### Cleanup (⚠️ Deletes ALL data)

```bash
# Stop everything
stop-all.bat

# Remove volumes (WARNING: Deletes databases and uploaded files)
docker volume prune -f

# Remove network
docker network rm hmis-network
```

## File Structure

```
openmrs-o3-local/
├── start-all.bat           # Start all systems
├── stop-all.bat            # Stop all systems
├── restart-all.bat         # Restart all systems
├── check-status.bat        # Check system status
├── view-logs.bat           # View system logs
├── SCRIPTS-README.md       # This file
├── DOCKER-SETUP-GUIDE.md   # Detailed setup guide
└── INTEGRATION-SETUP-GUIDE.md  # Integration configuration
```

## Best Practices

1. **Always use scripts instead of manual commands** - They handle dependencies correctly

2. **Check status before troubleshooting** - Run `check-status.bat` first

3. **View logs when debugging** - Use `view-logs.bat` to see what's happening

4. **Don't interrupt startup** - Wait 3-5 minutes for full initialization

5. **Stop gracefully** - Always use `stop-all.bat` instead of killing Docker

## Getting Help

If you encounter issues:

1. Run `check-status.bat` - See what's running
2. Run `view-logs.bat` - Check for error messages
3. Check `DOCKER-SETUP-GUIDE.md` - Detailed troubleshooting section
4. Check `INTEGRATION-SETUP-GUIDE.md` - Integration-specific issues

## Version Information

- **Created**: 2025-11-25
- **Compatible with**: Windows 10/11
- **Docker Version**: 20.10+
- **Docker Compose**: v2.0+

---

**Quick Command Reference**:
- Start: `start-all.bat`
- Stop: `stop-all.bat`
- Status: `check-status.bat`
- Logs: `view-logs.bat`
- Restart: `restart-all.bat`