# 🚀 Hetzner Quick Start - 5 Minutes to Deployment

## One-Command Deployment

### Step 1: Create Hetzner Server (2 minutes)

1. Go to: https://console.hetzner.cloud/
2. Click "Add Server"
3. Select:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 4GB RAM, €10.90/mo)
   - **Location**: Closest to you
   - **SSH Key**: Add your public key
4. Click "Create & Buy"
5. **Copy your server IP**: e.g., `65.21.123.45`

### Step 2: Deploy (1 minute)

**On your local machine (in the project directory):**

```bash
# Option 1: Full deployment (recommended)
./deploy-to-hetzner.sh 65.21.123.45

# Option 2: Ultra-quick (no setup output)
./deployment/quick-deploy.sh 65.21.123.45
```

### Step 3: Access (Immediately)

**Dashboard:** `http://YOUR_IP:3000`  
**API:** `http://YOUR_IP:8000`  
**Docs:** `http://YOUR_IP:8000/docs`

---

## What Gets Deployed

✅ PostgreSQL database  
✅ AI Agent with Qwen model  
✅ Backend event generator  
✅ Web dashboard  
✅ Automatic model download  
✅ Firewall configuration  
✅ Docker & Docker Compose  

---

## After Deployment

### Test It Works

```bash
# Check health
curl http://YOUR_IP:8000/health | jq

# Test event analysis
curl -X POST http://YOUR_IP:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{"type":"login","data":{"username":"admin","status":"SUCCESS"}}' | jq
```

### View Logs

```bash
ssh root@YOUR_IP
cd /root/cyber-defense  # or /home/cyber/cyber-defense
docker-compose logs -f
```

### Manage Services

```bash
# On server
docker-compose ps          # Status
docker-compose restart     # Restart
docker-compose down        # Stop
docker-compose up -d       # Start
```

---

## Deployment Options

### Basic (Rule-Based Mode) - €4.51/month

```yaml
# Uses CX21 or CPX11
# No LLM, rule-based scoring only
USE_LLM=false
```

### Standard (Qwen 1.5B) - €10.90/month

```yaml
# Uses CPX21
# LLM with good accuracy
OLLAMA_MODEL=qwen2.5:1.5b
USE_LLM=true
```

### Premium (Qwen 3B) - €18.90/month

```yaml
# Uses CPX31
# Best LLM accuracy
OLLAMA_MODEL=qwen2.5:3b
USE_LLM=true
```

---

## Troubleshooting

### Services Not Starting

```bash
ssh root@YOUR_IP
cd /root/cyber-defense
docker-compose logs
```

### Can't Access from Browser

```bash
# Check firewall
ssh root@YOUR_IP "ufw status"

# Open ports if needed
ssh root@YOUR_IP "ufw allow 3000/tcp && ufw allow 8000/tcp"
```

### Model Not Loading

```bash
# Pull model manually
ssh root@YOUR_IP "cd /root/cyber-defense && docker exec ollama-qwen ollama pull qwen2.5:1.5b"
```

---

## What's Included

📂 **Deployment Package Includes:**

- ✅ `deploy-to-hetzner.sh` - Full deployment script
- ✅ `deployment/quick-deploy.sh` - Quick deployment
- ✅ `deployment/server-setup.sh` - Server configuration
- ✅ `deployment/DEPLOYMENT_GUIDE.md` - Detailed guide
- ✅ `deployment/docker-compose.production.yml` - Production config
- ✅ All application code and dependencies

---

## Configuration

### Change Model After Deployment

```bash
ssh root@YOUR_IP
cd /root/cyber-defense

# Edit docker-compose.yml
nano docker-compose.yml

# Change OLLAMA_MODEL to:
# - qwen2.5:0.5b  (smallest, 400MB)
# - qwen2.5:1.5b  (recommended, 900MB)
# - qwen2.5:3b    (best, 2GB)

# Restart
docker-compose restart agent
```

### Switch Between LLM and Rule-Based

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change USE_LLM=true to USE_LLM=false (or vice versa)

# Restart
docker-compose restart agent
```

### Change Database Password

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change POSTGRES_PASSWORD
# Update DATABASE_URL with new password

# Restart database
docker-compose down
docker-compose up -d
```

---

## Cost Calculator

| Setup | Server | Cost/Month | Use Case |
|-------|--------|------------|----------|
| Minimal | CX21 (2 vCPU, 2GB) | €4.51 | Testing, rule-based |
| Standard | CPX21 (3 vCPU, 4GB) | €10.90 | Production, Qwen 1.5B |
| Premium | CPX31 (4 vCPU, 8GB) | €18.90 | High performance, Qwen 3B |
| Enterprise | CPX41 (8 vCPU, 16GB) | €36.90 | Heavy load, multiple instances |

---

## Security Checklist

After deployment:

1. ✅ Change database password in `docker-compose.yml`
2. ✅ Set up SSH key authentication (disable password login)
3. ✅ Configure firewall rules
4. ✅ Enable automatic security updates
5. ✅ Set up backup schedule

```bash
# Quick security setup
ssh root@YOUR_IP << 'EOF'
# Change DB password
cd /root/cyber-defense
nano docker-compose.yml  # Change POSTGRES_PASSWORD

# Disable password SSH login
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Enable auto-updates
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
EOF
```

---

## Backup & Restore

### Backup

```bash
# Backup database
ssh root@YOUR_IP "cd /root/cyber-defense && docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql"

# Download backup
scp root@YOUR_IP:/root/cyber-defense/backup.sql ./
```

### Restore

```bash
# Upload backup
scp backup.sql root@YOUR_IP:/root/cyber-defense/

# Restore
ssh root@YOUR_IP "cd /root/cyber-defense && docker exec -i cyber-events-db psql -U postgres cyber_events < backup.sql"
```

---

## Quick Commands

```bash
# Deploy
./deploy-to-hetzner.sh <IP>

# Connect
ssh root@<IP>

# Navigate
cd /root/cyber-defense

# View status
docker-compose ps

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Start
docker-compose up -d

# Update
git pull && docker-compose build && docker-compose up -d
```

---

## Support

**Detailed Guide:** `deployment/DEPLOYMENT_GUIDE.md`  
**Configuration:** Edit `docker-compose.yml`  
**Logs:** `docker-compose logs -f`  
**Status:** `docker-compose ps`

---

## Summary

✅ **Total Time**: 5 minutes  
✅ **Cost**: From €4.51/month  
✅ **Commands**: 1 deployment command  
✅ **Fully Automated**: No manual configuration needed  

**Just run:**
```bash
./deploy-to-hetzner.sh YOUR_SERVER_IP
```

**And access at:**
- Dashboard: `http://YOUR_IP:3000`
- API: `http://YOUR_IP:8000`

That's it! 🎉
