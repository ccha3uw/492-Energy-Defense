# Simple Hetzner Deployment with Root User

## Prerequisites

- Hetzner Cloud server (CPX31 or better: 4 vCPU, 16GB RAM)
- Root user with password
- Ubuntu 22.04 or 24.04

---

## Step 1: Create Deployment Package (On Your Local Machine)

```bash
# Create the deployment package
./create-deployment-package.sh
```

This creates `cyber-defense-deploy.tar.gz` (~20MB)

---

## Step 2: Upload to Hetzner

### Option A: Using SCP (with password)

```bash
# Upload the package (you'll be prompted for password)
scp cyber-defense-deploy.tar.gz root@YOUR_SERVER_IP:/root/
```

### Option B: Using Web Panel Upload

1. Log into Hetzner console
2. Use the web-based file manager or console
3. Upload `cyber-defense-deploy.tar.gz` to `/root/`

### Option C: Using wget (if you host it somewhere)

On the Hetzner server:
```bash
wget http://yourserver.com/cyber-defense-deploy.tar.gz
```

---

## Step 3: SSH to Your Server

```bash
ssh root@YOUR_SERVER_IP
# Enter password when prompted
```

---

## Step 4: Extract and Setup (On Hetzner Server)

```bash
# Extract the package
cd /root
tar -xzf cyber-defense-deploy.tar.gz
cd cyber-defense

# Run the automated setup
curl -fsSL https://get.docker.com | sh

# Install docker-compose
apt-get update
apt-get install -y docker-compose jq

# Start the system
docker-compose up -d

# Watch model download (1-2 minutes)
docker logs -f ollama-init
# Press Ctrl+C when you see "Qwen model ready!"
```

---

## Step 5: Verify It's Working

```bash
# Check all containers are running
docker ps

# Test the agent
curl http://localhost:8000/health | jq

# Test event analysis
curl -X POST http://localhost:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "test",
      "status": "SUCCESS",
      "timestamp": "2025-12-02T10:00:00",
      "is_admin": false
    }
  }' | jq
```

---

## Step 6: Configure Firewall (Optional but Recommended)

```bash
# Install firewall
apt-get install -y ufw

# Allow SSH (IMPORTANT - do this first!)
ufw allow 22/tcp

# Allow application ports
ufw allow 8000/tcp   # Agent API
ufw allow 3000/tcp   # Dashboard
ufw allow 5432/tcp   # Database (only if accessing remotely)

# Enable firewall
ufw --force enable

# Check status
ufw status
```

---

## Accessing Your System

### From Your Local Machine

```bash
# Agent API
curl http://YOUR_SERVER_IP:8000/health

# Dashboard (in browser)
http://YOUR_SERVER_IP:3000
```

### Using SSH Tunnel (More Secure)

```bash
# On your local machine, create SSH tunnel
ssh -L 8000:localhost:8000 -L 3000:localhost:3000 root@YOUR_SERVER_IP

# Now access locally
http://localhost:3000  # Dashboard
http://localhost:8000  # Agent API
```

---

## Management Commands

```bash
# View logs
docker-compose logs -f

# Stop system
docker-compose down

# Restart system
docker-compose restart

# Check status
docker-compose ps

# Update configuration
nano .env
docker-compose restart
```

---

## Choosing LLM vs Rule-Based Mode

### Rule-Based Mode (Recommended - 100% Accurate)

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change this line:
      - USE_LLM=false

# Restart
docker-compose restart agent
```

### LLM Mode (AI-Powered)

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change this line:
      - USE_LLM=true

# Restart
docker-compose restart agent
```

---

## Troubleshooting

### Problem: Cannot connect to server

```bash
# Check if services are running
docker ps

# Check firewall
ufw status

# Check logs
docker-compose logs
```

### Problem: Model not loading

```bash
# Check Ollama container
docker logs ollama-qwen

# Manually pull model
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Verify model exists
docker exec ollama-qwen ollama list
```

### Problem: Out of disk space

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Remove old images
docker image prune -a
```

### Problem: Out of memory

```bash
# Check memory
free -h

# Restart with less memory
docker-compose down
# Edit docker-compose.yml to reduce memory limits
docker-compose up -d
```

---

## Upgrading the System

### Method 1: Replace Files

```bash
# On your local machine, create new package
./create-deployment-package.sh

# Upload to server
scp cyber-defense-deploy.tar.gz root@YOUR_SERVER_IP:/root/

# On server
cd /root
docker-compose down
tar -xzf cyber-defense-deploy.tar.gz
cd cyber-defense
docker-compose up -d
```

### Method 2: Git Pull (if using git)

```bash
# On server
cd /root/cyber-defense
git pull
docker-compose down
docker-compose build
docker-compose up -d
```

---

## Quick Command Reference

```bash
# Start system
docker-compose up -d

# Stop system
docker-compose down

# View logs
docker-compose logs -f [service]

# Restart service
docker-compose restart [service]

# Check status
docker-compose ps

# Test agent
curl http://localhost:8000/health | jq

# Run diagnostics
./check-qwen-model.sh

# Apply fixes
./apply-fix.sh
```

---

## Security Recommendations

1. **Change default passwords** if you exposed PostgreSQL
2. **Use SSH tunnels** instead of opening all ports
3. **Enable UFW firewall** with minimal open ports
4. **Keep system updated**: `apt update && apt upgrade`
5. **Monitor logs regularly**: `docker-compose logs`
6. **Backup database**: `docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql`

---

## Complete Example Session

```bash
# === ON YOUR LOCAL MACHINE ===
./create-deployment-package.sh
scp cyber-defense-deploy.tar.gz root@65.21.123.45:/root/

# === ON HETZNER SERVER ===
ssh root@65.21.123.45
# [enter password]

cd /root
tar -xzf cyber-defense-deploy.tar.gz
cd cyber-defense

# Install Docker
curl -fsSL https://get.docker.com | sh
apt-get install -y docker-compose jq

# Start system
docker-compose up -d

# Wait for model to download
docker logs -f ollama-init

# Test it works
curl http://localhost:8000/health | jq

# Configure firewall
apt-get install -y ufw
ufw allow 22/tcp
ufw allow 8000/tcp
ufw allow 3000/tcp
ufw --force enable

# === DONE! ===
# Access from local machine:
# http://65.21.123.45:3000 (dashboard)
# http://65.21.123.45:8000 (API)
```

---

## File Locations

- Application: `/root/cyber-defense/`
- Docker volumes: `/var/lib/docker/volumes/`
- Logs: `docker-compose logs` or `/var/lib/docker/containers/`
- Configuration: `/root/cyber-defense/.env`

---

## Need Help?

Run the diagnostic script:
```bash
./check-qwen-model.sh
```

Apply fixes:
```bash
./apply-fix.sh
```

Check README.md for detailed documentation.
