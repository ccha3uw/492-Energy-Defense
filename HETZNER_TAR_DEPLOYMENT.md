# Hetzner Deployment Guide (tar.gz Method)

## Easy Deployment with Root User & Password

This guide shows you how to deploy to Hetzner using a simple tar.gz file upload with root user authentication.

---

## Step 1: Create Deployment Package

On your **local machine** (where the project is):

```bash
./create-deployment-package.sh
```

This creates a file like `cyber-defense-20251202-143045.tar.gz`

---

## Step 2: Upload to Hetzner

### Option A: Using SCP (with password)

```bash
# Replace YOUR_SERVER_IP with your Hetzner server IP
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

When prompted, enter your root password.

### Option B: Using SFTP

```bash
sftp root@YOUR_SERVER_IP
# Enter password when prompted

# Upload file
put cyber-defense-*.tar.gz /root/
exit
```

### Option C: Using Hetzner Web Console

1. Log into Hetzner Cloud Console
2. Click on your server
3. Click "Console" button (browser terminal)
4. Use `wget` or `curl` to download from a URL:

```bash
# If you host it somewhere
cd /root
wget https://your-url.com/cyber-defense-*.tar.gz

# Or use a file sharing service temporarily
```

---

## Step 3: Connect to Server

```bash
ssh root@YOUR_SERVER_IP
```

Enter your root password when prompted.

---

## Step 4: Extract Package

```bash
cd /root

# List files to verify upload
ls -lh cyber-defense-*.tar.gz

# Extract
tar -xzf cyber-defense-*.tar.gz

# Rename for convenience
mv cyber-defense-deploy cyber-defense

# Navigate to directory
cd cyber-defense

# List contents
ls -la
```

---

## Step 5: Run Setup Script

This installs Docker, Docker Compose, and sets up firewall:

```bash
chmod +x hetzner-setup.sh
./hetzner-setup.sh
```

This will:
- ✅ Update system packages
- ✅ Install Docker
- ✅ Install Docker Compose
- ✅ Install utilities (curl, jq, etc.)
- ✅ Configure firewall (ports 22, 80, 443, 3000, 8000)

Takes ~3-5 minutes.

---

## Step 6: Start the System

```bash
chmod +x start-system.sh
./start-system.sh
```

This starts all Docker containers.

---

## Step 7: Monitor Model Download

The Qwen model will download automatically:

```bash
docker logs -f ollama-init
```

Wait for:
```
Qwen model ready!
```

Press `Ctrl+C` when done (takes 1-2 minutes).

---

## Step 8: Access Your System

Open in your browser:

- **Dashboard**: `http://YOUR_SERVER_IP:3000`
- **Agent API**: `http://YOUR_SERVER_IP:8000`
- **API Docs**: `http://YOUR_SERVER_IP:8000/docs`

---

## Verification

### Check all containers are running:

```bash
docker ps
```

You should see:
- `cyber-events-db`
- `ollama-qwen`
- `cyber-agent`
- `cyber-backend`
- `cyber-dashboard`

### Test the agent:

```bash
curl http://localhost:8000/health | jq
```

Should return:
```json
{
  "status": "healthy",
  "service": "492-Energy-Defense Cyber Event Triage Agent",
  "model": "qwen2.5:0.5b"
}
```

### Check if Qwen model is loaded:

```bash
docker exec ollama-qwen ollama list
```

Should show `qwen2.5:0.5b` in the list.

---

## Common Tasks

### View Logs

```bash
# All logs
docker-compose logs -f

# Specific service
docker logs cyber-agent
docker logs cyber-backend
docker logs ollama-qwen
```

### Restart Services

```bash
# All services
docker-compose restart

# Specific service
docker-compose restart agent
```

### Stop System

```bash
docker-compose down
```

### Start Again

```bash
docker-compose up -d
```

### Update Configuration

```bash
# Edit environment variables
nano docker-compose.yml

# Or edit .env file
nano .env

# Restart after changes
docker-compose restart
```

---

## Recommended: Switch to Rule-Based Mode

