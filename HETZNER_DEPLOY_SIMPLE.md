# Simple Hetzner Deployment Guide (Root User)

## Prerequisites

- Hetzner Cloud Server (CPX21 or higher - 8GB+ RAM recommended)
- Root user with password
- Server IP address

---

## Step 1: Create Hetzner Server

1. Go to https://console.hetzner.cloud/
2. Create new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 8GB RAM, ~€15/month) or larger
   - **Location**: Choose closest to you
   - **SSH Key**: Optional (we'll use password)
   - **Name**: cyber-defense
3. Click "Create & Buy"
4. **Save the root password** shown after creation
5. **Copy the server IP address**

---

## Step 2: Connect to Server

From your local machine:

```bash
# SSH to your server (enter password when prompted)
ssh root@YOUR_SERVER_IP
```

---

## Step 3: Install Docker on Server

Once connected to your Hetzner server, run these commands:

```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y curl git apt-transport-https ca-certificates software-properties-common

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

Expected output:
```
Docker version 24.x.x
docker-compose version v2.x.x
```

---

## Step 4: Upload Deployment Package

### Option A: Using SCP (from your local machine)

```bash
# First, create the package on your local machine
./create-deployment-package.sh

# Copy to Hetzner server (enter password when prompted)
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

### Option B: Direct Download (if package is on GitHub/web)

```bash
# On the Hetzner server
cd /root
wget YOUR_PACKAGE_URL
# OR
curl -O YOUR_PACKAGE_URL
```

### Option C: Manual File Transfer

Use FileZilla, WinSCP, or similar tool:
- Protocol: SFTP
- Host: YOUR_SERVER_IP
- Username: root
- Password: [your root password]
- Upload the tar.gz file to /root/

---

## Step 5: Extract and Setup

On your Hetzner server:

```bash
# Go to root directory
cd /root

# List files to verify upload
ls -lh *.tar.gz

# Extract the package
tar -xzf cyber-defense-*.tar.gz

# Enter the extracted directory
cd /root

# Make scripts executable
chmod +x *.sh

# Copy environment file
cp .env.example .env
```

---

## Step 6: Configure Firewall (Optional but Recommended)

```bash
# Install UFW firewall
apt install -y ufw

# Allow SSH (IMPORTANT - do this first!)
ufw allow 22/tcp

# Allow application ports
ufw allow 8000/tcp   # Agent API
ufw allow 3000/tcp   # Dashboard
ufw allow 11434/tcp  # Ollama (optional, for external access)

# Enable firewall
ufw --force enable

# Check status
ufw status
```

---

## Step 7: Start the Application

```bash
# Start all services
docker-compose up -d

# Watch the logs to see progress
docker-compose logs -f ollama-init
```

Wait for the message: **"Qwen model ready!"** (takes 1-2 minutes)

Press `Ctrl+C` to exit logs.

---

## Step 8: Verify Everything is Running

```bash
# Check all containers are up
docker-compose ps

# Should show 5 containers running:
# - cyber-events-db
# - ollama-qwen
# - cyber-agent
# - cyber-backend
# - cyber-dashboard
```

---

## Step 9: Test the System

### From the Hetzner Server:

```bash
# Test agent health
curl http://localhost:8000/health | jq

# Test a critical event
curl -X POST http://localhost:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "admin",
      "status": "FAIL",
      "timestamp": "2025-12-02T02:30:00",
      "is_burst_failure": true,
      "is_suspicious_ip": true,
      "is_admin": true
    }
  }' | jq
```

Expected: `risk_score: 130, severity: "critical"`

### From Your Local Computer:

```bash
# Test agent (replace YOUR_SERVER_IP)
curl http://YOUR_SERVER_IP:8000/health | jq

# Access dashboard in browser
# Open: http://YOUR_SERVER_IP:3000
```

---

## Step 10: Apply Scoring Fix (Important!)

The default Qwen 0.5B model is too small for accurate scoring. Fix it:

```bash
# Run the fix script
./apply-fix.sh

# Choose option 1 (Rule-based - most reliable)
# Or option 4 (Hybrid - rule-based scores + AI reasoning)
```

---

## Common Management Commands

```bash
# View logs
docker-compose logs -f               # All services
docker-compose logs -f cyber-agent   # Just agent
docker-compose logs -f cyber-backend # Just backend

# Check status
docker-compose ps

# Restart services
docker-compose restart
docker-compose restart agent         # Just agent

# Stop everything
docker-compose down

# Start everything
docker-compose up -d

# Check disk space
df -h

# Check memory usage
free -h

# Check container resources
docker stats
```

---

## Accessing Services

Once deployed, access your services:

| Service | URL | Purpose |
|---------|-----|---------|
| Dashboard | `http://YOUR_SERVER_IP:3000` | Web interface |
| Agent API | `http://YOUR_SERVER_IP:8000` | API endpoint |
| API Docs | `http://YOUR_SERVER_IP:8000/docs` | Swagger UI |
| Database | `YOUR_SERVER_IP:5432` | PostgreSQL |

---

## Security Recommendations

### 1. Change Default Passwords

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change these values:
POSTGRES_PASSWORD: postgres  # Change this!
```

### 2. Use SSH Keys Instead of Password

```bash
# On your local machine, generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096

# Copy to server
ssh-copy-id root@YOUR_SERVER_IP

# Now you can SSH without password
ssh root@YOUR_SERVER_IP
```

### 3. Disable Password Authentication (Optional)

```bash
# Edit SSH config
nano /etc/ssh/sshd_config

# Change these lines:
PasswordAuthentication no
PermitRootLogin prohibit-password

# Restart SSH
systemctl restart sshd
```

### 4. Setup HTTPS with Domain (Optional)

If you have a domain, you can use Let's Encrypt for HTTPS. This requires additional setup with nginx/traefik.

---

## Troubleshooting

### Problem: Cannot connect to server

```bash
# Check if SSH port is open
telnet YOUR_SERVER_IP 22

# Check if server is running (from Hetzner console)
```

### Problem: Docker commands fail

```bash
# Check Docker is running
systemctl status docker

# Start Docker if needed
systemctl start docker

# Enable Docker at boot
systemctl enable docker
```

### Problem: Out of memory

```bash
# Check memory
free -h

# If low, upgrade to larger server type
# Or reduce services running
```

### Problem: Port already in use

```bash
# Check what's using the port
netstat -tulpn | grep 8000

# Kill the process if needed
kill -9 PID
```

### Problem: Model not downloading

```bash
# Check Ollama logs
docker logs ollama-qwen

# Manually pull model
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Or use rule-based mode (no model needed)
./apply-fix.sh  # Choose option 1
```

---

## Updating the Application

To update to a new version:

```bash
# Stop current version
docker-compose down

# Backup data (optional)
docker-compose down
tar -czf backup-$(date +%Y%m%d).tar.gz .

# Upload new package
# Extract and replace files
tar -xzf new-cyber-defense-*.tar.gz

# Rebuild containers
docker-compose build

# Start with new version
docker-compose up -d
```

---

## Backup Strategy

### Backup Database

```bash
# Backup PostgreSQL data
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Or backup entire volume
docker run --rm -v workspace_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/db-backup.tar.gz /data
```

### Backup Configuration

```bash
# Backup docker-compose and config
tar -czf config-backup.tar.gz docker-compose.yml .env
```

---

## Cost Estimate

| Server Type | vCPU | RAM | Storage | Price/Month |
|-------------|------|-----|---------|-------------|
| **CPX21** | 3 | 8GB | 80GB | ~€15 |
| **CPX31** | 4 | 16GB | 160GB | ~€30 |
| **CPX41** | 8 | 32GB | 240GB | ~€60 |

**Recommendation**: CPX21 for testing, CPX31 for production use

---

## Quick Reference Card

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Check status
cd /root && docker-compose ps

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Start
docker-compose up -d

# Test agent
curl http://localhost:8000/health | jq
```

---

## Support

If you encounter issues:
1. Check logs: `docker-compose logs`
2. Verify all containers running: `docker-compose ps`
3. Check server resources: `htop` or `docker stats`
4. Review firewall: `ufw status`

---

## Summary Checklist

- ✅ Hetzner server created
- ✅ Docker installed
- ✅ Application deployed
- ✅ Firewall configured
- ✅ Services running
- ✅ Scoring fix applied
- ✅ Tests passing
- ✅ Dashboard accessible

**You're all set! 🎉**

Access your dashboard at: **http://YOUR_SERVER_IP:3000**
