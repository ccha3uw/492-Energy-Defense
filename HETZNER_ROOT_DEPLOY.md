# Hetzner Deployment with Root User (tar.gz method)

## Quick Deployment Guide

This guide shows you how to deploy using a simple tar.gz package with root user access.

---

## Step 1: Create Deployment Package

On your **local machine** (in the project directory):

```bash
./create-deployment-package.sh
```

This creates a file like: `cyber-defense-20251202-143045.tar.gz`

---

## Step 2: Upload to Hetzner Server

```bash
# Replace YOUR_SERVER_IP with your actual server IP
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:~/
```

**Or use any file transfer method:**
- SFTP client (FileZilla, WinSCP, etc.)
- Hetzner Cloud Console file upload
- Web-based file manager

---

## Step 3: Deploy on Server

SSH into your Hetzner server:

```bash
ssh root@YOUR_SERVER_IP
```

Then run these commands:

```bash
# Extract the package
tar -xzf cyber-defense-*.tar.gz
cd 492-energy-defense

# Install Docker (if not already installed)
./install-docker.sh

# Start the application
./start.sh
```

**That's it!** The application will:
1. Install Docker (if needed)
2. Start all services
3. Download the Qwen model (~400MB, takes 1-2 minutes)
4. Initialize the database
5. Begin generating security events

---

## Step 4: Verify Deployment

### Check services are running:
```bash
docker ps
```

You should see 5 containers:
- `ollama-qwen`
- `cyber-agent`
- `cyber-backend`
- `cyber-events-db`
- `cyber-dashboard`

### Test the agent:
```bash
curl http://localhost:8000/health
```

### Access from your browser:
- **Dashboard**: `http://YOUR_SERVER_IP:3000`
- **API Docs**: `http://YOUR_SERVER_IP:8000/docs`

---

## Firewall Configuration (Recommended)

```bash
# Allow SSH (IMPORTANT - do this first!)
ufw allow 22/tcp

# Allow application ports
ufw allow 8000/tcp   # Agent API
ufw allow 3000/tcp   # Dashboard

# Enable firewall
ufw --force enable

# Check status
ufw status
```

---

## Complete Example (Full Workflow)

### On Your Local Machine:

```bash
# Navigate to project
cd /workspace

# Create deployment package
./create-deployment-package.sh
# Output: cyber-defense-20251202-143045.tar.gz

# Upload to server (replace 65.21.123.45 with your IP)
scp cyber-defense-20251202-143045.tar.gz root@65.21.123.45:~/
```

### On Hetzner Server:

```bash
# SSH into server
ssh root@65.21.123.45

# Extract package
tar -xzf cyber-defense-20251202-143045.tar.gz
cd 492-energy-defense

# Read deployment instructions (optional)
cat DEPLOY_INSTRUCTIONS.txt

# Start everything
./start.sh

# Wait ~2 minutes, then check
docker ps
curl http://localhost:8000/health
```

### On Your Local Browser:

```
http://65.21.123.45:3000  ← Dashboard
http://65.21.123.45:8000/docs  ← API Documentation
```

---

## Configuration Options

The package includes a `.env` file you can edit before starting:

```bash
# Edit configuration
nano .env

# Change these values:
USE_LLM=false              # Use rule-based (recommended)
OLLAMA_MODEL=qwen2.5:1.5b  # Or use larger model

# Restart to apply changes
docker compose restart agent
```

---

## Common Commands

```bash
# View logs (all services)
docker compose logs -f

# View specific service logs
docker compose logs -f cyber-agent

# Check service status
docker compose ps

# Restart services
docker compose restart

# Stop everything
docker compose down

# Start everything
docker compose up -d

# Check model
docker exec ollama-qwen ollama list

# Check system resources
htop  # or: docker stats
```

---

## Updating the Application

To update to a new version:

