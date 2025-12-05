# Simple Hetzner Deployment with tar.gz

## Quick Deployment (5 Minutes)

This guide is for deploying with **root user + password** authentication.

---

## Step 1: Create Deployment Package (Local Machine)

On your local machine where the project is:

```bash
./create-deployment-package.sh
```

This creates: `cyber-agent-deployment.tar.gz` (~50MB)

---

## Step 2: Upload to Hetzner Server

### Using SCP (with password)

```bash
scp cyber-agent-deployment.tar.gz root@YOUR_SERVER_IP:~/
```

You'll be prompted for the root password.

**Example:**
```bash
scp cyber-agent-deployment.tar.gz root@65.21.123.45:~/
# Enter password when prompted
```

### Alternative: Using WinSCP (Windows)

If on Windows:
1. Download WinSCP: https://winscp.net/
2. Connect to your server:
   - Host: `YOUR_SERVER_IP`
   - Username: `root`
   - Password: `your_password`
3. Drag and drop `cyber-agent-deployment.tar.gz` to `/root/`

---

## Step 3: SSH into Server

```bash
ssh root@YOUR_SERVER_IP
# Enter password when prompted
```

---

## Step 4: Extract and Deploy

On the server:

```bash
# Extract the package
tar -xzf cyber-agent-deployment.tar.gz

# Go into the directory
cd cyber-agent-deploy

# Run deployment script
./deploy.sh
```

The deployment script will:
- ✅ Install Docker (if not present)
- ✅ Install Docker Compose
- ✅ Start all services
- ✅ Download Qwen model (~400MB, 1-2 min)
- ✅ Initialize database

---

## Step 5: Verify Deployment

### Check Services Running

```bash
docker-compose ps
```

Should show 5 containers:
- ✅ cyber-events-db
- ✅ ollama-qwen
- ✅ cyber-agent
- ✅ cyber-backend
- ✅ cyber-dashboard

### Check Model Loaded

```bash
./check-qwen-model.sh
```

### Test Agent

```bash
curl http://localhost:8000/health | jq
```

---

## Step 6: Open Firewall (IMPORTANT!)

Allow external access to the ports:

```bash
# Install UFW if not present
apt-get install -y ufw

# Allow SSH (important!)
ufw allow 22/tcp

# Allow application ports
ufw allow 3000/tcp  # Dashboard
ufw allow 8000/tcp  # Agent API

# Enable firewall
ufw --force enable

# Check status
ufw status
```

---

## Step 7: Access From Your Computer

Open in your browser:

- **Dashboard**: `http://YOUR_SERVER_IP:3000`
- **API Docs**: `http://YOUR_SERVER_IP:8000/docs`
- **Health Check**: `http://YOUR_SERVER_IP:8000/health`

Replace `YOUR_SERVER_IP` with your actual server IP (e.g., 65.21.123.45)

---

## Complete Example

```bash
# === ON YOUR LOCAL MACHINE ===

# 1. Create package
./create-deployment-package.sh

# 2. Upload to server (enter password when prompted)
scp cyber-agent-deployment.tar.gz root@65.21.123.45:~/

# 3. SSH to server (enter password when prompted)
ssh root@65.21.123.45

# === NOW ON THE SERVER ===

# 4. Extract
tar -xzf cyber-agent-deployment.tar.gz
cd cyber-agent-deploy

# 5. Deploy (installs everything)
./deploy.sh

# 6. Wait 1-2 minutes, then verify
docker-compose ps
./check-qwen-model.sh

# 7. Open firewall
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw --force enable

# 8. Test from local machine browser
# Open: http://65.21.123.45:3000
```

---

## Package Contents

The deployment package includes:

```
cyber-agent-deploy/
├── agent/              # AI agent code
├── backend/            # Backend service
├── dashboard/          # Web dashboard
├── docker-compose.yml  # Service orchestration
├── .env                # Configuration
├── deploy.sh           # Automated deployment script
├── start.sh            # Start script
├── check-qwen-model.sh # Verification script
├── test-llm-mode.sh    # Testing script
└── README.md           # Documentation
```

---

## Useful Commands on Server

### View Logs
```bash
docker-compose logs -f
```

### Stop Services
```bash
docker-compose down
```

### Restart Services
```bash
docker-compose restart
```

### Update Application
```bash
# Upload new package
# scp cyber-agent-deployment.tar.gz root@SERVER_IP:~/

# On server:
cd ~
docker-compose down
rm -rf cyber-agent-deploy
tar -xzf cyber-agent-deployment.tar.gz
cd cyber-agent-deploy
docker-compose up -d
```

### Check Resource Usage
```bash
docker stats --no-stream
```

### View Agent Logs
```bash
docker logs cyber-agent --tail 50
```

---

## Troubleshooting

### Can't connect to server?

**Check SSH port is open:**
```bash
telnet YOUR_SERVER_IP 22
```

**Try with verbose SSH:**
```bash
ssh -v root@YOUR_SERVER_IP
```

### Services not starting?

**Check Docker is running:**
```bash
systemctl status docker
```

**Check logs:**
```bash
cd cyber-agent-deploy
docker-compose logs
```

**Restart everything:**
```bash
docker-compose down
docker-compose up -d
```

### Can't access dashboard?

**Check firewall:**
```bash
ufw status
```

**Make sure ports are open:**
```bash
ufw allow 3000/tcp
ufw allow 8000/tcp
```

**Check service is running:**
```bash
docker-compose ps dashboard
```

### Model not loading?

**Pull manually:**
```bash
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

**Check Ollama logs:**
```bash
docker logs ollama-qwen
```

---

## Server Requirements

### Minimum
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB
- **OS**: Ubuntu 20.04 or 22.04

### Recommended
- **CPU**: 4 cores
- **RAM**: 8GB
- **Storage**: 40GB
- **OS**: Ubuntu 22.04 LTS

---

## Security Notes

### For Production Use:

1. **Change default passwords** in `.env` file
2. **Use SSH keys** instead of password
3. **Setup HTTPS** with Let's Encrypt
4. **Restrict firewall** to specific IPs
5. **Setup automatic backups**

### Quick Security Improvements:

```bash
# Change PostgreSQL password
nano .env
# Edit: POSTGRES_PASSWORD=your_strong_password

# Restart to apply
docker-compose down
docker-compose up -d

# Restrict dashboard to specific IP
ufw delete allow 3000/tcp
ufw allow from YOUR_IP_ADDRESS to any port 3000 proto tcp
```

---

## Cost Estimate

**Hetzner Cloud Pricing (as of 2025):**

| Server | CPU | RAM | Storage | Price/Month |
|--------|-----|-----|---------|-------------|
| CPX11 | 2 vCPU | 2GB | 40GB | €4.51 |
| CPX21 | 3 vCPU | 4GB | 80GB | €9.52 |
| CPX31 | 4 vCPU | 8GB | 160GB | €18.54 |

**Recommended: CPX21 (4GB RAM)** - €9.52/month

---

## Next Steps

1. ✅ Deploy to Hetzner
2. ✅ Verify services are running
3. ✅ Open dashboard in browser
4. 📚 Read README.md for usage instructions
5. 🔧 Run `./apply-fix.sh` if needed to fix scoring
6. 🧪 Run `./test-llm-mode.sh` to test functionality

---

## Support

If you encounter issues:
1. Check logs: `docker-compose logs`
2. Verify Docker: `docker ps`
3. Check firewall: `ufw status`
4. Test locally: `curl http://localhost:8000/health`

---

**That's it! You now have a working cybersecurity agent on Hetzner Cloud.** 🚀
