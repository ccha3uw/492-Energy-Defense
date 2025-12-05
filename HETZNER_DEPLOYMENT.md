# 🚀 Hetzner Deployment Guide

Complete guide to deploying the 492-Energy-Defense Cybersecurity Agent to Hetzner Cloud.

## Prerequisites

- Hetzner Cloud account
- SSH key configured
- Local machine with SSH and Docker (for testing)

---

## Quick Deployment (5 Minutes)

### Step 1: Create Hetzner Server

1. **Go to Hetzner Cloud Console**: https://console.hetzner.cloud/

2. **Create a new server:**
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CX31 (2 vCPU, 8GB RAM) - €10/month minimum
   - **Location**: Choose closest to you
   - **SSH Key**: Add your public key
   - **Name**: cyber-defense-agent
   
3. **Note the IP address** (e.g., 65.21.123.45)

### Step 2: Deploy Application

From your local machine where you have this repository:

```bash
# Make deployment script executable
chmod +x deploy-to-hetzner.sh

# Deploy (replace with your server IP)
./deploy-to-hetzner.sh 65.21.123.45
```

**That's it!** The script will:
- ✅ Test SSH connection
- ✅ Install Docker & Docker Compose
- ✅ Upload application files
- ✅ Configure firewall
- ✅ Start all services
- ✅ Download Qwen model

**Wait 1-2 minutes** for the model to download, then access:
- **Dashboard**: http://65.21.123.45:3000
- **API**: http://65.21.123.45:8000/docs

---

## Server Requirements

### Minimum Configuration (Rule-Based Mode)
- **CPU**: 2 vCPUs
- **RAM**: 4 GB
- **Storage**: 20 GB SSD
- **Cost**: ~€5-7/month
- **Hetzner Type**: CX21 or CPX11

### Recommended Configuration (LLM Mode)
- **CPU**: 2-4 vCPUs
- **RAM**: 8 GB
- **Storage**: 40 GB SSD
- **Cost**: ~€10-15/month
- **Hetzner Type**: CX31 or CPX21

### High Performance (LLM Mode + High Load)
- **CPU**: 4-8 vCPUs
- **RAM**: 16 GB
- **Storage**: 80 GB SSD
- **Cost**: ~€30-40/month
- **Hetzner Type**: CPX31 or CX41

---

## Manual Deployment

If you prefer manual deployment:

### 1. Create Server
```bash
# SSH into your Hetzner server
ssh root@65.21.123.45
```

### 2. Install Dependencies
```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y curl git docker.io docker-compose jq ufw

# Enable Docker
systemctl enable docker
systemctl start docker
```

### 3. Clone/Upload Repository
```bash
# Create deployment directory
mkdir -p /opt/cyber-defense
cd /opt/cyber-defense

# Upload files (from local machine)
# Option A: Using git
git clone <your-repo-url> .

# Option B: Using SCP (from local machine)
scp -r ./* root@65.21.123.45:/opt/cyber-defense/
```

### 4. Configure Firewall
```bash
# Enable firewall
ufw --force enable

# Allow SSH (prevent lockout!)
ufw allow 22/tcp

# Allow application ports
ufw allow 8000/tcp  # Agent API
ufw allow 3000/tcp  # Dashboard
ufw allow 5432/tcp  # PostgreSQL (optional)

# Check status
ufw status
```

### 5. Start Application
```bash
cd /opt/cyber-defense

# Start services
docker-compose up -d

# Check status
docker-compose ps

# Watch model download
docker logs -f ollama-init
```

---

## Post-Deployment

### Verify Deployment

```bash
# Check all containers are running
docker-compose ps

# Should show:
# - cyber-events-db (healthy)
# - ollama-qwen (healthy)
# - cyber-agent (healthy)
# - cyber-backend (running)
# - cyber-dashboard (healthy)
```

### Test API

```bash
# From your local machine
curl http://65.21.123.45:8000/health | jq

# Should return:
# {
#   "status": "healthy",
#   "service": "492-Energy-Defense Cyber Event Triage Agent",
#   ...
# }
```

### Access Dashboard

Open in browser: **http://65.21.123.45:3000**

You should see the security dashboard with real-time alerts.

---

## Management Commands

All commands should be run on the Hetzner server:

```bash
# SSH into server
ssh root@65.21.123.45
cd /opt/cyber-defense

# View logs
docker-compose logs -f

# View specific service logs
docker logs -f cyber-agent
docker logs -f cyber-backend
docker logs -f cyber-dashboard

# Check service status
docker-compose ps

# Restart services
docker-compose restart

# Restart specific service
docker-compose restart agent

# Stop all services
docker-compose down

# Stop and remove data
docker-compose down -v

# Update application (after git pull)
docker-compose down
docker-compose build
docker-compose up -d
```

---

## Environment Configuration

### Change LLM Mode

Edit `/opt/cyber-defense/docker-compose.yml`:

```yaml
agent:
  environment:
    - USE_LLM=false  # false = rule-based, true = LLM mode
```

