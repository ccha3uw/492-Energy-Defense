# Simple Hetzner Deployment with tar.gz

## Overview

This is the easiest way to deploy to Hetzner using root user with password authentication.

## Prerequisites

- Hetzner server created (Ubuntu 20.04/22.04/24.04)
- Root password
- Server IP address
- Minimum: 8GB RAM, 20GB disk

## Step-by-Step Deployment

### Step 1: Create Deployment Package

On your **local machine**, in the project directory:

```bash
./create-deployment-package.sh
```

This creates: `cyber-defense-deployment.tar.gz` (~10-20MB)

---

### Step 2: Upload to Hetzner

Choose your preferred method:

#### Option A: Using SCP (Command Line)

```bash
scp cyber-defense-deployment.tar.gz root@YOUR_SERVER_IP:/root/
# Enter password when prompted
```

#### Option B: Using FileZilla (GUI)

1. Open FileZilla
2. Enter connection details:
   - **Host**: YOUR_SERVER_IP
   - **Username**: root
   - **Password**: your_password
   - **Port**: 22
3. Connect
4. Navigate to `/root/` on remote side
5. Drag and drop `cyber-defense-deployment.tar.gz`

#### Option C: Using WinSCP (Windows GUI)

1. Open WinSCP
2. New Session:
   - **File protocol**: SCP
   - **Host name**: YOUR_SERVER_IP
   - **User name**: root
   - **Password**: your_password
3. Login
4. Upload file to `/root/`

---

### Step 3: SSH into Server

```bash
ssh root@YOUR_SERVER_IP
# Enter password
```

Or use PuTTY on Windows with:
- Host: YOUR_SERVER_IP
- Port: 22
- Username: root
- Password: your_password

---

### Step 4: Extract and Setup

On the **Hetzner server**:

```bash
# Navigate to root directory
cd /root

# Extract the package
tar -xzf cyber-defense-deployment.tar.gz

# Enter the directory
cd cyber-defense

# Run the automated setup
./setup-hetzner.sh
```

The setup script will:
- ✅ Update system packages
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall (ports 22, 8000, 3000)
- ✅ Start all services
- ✅ Download Qwen model (~400MB, 1-2 minutes)

**Total time: 5-10 minutes**

---

### Step 5: Verify Installation

Wait 2-3 minutes after setup completes, then test:

```bash
# Check services are running
docker-compose ps

# Should show 5 containers running:
# - cyber-events-db
# - ollama-qwen
# - cyber-agent
# - cyber-backend
# - cyber-dashboard
```

Check the model loaded:
```bash
docker exec ollama-qwen ollama list
# Should show: qwen2.5:0.5b
```

Test the agent:
```bash
curl http://localhost:8000/health | jq
```

---

### Step 6: Access from Browser

Get your server IP:
```bash
curl ifconfig.me
```

Then open in your browser:
- **Dashboard**: `http://YOUR_SERVER_IP:3000`
- **API Docs**: `http://YOUR_SERVER_IP:8000/docs`

---

## Useful Commands

### Check Status
```bash
docker-compose ps
```

### View Logs
```bash
# All logs
docker-compose logs -f

# Specific service
docker-compose logs -f agent
docker-compose logs -f backend
docker-compose logs -f dashboard
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

### Check Resource Usage
```bash
docker stats
```

---

## Configuration Changes

### Switch to Rule-Based Mode (Recommended)

Edit `/root/cyber-defense/docker-compose.yml`:

```yaml
agent:
  environment:
    - USE_LLM=false  # Disable LLM, use rule-based
```

Restart:
```bash
docker-compose restart agent
```

### Use Larger Qwen Model

Edit `/root/cyber-defense/docker-compose.yml`:

```yaml
agent:
  environment:
    - OLLAMA_MODEL=qwen2.5:1.5b  # or qwen2.5:3b
```

Pull new model and restart:
```bash
docker exec ollama-qwen ollama pull qwen2.5:1.5b
docker-compose restart agent
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
systemctl status docker

# Check logs for errors
docker-compose logs

# Restart everything
docker-compose down
docker-compose up -d
```

### Can't Access from Browser

```bash
# Check firewall
ufw status

# Allow ports if needed
ufw allow 8000/tcp
ufw allow 3000/tcp
```

### Out of Memory

```bash
# Check memory usage
free -h

# Check Docker stats
docker stats

# If using Qwen model and low on RAM, switch to rule-based:
# Edit docker-compose.yml: USE_LLM=false
docker-compose restart agent
```

### Model Not Loading

```bash
# Check Ollama logs
docker logs ollama-init
docker logs ollama-qwen

# Manually pull model
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Verify it's there
docker exec ollama-qwen ollama list
```

---

## Security Notes

### After Installation, Secure Your Server

1. **Change Root Password**
```bash
passwd
```

2. **Create Non-Root User** (Optional but recommended)
```bash
adduser cyber
usermod -aG sudo cyber
usermod -aG docker cyber
```

3. **Configure SSH Key Authentication** (Optional)
```bash
# On local machine, generate key if you don't have one
ssh-keygen

# Copy to server
ssh-copy-id root@YOUR_SERVER_IP
```

4. **Disable Password Authentication** (Only after SSH key works!)
```bash
nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
systemctl restart sshd
```

---

## Updating the Application

### Method 1: Pull Latest Images

```bash
cd /root/cyber-defense
docker-compose down
docker-compose pull
docker-compose up -d
```

### Method 2: Upload New Package

1. Create new package on local machine
2. Upload to server
3. Extract and replace:
```bash
cd /root
tar -xzf cyber-defense-deployment.tar.gz
cd cyber-defense
docker-compose down
docker-compose up -d
```

---

## Complete Example Session

Here's what the entire process looks like:

```bash
# === ON LOCAL MACHINE ===
./create-deployment-package.sh
scp cyber-defense-deployment.tar.gz root@65.21.123.45:/root/

# === ON HETZNER SERVER ===
ssh root@65.21.123.45
cd /root
tar -xzf cyber-defense-deployment.tar.gz
cd cyber-defense
./setup-hetzner.sh

# Wait 5-10 minutes...

# === VERIFY ===
docker-compose ps
curl http://localhost:8000/health | jq

# === OPEN IN BROWSER ===
# http://65.21.123.45:3000
```

---

## Package Contents

The deployment package includes:

```
cyber-defense/
├── agent/                    # AI agent code
├── backend/                  # Backend code
├── dashboard/                # Dashboard code
├── docker-compose.yml        # Docker configuration
├── .env                      # Environment variables
├── setup-hetzner.sh          # Automated setup script
├── DEPLOY_README.md          # Deployment instructions
└── *.sh                      # Helper scripts
```

---

## Cost Estimate (Hetzner)

Recommended server: **CPX31**
- 4 vCPU, 16 GB RAM, 160 GB SSD
- Cost: ~€30/month
- Perfect for this application with LLM

Budget option: **CPX21** 
- 3 vCPU, 8 GB RAM, 80 GB SSD
- Cost: ~€15/month
- Works, but use rule-based mode (USE_LLM=false)

---

## Support

If you encounter issues:

1. **Check logs**: `docker-compose logs -f`
2. **Check status**: `docker-compose ps`
3. **Check resources**: `htop` or `docker stats`
4. **Restart**: `docker-compose restart`
5. **Fresh start**: `docker-compose down && docker-compose up -d`

For the Qwen scoring issue, run:
```bash
./apply-fix.sh
```

---

**That's it! You now have a fully functional cybersecurity agent running on Hetzner.** 🚀
