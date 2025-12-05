# Hetzner Deployment Guide - Simple Method (Root + Password)

## Quick Deployment with tar.gz

This guide shows how to deploy using just root access with password authentication.

---

## Prerequisites

- Hetzner Cloud server (CPX21 or larger)
- Root password access
- Your local machine with SSH client

---

## Step 1: Create Deployment Package

On your **local machine** (in the project directory):

```bash
./create-deployment-package.sh
```

This creates a file like: `cyber-defense-20251202-143052.tar.gz`

---

## Step 2: Create Hetzner Server

1. **Go to:** https://console.hetzner.cloud/
2. **Create new server:**
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 4GB RAM) - minimum
   - **Type**: CPX31 (4 vCPU, 8GB RAM) - recommended
   - **Location**: Closest to you
   - **SSH Key**: Optional (we'll use password)
   - **Name**: cyber-defense-server
3. **Click**: "Create & Buy Now"
4. **Save the root password** shown on screen
5. **Copy the IP address**: e.g., `65.108.123.45`

---

## Step 3: Upload Package to Server

```bash
# Replace with your package name and server IP
scp cyber-defense-20251202-143052.tar.gz root@65.108.123.45:/root/

# Enter root password when prompted
```

---

## Step 4: Deploy on Server

### 4.1 SSH into Server

```bash
ssh root@65.108.123.45
# Enter password when prompted
```

### 4.2 Run Setup Script

Copy and paste this entire block into your SSH session:

```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y docker.io docker-compose curl jq

# Start Docker
systemctl enable docker
systemctl start docker

# Extract the package
cd /root
tar -xzf cyber-defense-*.tar.gz

# Make scripts executable
chmod +x *.sh

# Start the system
docker-compose up -d

# Wait for model download (1-2 minutes)
sleep 120

# Check status
docker-compose ps
```

---

## Step 5: Verify Deployment

### Check Services

```bash
# Check all containers
docker ps

# Check agent health
curl http://localhost:8000/health | jq
```

Expected output:
```json
{
  "status": "healthy",
  "service": "492-Energy-Defense Cyber Event Triage Agent",
  "mode": "Rule-based",
  "model": "N/A"
}
```

### Test Event Analysis

```bash
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

Expected: `"risk_score": 130, "severity": "critical"`

---

## Step 6: Configure Firewall

```bash
# Allow SSH
ufw allow 22/tcp

# Allow Agent API (if accessing externally)
ufw allow 8000/tcp

# Allow Dashboard (if accessing externally)
ufw allow 3000/tcp

# Enable firewall
ufw --force enable

# Check status
ufw status
```

---

## Access Your System

### From Server (SSH)

```bash
# Agent health
curl http://localhost:8000/health

# View logs
docker logs -f cyber-agent

# Check database
docker exec -it cyber-events-db psql -U postgres -d cyber_events
```

### From External Machine

```bash
# Replace with your server IP
curl http://65.108.123.45:8000/health

# View dashboard
http://65.108.123.45:3000
```

---

## Management Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker logs -f cyber-agent
docker logs -f cyber-backend
docker logs -f cyber-dashboard
docker logs -f ollama-qwen
```

### Restart Services

```bash
# Restart everything
docker-compose restart

# Restart specific service
docker-compose restart agent
```

### Stop/Start

```bash
# Stop everything
docker-compose down

# Start everything
docker-compose up -d
```

### Update Deployment

```bash
# On local machine, create new package
./create-deployment-package.sh

# Upload to server
scp cyber-defense-NEW.tar.gz root@65.108.123.45:/root/

# On server
cd /root
docker-compose down
rm -rf agent backend dashboard docker-compose.yml
tar -xzf cyber-defense-NEW.tar.gz
docker-compose up -d
```

---

## Troubleshooting

### Problem: Can't SSH to server

**Solution:**
```bash
# Make sure you're using the correct IP and password
ssh root@YOUR_SERVER_IP

# If connection refused, wait a few minutes (server may be starting)
```

### Problem: Docker not installed

**Solution:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install -y docker-compose
```

### Problem: Containers not starting

**Solution:**
```bash
# Check logs
docker-compose logs

# Check system resources
free -h
df -h

# Restart
docker-compose down
docker-compose up -d
```

### Problem: Model not loading

**Solution:**
```bash
# Pull model manually
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Or switch to rule-based mode (no model needed)
# Edit docker-compose.yml: USE_LLM=false
docker-compose restart agent
```

---

## One-Liner Deployment

For the brave, here's a complete one-liner (after uploading tar.gz):

```bash
apt update && apt upgrade -y && \
apt install -y docker.io docker-compose curl jq && \
systemctl enable docker && systemctl start docker && \
cd /root && tar -xzf cyber-defense-*.tar.gz && \
chmod +x *.sh && docker-compose up -d && \
sleep 120 && docker-compose ps
```

---

## Server Specifications

### Minimum (Development/Testing)
- **CPX21**: 3 vCPU, 4GB RAM, 80GB SSD (~€10/month)
- Can run rule-based mode only

### Recommended (Production)
- **CPX31**: 4 vCPU, 8GB RAM, 160GB SSD (~€20/month)
- Can run LLM mode with validation

### High Performance
- **CPX41**: 8 vCPU, 16GB RAM, 240GB SSD (~€40/month)
- Smooth LLM operation with larger models

---

## Security Recommendations

### 1. Change root password
```bash
passwd
```

### 2. Create non-root user (optional)
```bash
adduser cyber
usermod -aG sudo cyber
usermod -aG docker cyber
```

### 3. Setup SSH keys (optional but recommended)
```bash
# On your local machine
ssh-keygen -t ed25519 -C "cyber-defense"

# Copy to server
ssh-copy-id root@YOUR_SERVER_IP
```

### 4. Restrict SSH access
```bash
# Edit SSH config
nano /etc/ssh/sshd_config

# Change:
PermitRootLogin yes  →  PermitRootLogin prohibit-password
PasswordAuthentication yes  →  PasswordAuthentication no

# Restart SSH
systemctl restart sshd
```

---

## Cost Estimate

| Server Type | Monthly Cost | Use Case |
|-------------|--------------|----------|
| CPX21 (4GB) | ~€10 | Development/Testing |
| CPX31 (8GB) | ~€20 | Production (Rule-based) |
| CPX41 (16GB)| ~€40 | Production (LLM mode) |

**Note**: Hetzner pricing is very competitive. Add ~€1-2/month for backups.

---

## Quick Reference

```bash
# Package creation (local)
./create-deployment-package.sh

# Upload to server (local)
scp cyber-defense-*.tar.gz root@SERVER_IP:/root/

# Deploy on server (SSH)
cd /root && tar -xzf cyber-defense-*.tar.gz && docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Restart
docker-compose restart
```

---

## Support

- **Quick check**: `docker-compose ps`
- **Logs**: `docker-compose logs`
- **Health**: `curl http://localhost:8000/health`
- **Database**: `docker exec -it cyber-events-db psql -U postgres -d cyber_events`

---

**That's it! Your cybersecurity monitoring system is now running on Hetzner Cloud.** 🚀