Restart:
```bash
docker-compose restart agent
```

### Change Model

Edit `/opt/cyber-defense/docker-compose.yml`:

```yaml
agent:
  environment:
    - OLLAMA_MODEL=qwen2.5:1.5b  # or qwen2.5:3b
```

Restart and pull new model:
```bash
docker-compose restart agent
docker exec ollama-qwen ollama pull qwen2.5:1.5b
```

### Change Database Credentials

Edit `/opt/cyber-defense/docker-compose.yml`:

```yaml
db:
  environment:
    POSTGRES_PASSWORD: your_secure_password
```

Update connection strings in backend and dashboard sections.

---

## Security Best Practices

### 1. Change Default Passwords

```bash
# Edit docker-compose.yml
# Change POSTGRES_PASSWORD from 'postgres' to something secure
```

### 2. Restrict Port Access

```bash
# Only allow your IP to access services
ufw delete allow 8000/tcp
ufw delete allow 3000/tcp
ufw delete allow 5432/tcp

# Allow only from your IP (replace with your IP)
ufw allow from 1.2.3.4 to any port 8000
ufw allow from 1.2.3.4 to any port 3000
```

### 3. Setup Domain & SSL

```bash
# Install Nginx
apt install -y nginx certbot python3-certbot-nginx

# Create Nginx config
cat > /etc/nginx/sites-available/cyber-defense << 'EOF'
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/cyber-defense /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Get SSL certificate
certbot --nginx -d your-domain.com
```

### 4. Setup Automatic Backups

```bash
# Create backup script
cat > /root/backup-cyber-defense.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec cyber-events-db pg_dump -U postgres cyber_events > $BACKUP_DIR/db-$DATE.sql

# Backup docker volumes
docker run --rm -v cyber-defense_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/volumes-$DATE.tar.gz /data

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /root/backup-cyber-defense.sh

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /root/backup-cyber-defense.sh") | crontab -
```

---

## Monitoring

### Check Resource Usage

```bash
# System resources
htop

# Docker stats
docker stats

# Disk usage
df -h
du -sh /var/lib/docker
```

### Setup Monitoring Alerts

```bash
# Install monitoring tools
apt install -y prometheus-node-exporter

# Or use Hetzner Cloud Console monitoring
```

---

## Troubleshooting

### Issue: Cannot connect to server

**Check:**
```bash
# Verify server is running (Hetzner Console)
# Check SSH key is correct
ssh-add -l

# Try with verbose output
ssh -v root@65.21.123.45
```

### Issue: Services not starting

**Check logs:**
```bash
docker-compose logs
docker logs ollama-qwen
docker logs cyber-agent
```

**Restart:**
```bash
docker-compose down
docker-compose up -d
```

### Issue: Out of memory

**Check memory:**
```bash
free -h
docker stats --no-stream
```

**Solution:** Upgrade to larger server or disable LLM mode.

### Issue: Firewall blocking access

**Check firewall:**
```bash
ufw status verbose
```

**Allow ports:**
```bash
ufw allow 8000/tcp
ufw allow 3000/tcp
```

### Issue: Model not downloading

**Manual pull:**
```bash
docker exec ollama-qwen ollama pull qwen2.5:0.5b
docker logs ollama-qwen
```

---

## Scaling Options

### Horizontal Scaling

Run multiple instances behind a load balancer:

```bash
# Install HAProxy
apt install -y haproxy

# Configure load balancing
# (See HAProxy documentation)
```

### Vertical Scaling

Resize your Hetzner server:
1. Stop services: `docker-compose down`
2. Power off server (Hetzner Console)
3. Resize server (Hetzner Console)
4. Power on server
5. Start services: `docker-compose up -d`

---

## Cost Estimation

| Configuration | Server Type | Cost/Month | Use Case |
|---------------|-------------|------------|----------|
| Minimum | CX21 | ~€6 | Testing, rule-based mode |
| Recommended | CX31 | ~€13 | Production, LLM mode |
| High Performance | CPX31 | ~€20 | High load, LLM mode |
| Enterprise | CX41 | ~€29 | Multiple instances |

*Prices as of 2025 - check Hetzner for current pricing*

---

## Uninstall

To completely remove the application:

```bash
# Stop and remove containers
cd /opt/cyber-defense
docker-compose down -v

# Remove application files
rm -rf /opt/cyber-defense

# Remove Docker images (optional)
docker system prune -a

# Remove firewall rules
ufw delete allow 8000/tcp
ufw delete allow 3000/tcp
ufw delete allow 5432/tcp
```

---

## Support

- **Documentation**: See README.md in repository
- **Issues**: Check application logs
- **Hetzner Support**: https://docs.hetzner.com/

---

## Summary

**Quick Deploy:**
```bash
./deploy-to-hetzner.sh 65.21.123.45
```

**Access:**
- Dashboard: http://YOUR_IP:3000
- API: http://YOUR_IP:8000

**Manage:**
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose logs -f
```

That's it! 🚀
