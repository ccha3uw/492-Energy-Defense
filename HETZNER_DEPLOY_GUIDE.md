# 🚀 Easy Hetzner Deployment Guide

## One-Command Deployment

Deploy the entire cybersecurity agent to a Hetzner server in minutes!

## Prerequisites

### 1. Local Machine
- SSH client installed
- SSH key configured for server access
- Git (to clone this repo)

### 2. Hetzner Cloud Server

**Minimum Specs:**
- **CPU**: 2 vCPUs
- **RAM**: 4 GB
- **Storage**: 20 GB SSD
- **OS**: Ubuntu 22.04 or 24.04 LTS

**Recommended Specs:**
- **CPU**: 4 vCPUs
- **RAM**: 8 GB
- **Storage**: 40 GB SSD
- **Server Type**: CPX21 (~€8/month) or CPX31 (~€15/month)

### 3. Create Server on Hetzner

1. Go to https://console.hetzner.cloud/
2. Create new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (2 vCPU, 4GB RAM) or better
   - **Location**: Nearest to you
   - **SSH Key**: Add your public SSH key
   - **Name**: cyber-defense
3. Click "Create & Buy Now"
4. **Note the IP address** (e.g., 65.21.123.45)

---

## 🎯 Deployment (One Command)

From your local machine, in the project directory:

```bash
./hetzner-deploy.sh 65.21.123.45
```

Replace `65.21.123.45` with your server's IP address.

### What It Does

The script automatically:
1. ✅ Tests SSH connection
2. ✅ Installs Docker & Docker Compose
3. ✅ Transfers all project files
4. ✅ Configures environment
5. ✅ Starts all services
6. ✅ Downloads Qwen model (~400MB)
7. ✅ Verifies deployment

**Time**: ~3-5 minutes

---

## 📊 Access Your Services

After deployment completes:

### Dashboard (Web Interface)
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

## 🔐 Secure Your Server

After deployment, configure the firewall:

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Configure firewall
ufw allow 22/tcp      # SSH
ufw allow 3000/tcp    # Dashboard
ufw allow 8000/tcp    # Agent API
ufw enable

# Optional: Restrict to specific IPs
# ufw allow from YOUR_IP to any port 3000
```

---

## 🔧 Server Management

### SSH into Server
```bash
ssh root@YOUR_SERVER_IP
cd /opt/cyber-defense
```

### Check Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All logs
docker-compose logs -f

# Specific service
docker logs -f cyber-agent
docker logs -f cyber-backend
docker logs -f cyber-dashboard
docker logs -f ollama-qwen
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart agent
```

### Stop Services
```bash
docker-compose down
```

### Start Services
```bash
docker-compose up -d
```

### Check Qwen Model Status
```bash
./check-qwen-model.sh
```

### Update Code
```bash
cd /opt/cyber-defense
git pull  # If using git
docker-compose down
docker-compose build
docker-compose up -d
```

---

## 🧪 Test Your Deployment

### From Your Local Machine

```bash
# Check agent health
curl http://YOUR_SERVER_IP:8000/health | jq

# Test event analysis
curl -X POST http://YOUR_SERVER_IP:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "admin",
      "status": "FAIL",
      "timestamp": "2025-12-02T02:30:00",
      "is_admin": true,
      "is_burst_failure": true,
      "is_suspicious_ip": true
    }
  }' | jq
```

### From the Server

```bash
ssh root@YOUR_SERVER_IP
cd /opt/cyber-defense
./test-llm-mode.sh
```

---

## 🐛 Troubleshooting

### Services Not Starting

```bash
# Check logs for errors
docker-compose logs

# Check resource usage
docker stats

# Restart everything
docker-compose down
docker-compose up -d
```

### Qwen Model Not Loading

```bash
# Check Ollama logs
docker logs ollama-qwen

# Manually pull model
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Verify model
docker exec ollama-qwen ollama list
```

### Agent Not Responding

```bash
# Check agent logs
docker logs cyber-agent

# Check if Ollama is accessible
docker exec cyber-agent curl http://ollama:11434/api/tags

# Restart agent
docker-compose restart agent
```

### Database Issues

```bash
# Check database logs
docker logs cyber-events-db

# Restart database
docker-compose restart db

# Recreate database (WARNING: deletes data)
docker-compose down -v
docker-compose up -d
```

