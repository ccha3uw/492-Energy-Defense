# 492-Energy-Defense - Hetzner Deployment Guide

## One-Command Deployment 🚀

Deploy to your Hetzner server in under 5 minutes!

### Step 1: Create Hetzner Server

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create a new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: 
     - CPX21 (3 vCPU, 8GB RAM) - Minimum for rule-based mode
     - CPX31 (4 vCPU, 16GB RAM) - Recommended for LLM mode
   - **Location**: Choose nearest
   - **SSH Key**: Add your public key
   - **Name**: cyber-defense
3. Note your server IP: `xxx.xxx.xxx.xxx`

### Step 2: Deploy Application

**Option A: Deploy from local directory**

From your local machine where you have this repository:

```bash
# SSH to server
ssh root@xxx.xxx.xxx.xxx

# Download deployment script
curl -fsSL https://raw.githubusercontent.com/your-repo/main/deploy-to-hetzner.sh -o deploy.sh

# Or if files are already on server:
# Copy all files to /tmp/cyber-agent first, then:
cd /tmp/cyber-agent
chmod +x deploy-to-hetzner.sh
./deploy-to-hetzner.sh
```

**Option B: One-line remote deployment**

```bash
# From your local machine, upload and run:
scp -r ./* root@xxx.xxx.xxx.xxx:/tmp/cyber-agent/
ssh root@xxx.xxx.xxx.xxx "cd /tmp/cyber-agent && bash deploy-to-hetzner.sh"
```

**Option C: Direct download and run**

```bash
# On the server:
curl -fsSL https://raw.githubusercontent.com/your-repo/main/deploy-to-hetzner.sh | sudo bash
```

### Step 3: Configure During Installation

The script will ask you:

```
Enter deployment user (default: cyber): [press Enter]
Enable LLM mode? (y/N): n  [recommended: use rule-based]
Continue with this configuration? (Y/n): y
```

**Recommended Configuration:**
- User: `cyber` (default)
- LLM Mode: `N` (rule-based is most reliable)
- If you choose LLM, select option 1 (Rule-based) for best accuracy

### Step 4: Access Your Application

After 2-3 minutes, access at:

- **Dashboard**: http://your-server-ip:3000
- **API**: http://your-server-ip:8000
- **API Docs**: http://your-server-ip:8000/docs

---

## What Gets Installed

### Software
- ✅ Docker & Docker Compose
- ✅ UFW Firewall (configured)
- ✅ Fail2ban (SSH protection)
- ✅ Git, curl, jq

### Application Components
- ✅ PostgreSQL Database
- ✅ Backend Event Generator
- ✅ AI Agent API
- ✅ Web Dashboard
- ✅ Ollama (if LLM mode enabled)

### Security
- ✅ Firewall rules (SSH, Dashboard, API)
- ✅ Fail2ban for SSH protection
- ✅ Non-root user for application
- ✅ Docker security

### Helper Commands
- ✅ `cyber-agent` command for management

---

## Management Commands

The deployment installs a helper command:

```bash
cyber-agent status    # Check service status
cyber-agent logs      # View live logs
cyber-agent restart   # Restart all services
cyber-agent stop      # Stop all services
cyber-agent start     # Start all services
cyber-agent update    # Update and restart
```

Or use Docker Compose directly:

```bash
cd /home/cyber/cyber-agent

# View status
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop everything
docker compose down

# Start everything
docker compose up -d
```

---

## Server Requirements

### Minimum (Rule-Based Mode)
- **CPU**: 2 vCPUs
- **RAM**: 4GB
- **Disk**: 20GB
- **Cost**: ~€10/month (CPX21)

### Recommended (Rule-Based Mode)
- **CPU**: 3 vCPUs
- **RAM**: 8GB
- **Disk**: 40GB
- **Cost**: ~€15/month (CPX21)

### Recommended (LLM Mode)
- **CPU**: 4 vCPUs
- **RAM**: 16GB
- **Disk**: 40GB
- **Cost**: ~€30/month (CPX31)

---

## Firewall Configuration

The script automatically configures UFW:

```bash
# View firewall status
sudo ufw status

# Allow additional port
sudo ufw allow 443/tcp

# Remove rule
sudo ufw delete allow 443/tcp
```

**Default Open Ports:**
- 22 (SSH)
- 3000 (Dashboard)
- 8000 (Agent API)

---

## Troubleshooting

### Check Service Status

```bash
cyber-agent status
```

### View Logs

```bash
# All logs
cyber-agent logs

# Specific service
docker logs cyber-agent
docker logs cyber-backend
docker logs cyber-dashboard
```

### Services Not Starting

```bash
# Restart everything
cyber-agent restart

# Or full restart
cd /home/cyber/cyber-agent
docker compose down
docker compose up -d
```

### Cannot Access Dashboard

```bash
# Check if port is open
sudo ufw status | grep 3000

# Check if service is running
curl http://localhost:3000/health

# Check Docker logs
docker logs cyber-dashboard
```

### Out of Memory

