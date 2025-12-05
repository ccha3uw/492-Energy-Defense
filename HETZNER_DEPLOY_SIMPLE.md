# Simple Hetzner Deployment - Root User with Password

## Overview

This guide shows how to deploy using a **tar.gz package** with **root user and password** authentication.

## Prerequisites

- Hetzner server with Ubuntu 22.04+ or Debian 11+
- Root password
- At least 4GB RAM (8GB recommended)

---

## Step 1: Create Deployment Package

On your **local machine**, in the project directory:

```bash
./create-deployment-package.sh
```

This creates: `cyber-defense-YYYYMMDD-HHMMSS.tar.gz`

---

## Step 2: Upload to Hetzner

### Option A: Using SCP (recommended)

```bash
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

When prompted, enter your root password.

### Option B: Using SFTP

```bash
sftp root@YOUR_SERVER_IP
put cyber-defense-*.tar.gz
exit
```

### Option C: Using Web Panel

1. Login to Hetzner Cloud Console
2. Open server console (web terminal)
3. Use `wget` or `curl` to download from a URL where you uploaded the file

---

## Step 3: SSH to Server

```bash
ssh root@YOUR_SERVER_IP
```

Enter password when prompted.

---

## Step 4: Extract and Deploy

```bash
# Extract the package
tar -xzf cyber-defense-*.tar.gz

# Enter directory
cd cyber-defense

# Run deployment script
chmod +x deploy.sh
./deploy.sh
```

The script will:
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall
- ✅ Build containers
- ✅ Download Qwen model (~400MB)
- ✅ Start all services

**Wait 1-2 minutes** for initialization.

---

## Step 5: Verify Deployment

### Check Services

```bash
docker-compose ps
```

Should show 5 containers running:
- `cyber-events-db` (database)
- `ollama-qwen` (AI model)
- `cyber-agent` (API)
- `cyber-backend` (event generator)
- `cyber-dashboard` (web UI)

### Test Agent

```bash
curl http://localhost:8000/health | jq
```

Expected output:
```json
{
  "status": "healthy",
  "service": "492-Energy-Defense Cyber Event Triage Agent",
  "mode": "Rule-based",
  ...
}
```

### Test Dashboard

```bash
curl http://localhost:3000/health
```

---

## Step 6: Access Your System

Get your server's public IP:

```bash
curl ifconfig.me
```

Then open in your browser:

### Dashboard
```
http://YOUR_SERVER_IP:3000
```

### Agent API
```
http://YOUR_SERVER_IP:8000
```

### API Documentation
```
http://YOUR_SERVER_IP:8000/docs
```

---

## Firewall Ports

The deployment automatically opens these ports:

| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | Server access |
| 80 | HTTP | Web traffic (future) |
| 443 | HTTPS | Secure web (future) |
| 3000 | Dashboard | Web interface |
| 8000 | Agent API | API endpoints |

---

## Useful Commands

### System Management

```bash
# Check status
docker-compose ps

# View logs (all)
docker-compose logs -f

# View specific logs
docker logs cyber-agent -f

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Start again
docker-compose up -d
```

### Model Management

```bash
# Check loaded models
docker exec ollama-qwen ollama list

# Pull/update model
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

### Database Access

```bash
# Connect to database
docker exec -it cyber-events-db psql -U postgres -d cyber_events

# Inside psql:
\dt                           # List tables
SELECT COUNT(*) FROM event_analyses;
\q                            # Quit
```

---

## Troubleshooting

### Services not starting?

```bash
# Check logs
docker-compose logs

# Try restarting
docker-compose restart

# Fresh start
docker-compose down -v
./deploy.sh
```

### Can't access from browser?

```bash
# Check firewall
ufw status

# Ensure ports are open
ufw allow 3000/tcp
ufw allow 8000/tcp
```

### Out of disk space?

```bash
# Clean up Docker
docker system prune -a

# Check disk usage
df -h
```

### Model not loading?

```bash
# Check Ollama
docker logs ollama-qwen

# Pull model manually
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

---

## Updating the System

To update your deployment:

1. **On local machine**: Create new package
   ```bash
   ./create-deployment-package.sh
   ```

2. **Upload to server**:
   ```bash
   scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
   ```

3. **On server**:
   ```bash
   cd /root/cyber-defense
   docker-compose down
   cd ..
   tar -xzf cyber-defense-NEW.tar.gz --overwrite
   cd cyber-defense
   ./deploy.sh
   ```

---

## Backup & Restore

### Backup Database

```bash
# Backup
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Download to local
scp root@YOUR_SERVER_IP:/root/cyber-defense/backup.sql ./
```

### Restore Database

```bash
# Upload backup
scp backup.sql root@YOUR_SERVER_IP:/root/cyber-defense/

# On server
docker exec -i cyber-events-db psql -U postgres cyber_events < backup.sql
```

---

## Uninstalling

To completely remove the system:

```bash
# Stop and remove containers
docker-compose down -v

# Remove Docker images
docker rmi $(docker images | grep cyber | awk '{print $3}')

# Remove files
cd ..
rm -rf cyber-defense
rm cyber-defense-*.tar.gz

# Optional: Remove Docker
apt-get remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

---

## Security Recommendations

### 1. Change Default Passwords

Edit `docker-compose.yml`:
```yaml
POSTGRES_PASSWORD: your_secure_password
```

Then restart:
```bash
docker-compose down -v
docker-compose up -d
```

### 2. Setup Firewall

```bash
# Only allow specific IPs for dashboard/API
ufw delete allow 3000/tcp
ufw allow from YOUR_IP_ADDRESS to any port 3000

ufw delete allow 8000/tcp
ufw allow from YOUR_IP_ADDRESS to any port 8000
```

### 3. Setup HTTPS (optional)

Use Nginx or Caddy as reverse proxy with Let's Encrypt.

---

## Resource Usage

Expected resource usage:

| Component | RAM | Disk |
|-----------|-----|------|
| PostgreSQL | 200-300MB | 1-2GB |
| Ollama (Qwen 0.5B) | 2-3GB | 500MB |
| Agent | 300-500MB | 100MB |
| Backend | 200-300MB | 50MB |
| Dashboard | 200-300MB | 50MB |
| **Total** | **~4GB** | **~3GB** |

---

## Quick Reference

### Package Contents
- `deploy.sh` - Main deployment script
- `docker-compose.yml` - Service configuration
- `agent/` - AI agent code
- `backend/` - Event generator
- `dashboard/` - Web interface
- `DEPLOY_README.txt` - Quick instructions
- `COMMANDS.txt` - Command reference

### First Time Setup
```bash
scp cyber-defense-*.tar.gz root@SERVER_IP:/root/
ssh root@SERVER_IP
tar -xzf cyber-defense-*.tar.gz
cd cyber-defense
./deploy.sh
```

### Access URLs
- Dashboard: `http://SERVER_IP:3000`
- API: `http://SERVER_IP:8000`
- Docs: `http://SERVER_IP:8000/docs`

---

## Support

If you encounter issues:

1. Check logs: `docker-compose logs`
2. Check status: `docker-compose ps`
3. Review `DEPLOY_README.txt` in package
4. Check `COMMANDS.txt` for quick reference

---

**Deployment Package Method**: Simple, reliable, works with password auth ✅