The Qwen 0.5B model is small and may have accuracy issues. For production, use rule-based mode:

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Find this line:
#   - USE_LLM=true
# Change to:
#   - USE_LLM=false

# Save (Ctrl+O, Enter, Ctrl+X)

# Restart agent
docker-compose restart agent
```

This gives you **100% accurate** scoring without LLM overhead.

---

## Upgrade Qwen Model (If using LLM)

For better LLM accuracy:

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change:
#   - OLLAMA_MODEL=qwen2.5:0.5b
# To:
#   - OLLAMA_MODEL=qwen2.5:1.5b

# Save and exit

# Pull new model
docker exec ollama-qwen ollama pull qwen2.5:1.5b

# Restart services
docker-compose restart ollama agent
```

---

## Troubleshooting

### Problem: Cannot connect to server

**Check firewall:**
```bash
ufw status
ufw allow 3000/tcp
ufw allow 8000/tcp
```

### Problem: Containers not starting

**Check logs:**
```bash
docker-compose logs
```

**Check system resources:**
```bash
free -h  # Check RAM
df -h    # Check disk space
```

### Problem: Model not downloading

**Manually pull:**
```bash
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

**Check Ollama logs:**
```bash
docker logs ollama-qwen
```

### Problem: Port already in use

**Check what's using the port:**
```bash
netstat -tulpn | grep :8000
netstat -tulpn | grep :3000
```

**Kill the process or change ports in docker-compose.yml**

---

## Security Recommendations

### 1. Change Database Password

Edit `docker-compose.yml`:
```yaml
db:
  environment:
    POSTGRES_PASSWORD: YOUR_SECURE_PASSWORD
```

Also update in agent and backend sections:
```yaml
DATABASE_URL=postgresql://postgres:YOUR_SECURE_PASSWORD@db:5432/cyber_events
```

### 2. Use SSH Keys (Optional)

```bash
# On your local machine
ssh-keygen -t ed25519 -C "your@email.com"

# Copy to server
ssh-copy-id root@YOUR_SERVER_IP
```

### 3. Setup SSL/TLS (Optional)

Use a reverse proxy like Nginx or Caddy with Let's Encrypt.

---

## Server Requirements

### Minimum (for testing):
- 2 vCPU
- 4 GB RAM
- 20 GB SSD
- Cost: ~€5-10/month

### Recommended (for production):
- 4 vCPU
- 8 GB RAM
- 40 GB SSD
- Cost: ~€15-30/month

### High Performance:
- 8 vCPU
- 16 GB RAM
- 80 GB SSD
- Cost: ~€30-60/month

---

## Complete Command Reference

```bash
# Package creation (local)
./create-deployment-package.sh

# Upload (local)
scp cyber-defense-*.tar.gz root@SERVER_IP:/root/

# Server setup
ssh root@SERVER_IP
cd /root
tar -xzf cyber-defense-*.tar.gz
mv cyber-defense-deploy cyber-defense
cd cyber-defense
./hetzner-setup.sh
./start-system.sh

# Monitor
docker logs -f ollama-init
docker ps
docker-compose logs -f

# Access
# http://SERVER_IP:3000  (Dashboard)
# http://SERVER_IP:8000  (API)
```

---

## Quick Reference Card

Save this on your server as `/root/commands.txt`:

```bash
# Start
cd /root/cyber-defense && docker-compose up -d

# Stop
cd /root/cyber-defense && docker-compose down

# Restart
cd /root/cyber-defense && docker-compose restart

# Logs
docker logs cyber-agent
docker logs cyber-backend
docker logs ollama-qwen

# Status
docker ps

# Model check
docker exec ollama-qwen ollama list

# Test agent
curl http://localhost:8000/health | jq

# Resource usage
docker stats --no-stream
```

---

## Next Steps

1. ✅ Access dashboard at `http://YOUR_SERVER_IP:3000`
2. ✅ Test API at `http://YOUR_SERVER_IP:8000/docs`
3. ✅ Review logs with `docker-compose logs -f`
4. ✅ Consider switching to rule-based mode for accuracy
5. ✅ Set up monitoring and backups

---

**Deployment complete!** 🚀

For questions or issues, check the logs and troubleshooting section above.