### Out of Memory

```bash
# Check memory usage
free -h

# Check container memory
docker stats

# Reduce memory if needed (edit docker-compose.yml)
# Reduce Ollama memory limit or switch to rule-based mode
```

---

## 📈 Monitoring

### System Resources
```bash
# CPU and Memory
htop

# Disk usage
df -h

# Container stats
docker stats
```

### Service Health
```bash
# All services
docker-compose ps

# Agent health
curl http://localhost:8000/health | jq

# Database status
docker exec cyber-events-db pg_isready -U postgres
```

### Event Statistics
```bash
# Connect to database
docker exec -it cyber-events-db psql -U postgres -d cyber_events

# Count events
SELECT event_type, COUNT(*) FROM event_analyses GROUP BY event_type;

# Recent critical events
SELECT * FROM event_analyses WHERE severity = 'critical' ORDER BY analyzed_at DESC LIMIT 10;
```

---

## 🔄 Updates and Maintenance

### Update System
```bash
apt-get update
apt-get upgrade -y
reboot  # If kernel updated
```

### Update Docker Images
```bash
cd /opt/cyber-defense
docker-compose pull
docker-compose up -d
```

### Backup Data
```bash
# Backup database
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Backup volumes
docker run --rm -v cyber-defense_postgres_data:/data -v $(pwd):/backup \
    ubuntu tar czf /backup/postgres-backup.tar.gz /data
```

### Restore Data
```bash
# Restore database
cat backup.sql | docker exec -i cyber-events-db psql -U postgres cyber_events
```

---

## 💰 Cost Optimization

### Reduce Costs
1. **Use Rule-Based Mode** (no Ollama needed):
   - Edit `docker-compose.yml`: `USE_LLM=false`
   - Saves 2-4GB RAM
   - Use smaller server (CPX11, ~€5/month)

2. **Use Smaller Model**:
   - Current: Qwen 0.5B (~400MB, 2-4GB RAM)
   - If accuracy issues, upgrade to 1.5B (~900MB, 3-4GB RAM)

3. **Schedule Snapshots**:
   - Take regular snapshots in Hetzner Console
   - Delete old backups

### Scale Up if Needed
```bash
# In Hetzner Console:
# 1. Power off server
# 2. Click "Resize"
# 3. Select larger type
# 4. Power on
```

---

## 🆘 Quick Commands Reference

### Deployment
```bash
./hetzner-deploy.sh YOUR_SERVER_IP
```

### SSH Access
```bash
ssh root@YOUR_SERVER_IP
cd /opt/cyber-defense
```

### Service Control
```bash
docker-compose ps              # Status
docker-compose logs -f         # Logs
docker-compose restart         # Restart
docker-compose down            # Stop
docker-compose up -d           # Start
```

### Testing
```bash
curl http://localhost:8000/health | jq
./test-llm-mode.sh
./check-qwen-model.sh
```

### Troubleshooting
```bash
docker logs cyber-agent
docker logs ollama-qwen
docker stats
free -h
```

---

## 📞 Support

If you encounter issues:

1. **Check logs**: `docker-compose logs`
2. **Check resources**: `docker stats` and `free -h`
3. **Restart services**: `docker-compose restart`
4. **Review documentation**: See README.md
5. **Full reset**: `docker-compose down -v && docker-compose up -d`

---

## 📚 Additional Resources

- **Main README**: `/opt/cyber-defense/README.md`
- **Dashboard Guide**: `/opt/cyber-defense/DASHBOARD_README.md`
- **Fix Scoring Issues**: `/opt/cyber-defense/FIX_QWEN_SCORING_ISSUE.md`
- **Hetzner Docs**: https://docs.hetzner.com/

---

## ✅ Deployment Checklist

- [ ] Server created on Hetzner
- [ ] SSH key configured
- [ ] Deployment script executed successfully
- [ ] Services are running (`docker-compose ps`)
- [ ] Dashboard accessible at http://SERVER_IP:3000
- [ ] Agent responding at http://SERVER_IP:8000/health
- [ ] Firewall configured
- [ ] Backup strategy planned
- [ ] Monitoring set up

---

**That's it! Your cybersecurity agent is now running on Hetzner Cloud! 🎉**
