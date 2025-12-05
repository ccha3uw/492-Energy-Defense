# 🚀 Hetzner Deployment Package - 492 Energy Defense

## Quick Deploy (5 Minutes)

### Step 1: Create Hetzner Server

1. Go to https://console.hetzner.cloud/
2. Create a new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 8GB RAM) - €15/month
   - **Location**: Closest to you
   - **SSH Key**: Add your public key
   - **Name**: cyber-defense-agent
3. Copy the server IP address

### Step 2: Deploy from Your Local Machine

```bash
# Clone or download this repository
cd hetzner-deploy

# Make deployment script executable
chmod +x deploy-to-hetzner.sh

# Run deployment (replace with your server IP)
./deploy-to-hetzner.sh YOUR_SERVER_IP
```

That's it! The script will:
- ✅ Configure the server
- ✅ Install Docker
- ✅ Upload all files
- ✅ Start services
- ✅ Download the AI model
- ✅ Run health checks

### Step 3: Verify

```bash
# Check status
ssh root@YOUR_SERVER_IP '/opt/cyber-defense/status.sh'

# View dashboard (if configured)
# Open: http://YOUR_SERVER_IP:3000

# Test the API
curl http://YOUR_SERVER_IP:8000/health
```

---

## What Gets Deployed

### Services
- 🤖 **AI Agent** (Port 8000) - Analyzes security events
- 🗄️ **PostgreSQL** (Port 5432) - Stores events and analysis
- 🧠 **Ollama** (Port 11434) - Qwen AI model
- 📊 **Dashboard** (Port 3000) - Web interface (optional)
- ⚙️ **Backend** - Generates events every 30 minutes

### Configuration
- **Default Mode**: Rule-based (100% accurate, no LLM overhead)
- **Model**: Qwen 2.5 1.5B (if you enable LLM mode)
- **Memory**: 6-8GB RAM used
- **Storage**: ~5GB used

---

## Server Requirements

### Minimum (Rule-Based Mode)
- **CPU**: 2 vCPUs
- **RAM**: 4 GB
- **Storage**: 20 GB
- **Cost**: ~€5-10/month
- **Hetzner Type**: CX21

### Recommended (LLM Mode)
- **CPU**: 3-4 vCPUs
- **RAM**: 8 GB
- **Storage**: 40 GB
- **Cost**: ~€15/month
- **Hetzner Type**: CPX21 or CPX31

### High Performance
- **CPU**: 4-8 vCPUs
- **RAM**: 16 GB
- **Storage**: 80 GB
- **Cost**: ~€30/month
- **Hetzner Type**: CPX31 or CPX41

---

## Deployment Options

### Option 1: Full Automated (Recommended)
```bash
./deploy-to-hetzner.sh YOUR_IP
```
Deploys everything automatically.

### Option 2: Step-by-Step
```bash
# 1. Setup server
./setup-server.sh YOUR_IP

# 2. Deploy application
./deploy-app.sh YOUR_IP

# 3. Configure services
./configure-services.sh YOUR_IP
```

### Option 3: Manual
See `MANUAL_DEPLOYMENT.md`

---

## Post-Deployment

### Check Status
```bash
ssh root@YOUR_IP '/opt/cyber-defense/status.sh'
```

### View Logs
```bash
ssh root@YOUR_IP 'cd /opt/cyber-defense && docker-compose logs -f'
```

### Test the Agent
```bash
curl -X POST http://YOUR_IP:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "admin",
      "status": "FAIL",
      "is_admin": true
    }
  }'
```

### Enable Dashboard
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose up -d dashboard
```

Then visit: http://YOUR_IP:3000

---

## Configuration

### Switch to LLM Mode
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
nano docker-compose.yml
# Change: USE_LLM=true
docker-compose restart agent
```

### Change Model
```bash
# Edit docker-compose.yml
OLLAMA_MODEL=qwen2.5:3b  # or qwen2.5:1.5b

# Pull new model
docker exec ollama-qwen ollama pull qwen2.5:3b
docker-compose restart agent
```

### Scale Resources
Edit `docker-compose.yml` memory limits:
```yaml
deploy:
  resources:
    limits:
      memory: 8G  # Adjust as needed
```

---

## Firewall Configuration

The deployment automatically configures UFW firewall:
- ✅ Port 22 (SSH)
- ✅ Port 8000 (Agent API)
- ✅ Port 3000 (Dashboard - optional)
- ❌ Port 5432 (Database - internal only)
- ❌ Port 11434 (Ollama - internal only)

---

## Backup & Restore

### Backup Database
```bash
ssh root@YOUR_IP '/opt/cyber-defense/backup.sh'
```

Downloads to: `/opt/cyber-defense/backups/`

### Restore Database
```bash
ssh root@YOUR_IP '/opt/cyber-defense/restore.sh backup_file.sql'
```

---

## Troubleshooting

### Services Not Starting
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose ps
docker-compose logs
```

### Out of Memory
```bash
# Check memory usage
ssh root@YOUR_IP 'free -h'

# Upgrade server or disable LLM mode
```

### Can't Connect
```bash
# Check firewall
ssh root@YOUR_IP 'ufw status'

# Allow ports if needed
ssh root@YOUR_IP 'ufw allow 8000/tcp'
```

### Model Download Stuck
```bash
ssh root@YOUR_IP
docker exec ollama-qwen ollama pull qwen2.5:1.5b --debug
```

---

## Updating

### Update Application
```bash
./deploy-to-hetzner.sh YOUR_IP
# Choose "Update" when prompted
```

### Update Docker Images
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose pull
docker-compose up -d
```

---

## Uninstall

```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose down -v
rm -rf /opt/cyber-defense
```

---

## Cost Estimation

### Monthly Costs (Hetzner)

| Configuration | Server Type | RAM | Cost/Month |
|---------------|-------------|-----|------------|
| Minimal | CX21 | 4GB | €5.83 |
| Recommended | CPX21 | 8GB | €14.30 |
| High Performance | CPX31 | 16GB | €29.50 |
| Maximum | CPX41 | 32GB | €59.00 |

Plus:
- Backup space: ~€0.50/month
- Traffic: Free (20TB included)

---

## Security Notes

### Default Settings
- ✅ UFW firewall enabled
- ✅ Only necessary ports open
- ✅ Database not exposed externally
- ✅ Docker network isolation
- ⚠️ Default database password (change in production)

### Production Recommendations
1. Change database password in `docker-compose.yml`
2. Add SSL/TLS with nginx reverse proxy
3. Enable SSH key-only authentication
4. Set up automated backups
5. Configure log rotation
6. Enable fail2ban for SSH protection

---

## Support

### Get Help
- Check logs: `docker-compose logs`
- Run status check: `./status.sh`
- Review `TROUBLESHOOTING.md`

### Common Issues
- **Model too large**: Switch to rule-based mode or smaller model
- **Out of memory**: Upgrade server or reduce Docker memory limits
- **Slow performance**: Check CPU usage, consider upgrade

---

## Next Steps

After deployment:
1. ✅ Verify all services are running
2. ✅ Test the API with sample events
3. ✅ Review the logs
4. ✅ Configure backups
5. ✅ Set up monitoring (optional)
6. ✅ Enable dashboard (optional)

---

**Questions? Check the full documentation or run `./status.sh` on the server.**
