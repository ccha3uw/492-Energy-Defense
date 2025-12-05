# Hetzner Deployment Guide - 492-Energy-Defense

## Quick Start (5 Minutes)

### Prerequisites

- Hetzner Cloud account
- SSH key configured
- Local machine with SSH and rsync

### Step 1: Create Hetzner Server

1. Go to https://console.hetzner.cloud/
2. Create new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 4GB RAM) - €10/month
     - For better performance: CPX31 (4 vCPU, 8GB RAM) - €18/month
   - **Location**: Choose closest to you
   - **SSH Key**: Add your public key
   - **Name**: cyber-defense-agent
3. Click "Create & Buy"
4. **Copy the IP address**: e.g., `65.21.123.45`

### Step 2: Deploy Application

**On your local machine (in project directory):**

```bash
# Make deployment script executable
chmod +x deploy-to-hetzner.sh

# Deploy (replace with your server IP)
./deploy-to-hetzner.sh 65.21.123.45
```

That's it! The script will:
- ✅ Test SSH connection
- ✅ Install Docker & Docker Compose
- ✅ Create application user
- ✅ Configure firewall
- ✅ Copy all files
- ✅ Build Docker images
- ✅ Start all services
- ✅ Download Qwen model

### Step 3: Access Your Application

After deployment completes:

**Dashboard:** http://YOUR_SERVER_IP:3000
**API:** http://YOUR_SERVER_IP:8000
**API Docs:** http://YOUR_SERVER_IP:8000/docs

---

## Detailed Deployment Options

### Option 1: One-Command Deployment (Recommended)

```bash
./deploy-to-hetzner.sh <SERVER_IP>
```

### Option 2: Manual Deployment

```bash
# 1. SSH into server
ssh root@YOUR_SERVER_IP

# 2. Run setup script
curl -fsSL https://raw.githubusercontent.com/your-repo/deployment/server-setup.sh | bash

# 3. Clone repository
git clone YOUR_REPO_URL /home/cyber/cyber-defense
cd /home/cyber/cyber-defense

# 4. Start services
docker-compose up -d
```

### Option 3: Custom User Deployment

```bash
./deploy-to-hetzner.sh <SERVER_IP> <SSH_USER>

# Example with custom user:
./deploy-to-hetzner.sh 65.21.123.45 ubuntu
```

---

## Server Requirements

### Minimum Specs (Rule-Based Mode)
- **CPU**: 2 vCPUs
- **RAM**: 2GB
- **Storage**: 20GB
- **Cost**: ~€5-10/month
- **Hetzner Type**: CX21

### Recommended Specs (LLM Mode with Qwen 1.5B)
- **CPU**: 3-4 vCPUs
- **RAM**: 4-8GB
- **Storage**: 40GB
- **Cost**: ~€10-18/month
- **Hetzner Type**: CPX21 or CPX31

### High Performance (LLM Mode with Qwen 3B)
- **CPU**: 4-8 vCPUs
- **RAM**: 8-16GB
- **Storage**: 40GB
- **Cost**: ~€18-36/month
- **Hetzner Type**: CPX31 or CPX41

---

## Post-Deployment Configuration

### 1. Verify Services

```bash
ssh root@YOUR_SERVER_IP
cd /home/cyber/cyber-defense

# Check container status
docker-compose ps

# Check logs
docker-compose logs -f

# Verify model loaded
./check-qwen-model.sh
```

### 2. Test the API

```bash
# From your local machine
curl http://YOUR_SERVER_IP:8000/health | jq

# Test event analysis
curl -X POST http://YOUR_SERVER_IP:8000/evaluate-event \
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

### 3. Configure Domain (Optional)

If you have a domain:

```bash
# Install nginx
ssh root@YOUR_SERVER_IP
apt-get install -y nginx certbot python3-certbot-nginx

# Configure nginx reverse proxy
cat > /etc/nginx/sites-available/cyber-defense <<EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/cyber-defense /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Get SSL certificate
certbot --nginx -d your-domain.com
```

---

## Management Commands

### On the Server

```bash
# Connect to server
ssh root@YOUR_SERVER_IP
cd /home/cyber/cyber-defense

# View status
docker-compose ps

# View logs
docker-compose logs -f
docker-compose logs -f agent
docker-compose logs -f backend

# Restart services
docker-compose restart
docker-compose restart agent

# Stop services
docker-compose down

# Update application
git pull
docker-compose build
docker-compose up -d

# Check model
./check-qwen-model.sh

# Run tests
./test-llm-mode.sh
```

### From Local Machine

```bash
# SSH into server
ssh root@YOUR_SERVER_IP