```bash
# Check memory usage
free -h

# Check Docker stats
docker stats

# Solution: Upgrade server or disable LLM mode
cd /home/cyber/cyber-agent
# Edit docker-compose.yml, set USE_LLM=false
docker compose restart agent
```

### Database Connection Errors

```bash
# Restart database
docker restart cyber-events-db

# Check database logs
docker logs cyber-events-db

# Verify database is healthy
docker exec cyber-events-db pg_isready -U postgres
```

---

## Updating the Application

### Method 1: Using Helper Command

```bash
cyber-agent update
```

### Method 2: Manual Update

```bash
cd /home/cyber/cyber-agent
git pull
docker compose pull
docker compose up -d
```

### Method 3: Full Rebuild

```bash
cd /home/cyber/cyber-agent
docker compose down
docker compose build
docker compose up -d
```

---

## Backup & Restore

### Backup Database

```bash
# Create backup
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Download to local machine
scp root@your-server-ip:/root/backup.sql ./
```

### Restore Database

```bash
# Upload backup
scp backup.sql root@your-server-ip:/tmp/

# Restore
docker exec -i cyber-events-db psql -U postgres cyber_events < /tmp/backup.sql
```

### Backup Configuration

```bash
# Backup docker-compose.yml
cp /home/cyber/cyber-agent/docker-compose.yml ~/docker-compose.backup.yml
```

---

## Uninstall

```bash
# Stop and remove containers
cd /home/cyber/cyber-agent
docker compose down -v

# Remove application directory
sudo rm -rf /home/cyber/cyber-agent

# Remove user (optional)
sudo userdel -r cyber

# Remove helper command
sudo rm /usr/local/bin/cyber-agent

# Remove firewall rules (optional)
sudo ufw delete allow 3000/tcp
sudo ufw delete allow 8000/tcp
```

---

## Security Best Practices

### 1. Change Default Passwords

```bash
# Edit docker-compose.yml
cd /home/cyber/cyber-agent
nano docker-compose.yml

# Change POSTGRES_PASSWORD
# Restart services
docker compose down && docker compose up -d
```

### 2. Enable HTTPS (Optional)

```bash
# Install Caddy (reverse proxy with auto HTTPS)
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Configure Caddy
sudo nano /etc/caddy/Caddyfile
```

Add:
```
your-domain.com {
    reverse_proxy localhost:3000
}

api.your-domain.com {
    reverse_proxy localhost:8000
}
```

```bash
# Restart Caddy
sudo systemctl restart caddy

# Open HTTPS port
sudo ufw allow 443/tcp
```

### 3. Regular Updates

```bash
# Update system packages weekly
sudo apt update && sudo apt upgrade -y

# Update application monthly
cyber-agent update
```

### 4. Monitor Logs

```bash
# Check for suspicious activity
sudo tail -f /var/log/auth.log

# Check fail2ban status
sudo fail2ban-client status sshd
```

---

## Cost Estimation

### Monthly Costs (Hetzner)

| Configuration | Server | Cost/Month |
|--------------|--------|------------|
| Rule-Based (Minimum) | CPX11 (2 vCPU, 4GB) | €7 |
| Rule-Based (Recommended) | CPX21 (3 vCPU, 8GB) | €15 |
| LLM Mode (Qwen 1.5B) | CPX31 (4 vCPU, 16GB) | €30 |
| LLM Mode (Qwen 3B) | CPX41 (8 vCPU, 32GB) | €60 |

**Recommendation**: Start with CPX21 + Rule-Based mode (€15/month)

---

## Performance Tuning

### For Small Servers (4-8GB RAM)

Edit `docker-compose.yml`:

```yaml
services:
  db:
    environment:
      - POSTGRES_SHARED_BUFFERS=256MB
      - POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
```

### Reduce Event Generation

Edit `backend/data_generator.py`:

```python
# Reduce number of events
num_login = random.randint(5, 15)  # Instead of 20-80
num_firewall = random.randint(20, 50)  # Instead of 100-300
```

---

## Getting Help

### Check Service Status

```bash
cyber-agent status
```

### View All Logs

```bash
cyber-agent logs
```

### System Information

```bash
# Memory usage
free -h

# Disk usage
df -h

# Docker stats
docker stats

# Running containers
docker ps
```

### Support

- Check logs first: `cyber-agent logs`
- Review README.md in `/home/cyber/cyber-agent`
- Check GitHub issues
- Review this deployment guide

---

## Quick Reference

```bash
# Deployment
./deploy-to-hetzner.sh

# Management
cyber-agent {start|stop|restart|logs|status|update}

# Access
Dashboard:  http://server-ip:3000
API:        http://server-ip:8000
API Docs:   http://server-ip:8000/docs

# Files
Config:     /home/cyber/cyber-agent/docker-compose.yml
Logs:       docker compose logs
Data:       Docker volumes (postgres_data, ollama_data)

# Security
Firewall:   sudo ufw status
Fail2ban:   sudo fail2ban-client status
```

---

**Ready to deploy? Run `./deploy-to-hetzner.sh` on your Hetzner server!** 🚀
