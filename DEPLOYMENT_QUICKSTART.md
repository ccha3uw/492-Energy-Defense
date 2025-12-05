# 🚀 Deployment Quickstart

Deploy the 492-Energy-Defense Cybersecurity Agent to Hetzner Cloud in **5 minutes**.

## Prerequisites

- Hetzner Cloud account
- SSH key configured
- This repository on your local machine

---

## Step 1: Create Hetzner Server (2 minutes)

1. Go to: **https://console.hetzner.cloud/**

2. Click **"Add Server"**

3. Choose configuration:
   ```
   Image:     Ubuntu 22.04 LTS
   Type:      CX31 (2 vCPU, 8GB RAM) - €13/month
   Location:  Closest to you
   SSH Key:   Add your public key
   Name:      cyber-defense
   ```

4. Click **"Create & Buy Now"**

5. **Copy the IP address** (e.g., `65.21.123.45`)

---

## Step 2: Deploy (1 minute)

On your local machine:

```bash
# Navigate to project directory
cd /path/to/492-energy-defense

# Make script executable (first time only)
chmod +x deploy-to-hetzner.sh

# Deploy (replace with YOUR server IP)
./deploy-to-hetzner.sh 65.21.123.45
```

**That's it!** ✨

The script will automatically:
- ✅ Install Docker & Docker Compose
- ✅ Upload application files
- ✅ Configure firewall
- ✅ Start all services
- ✅ Download AI model

---

## Step 3: Access (1 minute)

Wait 1-2 minutes for the model to download, then:

**Dashboard (Web UI):**
```
http://65.21.123.45:3000
```

**API Documentation:**
```
http://65.21.123.45:8000/docs
```

**Health Check:**
```bash
curl http://65.21.123.45:8000/health | jq
```

---

## Quick Commands

### View Logs
```bash
ssh root@65.21.123.45
cd /opt/cyber-defense
docker-compose logs -f
```

### Restart Services
```bash
ssh root@65.21.123.45
cd /opt/cyber-defense
docker-compose restart
```

### Check Status
```bash
ssh root@65.21.123.45
cd /opt/cyber-defense
docker-compose ps
```

### Run Health Check
```bash
./health-check.sh 65.21.123.45
```

---

## Troubleshooting

### Can't SSH to server?

```bash
# Add your SSH key
ssh-copy-id root@65.21.123.45

# Or specify key manually
ssh -i ~/.ssh/id_rsa root@65.21.123.45
```

### Services not starting?

```bash
# SSH into server
ssh root@65.21.123.45
cd /opt/cyber-defense

# Check logs
docker-compose logs

# Restart
docker-compose restart
```

### Firewall blocking access?

```bash
ssh root@65.21.123.45

# Allow ports
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw status
```

---

## Configuration Options

### Switch to Rule-Based Mode (No LLM)

```bash
ssh root@65.21.123.45
cd /opt/cyber-defense

# Edit docker-compose.yml
nano docker-compose.yml

# Change: USE_LLM=true to USE_LLM=false
# Save and restart
docker-compose restart agent
```

### Change Model

```bash
ssh root@65.21.123.45
cd /opt/cyber-defense

# Edit docker-compose.yml
nano docker-compose.yml

# Change: OLLAMA_MODEL=qwen2.5:0.5b
#      to: OLLAMA_MODEL=qwen2.5:1.5b

# Save, pull new model, and restart
docker exec ollama-qwen ollama pull qwen2.5:1.5b
docker-compose restart agent
```

---

## Server Costs

| Server Type | RAM | CPU | Storage | Cost/Month | Use Case |
|-------------|-----|-----|---------|------------|----------|
| CX21 | 4GB | 2 vCPU | 40GB | ~€6 | Testing |
| CX31 | 8GB | 2 vCPU | 80GB | ~€13 | Production |
| CPX31 | 16GB | 4 vCPU | 160GB | ~€20 | High Load |

*Prices as of 2025*

---

## What Gets Deployed?

The deployment includes:
- 🐘 PostgreSQL database
- 🤖 AI Agent API (FastAPI)
- 🔄 Backend event generator
- 📊 Web dashboard
- 🧠 Ollama (for LLM mode)

All containerized with Docker Compose.

---

## Security Notes

After deployment, you should:

1. **Change database password** in `docker-compose.yml`
2. **Restrict firewall** to your IP only
3. **Setup SSL** with Let's Encrypt (see HETZNER_DEPLOYMENT.md)
4. **Enable backups** (see HETZNER_DEPLOYMENT.md)

---

## Full Documentation

For detailed information:
- **Complete Guide**: `HETZNER_DEPLOYMENT.md`
- **Application Docs**: `README.md`
- **Troubleshooting**: `TROUBLESHOOTING.md` (if exists)

---

## Support

**Quick Help:**
```bash
# View deployment logs
ssh root@YOUR_IP 'cd /opt/cyber-defense && docker-compose logs'

# Run health check
./health-check.sh YOUR_IP
```

**Need more help?**
See `HETZNER_DEPLOYMENT.md` for detailed troubleshooting.

---

## Summary

**Deploy:**
```bash
./deploy-to-hetzner.sh 65.21.123.45
```

**Access:**
- Dashboard: http://65.21.123.45:3000
- API: http://65.21.123.45:8000/docs

**Manage:**
```bash
ssh root@65.21.123.45
cd /opt/cyber-defense
docker-compose logs -f
```

**Done!** 🎉

---

*Deployment takes ~5 minutes total*