# View logs remotely
ssh root@YOUR_SERVER_IP 'cd /home/cyber/cyber-defense && docker-compose logs --tail 100'

# Restart remotely
ssh root@YOUR_SERVER_IP 'cd /home/cyber/cyber-defense && docker-compose restart'

# Check health
curl http://YOUR_SERVER_IP:8000/health
```

---

## Troubleshooting

### Problem: Services not starting

```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Check memory
free -h

# Restart everything
docker-compose down
docker-compose up -d
```

### Problem: Model not loading

```bash
# Pull model manually
docker exec ollama-qwen ollama pull qwen2.5:1.5b

# Check model status
docker exec ollama-qwen ollama list

# Check Ollama logs
docker logs ollama-qwen
```

### Problem: Can't access from outside

```bash
# Check firewall
ufw status

# Open ports
ufw allow 3000/tcp
ufw allow 8000/tcp

# Check if services are listening
netstat -tlnp | grep -E '3000|8000'
```

### Problem: Out of memory

```bash
# Check memory usage
docker stats

# Switch to rule-based mode (no LLM)
cd /home/cyber/cyber-defense
nano docker-compose.yml
# Change: USE_LLM=false

docker-compose restart agent
```

---

## Backup & Restore

### Backup Database

```bash
# On server
cd /home/cyber/cyber-defense

# Backup
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Download to local machine
scp root@YOUR_SERVER_IP:/home/cyber/cyber-defense/backup.sql ./
```

### Restore Database

```bash
# On server
cd /home/cyber/cyber-defense

# Upload backup
scp ./backup.sql root@YOUR_SERVER_IP:/home/cyber/cyber-defense/

# Restore
docker exec -i cyber-events-db psql -U postgres cyber_events < backup.sql
```

---

## Monitoring

### Set Up Monitoring (Optional)

```bash
# Install monitoring tools
ssh root@YOUR_SERVER_IP

# Install htop for system monitoring
apt-get install -y htop

# Monitor in real-time
htop

# Check Docker resource usage
docker stats

# Set up log monitoring
tail -f /var/log/syslog
```

---

## Security Best Practices

1. **Change default passwords**
   ```bash
   # Edit docker-compose.yml and change PostgreSQL password
   POSTGRES_PASSWORD: your_secure_password
   ```

2. **Limit SSH access**
   ```bash
   # Disable password authentication
   nano /etc/ssh/sshd_config
   # Set: PasswordAuthentication no
   systemctl restart sshd
   ```

3. **Keep system updated**
   ```bash
   apt-get update && apt-get upgrade -y
   ```

4. **Set up automatic updates**
   ```bash
   apt-get install -y unattended-upgrades
   dpkg-reconfigure --priority=low unattended-upgrades
   ```

---

## Cost Optimization

### For Development/Testing

**CPX11** (2 vCPU, 2GB RAM) - €4.51/month
- Use rule-based mode (USE_LLM=false)
- Suitable for testing

### For Production (Small)

**CPX21** (3 vCPU, 4GB RAM) - €10.90/month
- Use Qwen 1.5B model
- Good for moderate load

### For Production (High Performance)

**CPX31** (4 vCPU, 8GB RAM) - €18.90/month
- Use Qwen 3B model
- Better performance and accuracy

---

## Updates & Maintenance

### Update Application

```bash
# On server
cd /home/cyber/cyber-defense

# Pull latest changes
git pull

# Rebuild and restart
docker-compose build
docker-compose up -d
```

### Update Docker Images

```bash
# Pull latest base images
docker-compose pull

# Rebuild
docker-compose build

# Restart
docker-compose up -d
```

---

## Support

If you encounter issues:

1. Check logs: `docker-compose logs`
2. Check service status: `docker-compose ps`
3. Review this guide
4. Check firewall settings: `ufw status`
5. Verify disk space: `df -h`
6. Check memory: `free -h`

---

## Quick Reference

```bash
# Deploy
./deploy-to-hetzner.sh <SERVER_IP>

# Connect
ssh root@<SERVER_IP>

# Navigate to app
cd /home/cyber/cyber-defense

# Common commands
docker-compose ps          # Status
docker-compose logs -f     # Logs
docker-compose restart     # Restart
docker-compose down        # Stop
docker-compose up -d       # Start

# Access
http://<SERVER_IP>:3000    # Dashboard
http://<SERVER_IP>:8000    # API
```

---

**Deployment time: ~5 minutes**
**Cost: From €4.51/month**
**Fully automated setup**
