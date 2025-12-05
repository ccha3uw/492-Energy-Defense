# Deployment Package Overview

This repository includes everything needed for **one-command deployment** to Hetzner Cloud.

## 📦 What's Included

### Deployment Scripts
- **`deploy-to-hetzner.sh`** - Main deployment script (one command!)
- **`health-check.sh`** - Verify deployment status
- **`apply-fix.sh`** - Fix Qwen model scoring issues

### Documentation
- **`DEPLOYMENT_QUICKSTART.md`** - 5-minute deployment guide
- **`HETZNER_DEPLOYMENT.md`** - Complete deployment documentation
- **`FIX_QWEN_SCORING_ISSUE.md`** - Fix LLM scoring problems

### Configuration
- **`docker-compose.yml`** - Service orchestration
- **`deploy-config.env.example`** - Deployment settings template
- **`.deployignore`** - Files excluded from deployment

### Application
- **`agent/`** - AI agent service
- **`backend/`** - Event generator & database
- **`dashboard/`** - Web interface

---

## 🚀 Quick Start

### Deploy to Hetzner (5 minutes)

```bash
# 1. Create Hetzner server (Ubuntu 22.04, 8GB RAM)
# 2. Note the IP address

# 3. Deploy
./deploy-to-hetzner.sh YOUR_SERVER_IP

# 4. Access
open http://YOUR_SERVER_IP:3000
```

**That's it!** ✨

---

## 📖 Documentation Guide

### For Quick Deployment
→ Read **`DEPLOYMENT_QUICKSTART.md`** (5 minutes)

### For Complete Details
→ Read **`HETZNER_DEPLOYMENT.md`** (full guide)

### For Application Usage
→ Read **`README.md`** (main docs)

### For Model Issues
→ Read **`FIX_QWEN_SCORING_ISSUE.md`**

---

## 🎯 Deployment Features

### ✅ Fully Automated
- Installs Docker & Docker Compose
- Configures firewall
- Uploads application
- Starts all services
- Downloads AI model

### ✅ Zero Configuration
- Works out of the box
- Sensible defaults
- No manual setup needed

### ✅ Production Ready
- Health checks
- Automatic restarts
- Log management
- Resource limits

### ✅ Secure
- Firewall configured
- Service isolation
- Volume persistence

---

## 💰 Server Requirements

### Minimum (Rule-Based Mode)
- **Type**: CX21
- **RAM**: 4GB
- **CPU**: 2 vCPU
- **Cost**: ~€6/month

### Recommended (LLM Mode)
- **Type**: CX31
- **RAM**: 8GB
- **CPU**: 2 vCPU
- **Cost**: ~€13/month

### High Performance
- **Type**: CPX31
- **RAM**: 16GB
- **CPU**: 4 vCPU
- **Cost**: ~€20/month

---

## 🔧 Management

### View Logs
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose logs -f
```

### Restart Services
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose restart
```

### Check Health
```bash
./health-check.sh YOUR_IP
```

### Update Application
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
git pull  # or upload new files
docker-compose down
docker-compose build
docker-compose up -d
```

---

## 🛠️ Customization

### Change to Rule-Based Mode
```bash
# Edit docker-compose.yml on server
USE_LLM=false

# Restart
docker-compose restart agent
```

### Change AI Model
```bash
# Edit docker-compose.yml on server
OLLAMA_MODEL=qwen2.5:1.5b

# Pull and restart
docker exec ollama-qwen ollama pull qwen2.5:1.5b
docker-compose restart agent
```

### Change Ports
```bash
# Edit docker-compose.yml on server
ports:
  - "8080:3000"  # Dashboard on port 8080
  - "9000:8000"  # API on port 9000
```

---

## 📊 What Gets Deployed

After deployment, you'll have:

- **📊 Dashboard** - Web interface at `:3000`
- **🤖 Agent API** - REST API at `:8000`
- **🐘 PostgreSQL** - Database at `:5432`
- **🧠 Ollama** - AI model server (internal)
- **🔄 Backend** - Event generator (internal)

All running in Docker containers with automatic restarts.

---

## 🔐 Security Checklist

After deployment:

- [ ] Change database password in `docker-compose.yml`
- [ ] Restrict firewall to your IP
- [ ] Setup domain with SSL (optional)
- [ ] Configure backups
- [ ] Review logs regularly

See **`HETZNER_DEPLOYMENT.md`** for details.

---

## 🐛 Troubleshooting

### Deployment fails?
```bash
# Check SSH connection
ssh root@YOUR_IP

# Check logs
./deploy-to-hetzner.sh YOUR_IP 2>&1 | tee deploy.log
```

### Services not starting?
```bash
ssh root@YOUR_IP
cd /opt/cyber-defense
docker-compose logs
docker-compose ps
```

### Can't access services?
```bash
# Check firewall
ssh root@YOUR_IP
ufw status

# Allow ports
ufw allow 3000/tcp
ufw allow 8000/tcp
```

### Model scoring incorrect?
```bash
# See FIX_QWEN_SCORING_ISSUE.md
./apply-fix.sh
```

---

## 📁 File Structure

```
.
├── deploy-to-hetzner.sh          # Main deployment script ⭐
├── health-check.sh                # Health verification
├── apply-fix.sh                   # Model fix script
│
├── DEPLOYMENT_QUICKSTART.md       # Quick guide ⭐
├── HETZNER_DEPLOYMENT.md          # Full guide
├── FIX_QWEN_SCORING_ISSUE.md     # Model fixes
├── README_DEPLOYMENT.md           # This file
│
├── docker-compose.yml             # Service config
├── deploy-config.env.example      # Config template
├── .deployignore                  # Exclude list
│
├── agent/                         # AI agent code
├── backend/                       # Backend code
├── dashboard/                     # Web UI code
│
└── README.md                      # Main application docs
```

---

## 🎓 Learn More

### Deployment
- [Quick Start](DEPLOYMENT_QUICKSTART.md) - 5-minute guide
- [Full Guide](HETZNER_DEPLOYMENT.md) - Complete documentation

### Application
- [README](README.md) - Main documentation
- [Project Summary](PROJECT_SUMMARY.md) - Technical overview (if exists)

### Issues
- [Model Fix](FIX_QWEN_SCORING_ISSUE.md) - Scoring problems
- [Troubleshooting](HETZNER_DEPLOYMENT.md#troubleshooting) - Common issues

---

## 🆘 Support

**Quick Help:**
```bash
# Health check
./health-check.sh YOUR_IP

# View logs
ssh root@YOUR_IP 'cd /opt/cyber-defense && docker-compose logs'

# Check status
ssh root@YOUR_IP 'cd /opt/cyber-defense && docker-compose ps'
```

**Need more help?**
- Check `HETZNER_DEPLOYMENT.md`
- Review application logs
- Check Hetzner status page

---

## ✨ Summary

This is a **complete deployment package** with:
- ✅ One-command deployment
- ✅ Automated setup
- ✅ Health monitoring
- ✅ Comprehensive documentation
- ✅ Production ready

**Get started:**
```bash
./deploy-to-hetzner.sh YOUR_SERVER_IP
```

**Access:**
- Dashboard: `http://YOUR_IP:3000`
- API: `http://YOUR_IP:8000/docs`

**That's it!** 🎉

---

*Built for easy deployment to Hetzner Cloud*