```bash
# On your local machine
./create-deployment-package.sh
scp cyber-defense-NEW.tar.gz root@YOUR_SERVER_IP:~/

# On the server
cd ~
docker compose -f 492-energy-defense/docker-compose.yml down
tar -xzf cyber-defense-NEW.tar.gz
cd 492-energy-defense
./start.sh
```

---

## Troubleshooting

### Problem: Docker not installed

```bash
./install-docker.sh
# Or manually:
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### Problem: Port already in use

```bash
# Find what's using the port
netstat -tlnp | grep 8000

# Kill the process or change port in docker-compose.yml
```

### Problem: Can't access from outside

```bash
# Check if firewall is blocking
ufw status

# Allow the port
ufw allow 8000/tcp
ufw allow 3000/tcp
```

### Problem: Services keep restarting

```bash
# Check logs for errors
docker compose logs

# Check system resources
free -h
df -h

# Restart everything
docker compose down
docker compose up -d
```

### Problem: Model not downloading

```bash
# Check Ollama logs
docker logs ollama-init

# Manually pull model
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Check internet connectivity
ping -c 3 8.8.8.8
```

---

## Package Contents

The deployment package includes:

- `agent/` - AI agent service code
- `backend/` - Backend service and data generator
- `dashboard/` - Web dashboard
- `docker-compose.yml` - Service orchestration
- `.env` - Configuration file
- `README.md` - Full documentation
- `DEPLOY_INSTRUCTIONS.txt` - Detailed deployment guide
- `install-docker.sh` - Docker installation script
- `start.sh` - Quick start script
- `check-qwen-model.sh` - Model verification script
- `apply-fix.sh` - Fix for scoring issues

---

## Security Best Practices

### For Production Deployments:

1. **Change default passwords** in `.env`
2. **Enable firewall** (UFW)
3. **Use SSH keys** instead of passwords
4. **Keep system updated**:
   ```bash
   apt update && apt upgrade -y
   ```
5. **Set up HTTPS** with reverse proxy (nginx/traefik)
6. **Regular backups** of database
7. **Limit SSH access** to specific IPs if possible

### Backup Database:

```bash
# Create backup
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Restore backup
cat backup.sql | docker exec -i cyber-events-db psql -U postgres cyber_events
```

---

## Server Specifications

### Minimum (Rule-Based Mode):
- **RAM**: 4GB
- **CPU**: 2 cores
- **Disk**: 20GB
- **Cost**: ~€5-10/month

### Recommended (LLM Mode):
- **RAM**: 8-16GB
- **CPU**: 4 cores
- **Disk**: 40GB
- **Cost**: ~€15-30/month

### Hetzner Cloud Server Types:

| Type | vCPU | RAM | Disk | Price/mo | Good For |
|------|------|-----|------|----------|----------|
| CX11 | 1 | 2GB | 20GB | €3.79 | Rule-based only |
| CX21 | 2 | 4GB | 40GB | €5.83 | Rule-based |
| CX31 | 2 | 8GB | 80GB | €10.38 | LLM (0.5B) |
| CPX31 | 4 | 16GB | 160GB | €30.00 | LLM (1.5B/3B) |

---

## Quick Reference Card

```bash
# CREATE PACKAGE (local)
./create-deployment-package.sh

# UPLOAD (local)
scp cyber-defense-*.tar.gz root@SERVER_IP:~/

# DEPLOY (server)
ssh root@SERVER_IP
tar -xzf cyber-defense-*.tar.gz
cd 492-energy-defense
./start.sh

# ACCESS (browser)
http://SERVER_IP:3000  # Dashboard
http://SERVER_IP:8000  # API

# MANAGE (server)
docker compose logs -f    # View logs
docker compose ps         # Check status
docker compose restart    # Restart
docker compose down       # Stop
```

---

## Support

- **Full documentation**: See `README.md` in the package
- **Deployment details**: See `DEPLOY_INSTRUCTIONS.txt` in the package
- **Check logs**: `docker compose logs`
- **Check status**: `docker compose ps`

---

**That's it!** You now have a simple tar.gz deployment method for Hetzner with root user access. 🚀
