# Simple Hetzner Deployment (Root User)

## Quick Start

### 1. Create Deployment Package (On Your Local Machine)

```bash
./create-deployment-package.sh
```

This creates: `cyber-defense-agent-YYYYMMDD.tar.gz`

### 2. Upload to Hetzner Server

```bash
# Replace with your server IP
scp cyber-defense-agent-*.tar.gz root@YOUR_SERVER_IP:/root/
```

### 3. Deploy on Server

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Extract package
cd /root
tar -xzf cyber-defense-agent-*.tar.gz
cd cyber-defense-deploy

# Run automated deployment
./deploy.sh
```

**That's it!** The script will:
- ✅ Install Docker & Docker Compose
- ✅ Build containers
- ✅ Download Qwen model
- ✅ Start all services

### 4. Access Your System

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000/docs

---

## What's Included in the Package

```
cyber-defense-deploy/
├── agent/              # AI agent service
├── backend/            # Event generator
├── dashboard/          # Web dashboard
├── docker-compose.yml  # Container orchestration
├── .env               # Configuration
├── deploy.sh          # Automated deployment
├── check-qwen-model.sh # Model verification
├── apply-fix.sh       # Fix scoring issues
├── DEPLOY_README.md   # Quick reference
└── README.md          # Full documentation
```

---

## Server Requirements

### Minimum
- **CPU**: 2 vCPUs
- **RAM**: 4GB
- **Disk**: 20GB
- **OS**: Ubuntu 20.04+ or Debian 11+

### Recommended
- **CPU**: 4 vCPUs
- **RAM**: 8GB
- **Disk**: 40GB
- **OS**: Ubuntu 22.04 LTS

---

## Post-Deployment Steps

### Configure Firewall

```bash
# Allow necessary ports
ufw allow 22/tcp     # SSH
ufw allow 3000/tcp   # Dashboard
ufw allow 8000/tcp   # Agent API
ufw enable

# Check status
ufw status
```

### Verify Services

```bash
# Check all containers are running
docker-compose ps

# All should show "Up" status:
# - cyber-events-db
# - ollama-qwen
# - cyber-agent
# - cyber-backend
# - cyber-dashboard
```

### Test the System

```bash
# Check model is loaded
./check-qwen-model.sh

# Test agent API
curl http://localhost:8000/health | jq

# Test event analysis
./test-llm-mode.sh
```

---

## Monitoring & Management

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker logs -f cyber-agent
docker logs -f cyber-backend
docker logs -f cyber-dashboard
```

### Restart Services

```bash
# Restart all
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

### Check Resource Usage

```bash
docker stats
```

---

## Troubleshooting

### Problem: Qwen model scoring incorrectly

**Solution**: Use rule-based mode (more accurate)

```bash
./apply-fix.sh
# Choose option 1
```

### Problem: Services not starting

```bash
# Check logs
docker-compose logs

# Restart everything
docker-compose down
docker-compose up -d
```

### Problem: Can't access dashboard

**Check firewall:**
```bash
ufw status
ufw allow 3000/tcp
```

**Check service:**
```bash
docker logs cyber-dashboard
curl http://localhost:3000/health
```

### Problem: Out of memory

**Check usage:**
```bash
free -h
docker stats
```

**If using Qwen with LLM mode**, switch to rule-based:
```bash
# Edit docker-compose.yml
nano docker-compose.yml
# Change: USE_LLM=false

# Restart
docker-compose restart agent
```

---

## Updating the System

### Pull Latest Changes

```bash
# On local machine, create new package
./create-deployment-package.sh

# Upload to server
scp cyber-defense-agent-*.tar.gz root@YOUR_SERVER_IP:/root/

# On server
cd /root
docker-compose down
rm -rf cyber-defense-deploy
tar -xzf cyber-defense-agent-*.tar.gz
cd cyber-defense-deploy
./deploy.sh
```

---

## Security Recommendations

### 1. Change Default Passwords

Edit `.env` file:
```bash
nano .env
# Change PostgreSQL password
POSTGRES_PASSWORD=your_secure_password
```

### 2. Enable Firewall

```bash
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw enable
```

### 3. Use SSH Keys Only

```bash
# Disable password authentication
nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
systemctl restart sshd
```

### 4. Keep System Updated

```bash
apt-get update
apt-get upgrade -y
```

---

## Backup & Restore

### Backup Database

```bash
# Create backup
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Copy to local machine
scp root@YOUR_SERVER_IP:/root/backup.sql ./
```

### Restore Database

```bash
# Upload backup
scp backup.sql root@YOUR_SERVER_IP:/root/

# Restore
docker exec -i cyber-events-db psql -U postgres cyber_events < backup.sql
```

---

## Complete Example Workflow

```bash
# ========================================
# ON YOUR LOCAL MACHINE
# ========================================

# 1. Create deployment package
./create-deployment-package.sh

# 2. Upload to server (replace IP)
scp cyber-defense-agent-*.tar.gz root@65.21.123.45:/root/

# ========================================
# ON YOUR HETZNER SERVER
# ========================================

# 3. SSH into server
ssh root@65.21.123.45

# 4. Extract and deploy
cd /root
tar -xzf cyber-defense-agent-*.tar.gz
cd cyber-defense-deploy
./deploy.sh

# 5. Configure firewall
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw enable

# 6. Verify deployment
docker-compose ps
./check-qwen-model.sh

# 7. Access dashboard
# Open browser: http://65.21.123.45:3000

# ========================================
# DONE! 🎉
# ========================================
```

---

## Support & Documentation

- **Quick Reference**: See `DEPLOY_README.md` in the package
- **Full Documentation**: See `README.md` in the package
- **Fix Issues**: Run `./apply-fix.sh` on the server

---

## Summary

**3 Simple Steps:**
1. `./create-deployment-package.sh` (local)
2. `scp cyber-defense-*.tar.gz root@SERVER:/root/` (local)
3. `cd /root/cyber-defense-deploy && ./deploy.sh` (server)

**Access:** http://YOUR_SERVER_IP:3000

**That's it!** 🚀
