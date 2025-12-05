# Deploy to Hetzner with Root/Password

Simple deployment guide for Hetzner Cloud using root user and password authentication.

## Prerequisites

- Hetzner Cloud account
- Server created with Ubuntu 22.04/24.04
- Root password set
- FileZilla, WinSCP, or scp command available

## Step 1: Create Deployment Package

On your local machine:

```bash
./create-deployment-package.sh
```

This creates a `cyber-defense-YYYYMMDD-HHMMSS.tar.gz` file containing everything needed.

## Step 2: Create Hetzner Server

1. Login to https://console.hetzner.cloud/
2. Create new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 or better (4GB+ RAM recommended)
   - **Location**: Closest to you
   - **Name**: cyber-defense
3. **Set root password** (no SSH key needed)
4. Click "Create & Buy"
5. **Copy the server IP address** (e.g., 65.21.123.45)

## Step 3: Upload Package

### Option A: Using scp (Linux/Mac/WSL)

```bash
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

Enter root password when prompted.

### Option B: Using FileZilla (Windows/Mac/Linux)

1. Open FileZilla
2. Quick Connect:
   - **Host**: YOUR_SERVER_IP
   - **Username**: root
   - **Password**: [your root password]
   - **Port**: 22
3. Click "Quickconnect"
4. Drag and drop the .tar.gz file to /root/

### Option C: Using WinSCP (Windows)

1. Open WinSCP
2. New Session:
   - **Host name**: YOUR_SERVER_IP
   - **User name**: root
   - **Password**: [your root password]
3. Click "Login"
4. Upload the .tar.gz file

## Step 4: Deploy on Server

### Connect via SSH

**Linux/Mac/WSL:**
```bash
ssh root@YOUR_SERVER_IP
```

**Windows (if no WSL):**
Use PuTTY:
1. Host: YOUR_SERVER_IP
2. Port: 22
3. Connection Type: SSH
4. Click "Open"
5. Login as: root
6. Password: [your password]

### Run Deployment

```bash
# Extract package
tar -xzf cyber-defense-*.tar.gz

# Enter directory
cd cyber-defense

# Make script executable (if needed)
chmod +x deploy-on-hetzner.sh

# Run deployment
./deploy-on-hetzner.sh
```

The script will automatically:
- ✅ Update system packages
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall (ports 22, 80, 443, 3000, 8000)
- ✅ Start all services
- ✅ Download Qwen model (~400MB)

**Wait 2-3 minutes** for everything to initialize.

## Step 5: Access Your Application

Replace `YOUR_SERVER_IP` with your actual server IP:

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Verify Deployment

```bash
# Check all containers are running
docker-compose ps

# Should show:
# - cyber-events-db (PostgreSQL)
# - ollama-qwen (Ollama)
# - cyber-agent (API)
# - cyber-backend (Event generator)
# - cyber-dashboard (Web UI)

# Check Qwen model is loaded
docker exec ollama-qwen ollama list

# Test agent health
curl http://localhost:8000/health
```

## Common Commands

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker logs -f cyber-agent

# Restart everything
docker-compose restart

# Stop everything
docker-compose down

# Start everything
docker-compose up -d

# Check status
docker-compose ps
```

## Troubleshooting

### Can't connect to server
```bash
# Check firewall allows SSH
ufw status
ufw allow 22/tcp
```

### Services not running
```bash
# Check Docker is running
systemctl status docker

# Start Docker if needed
systemctl start docker

# Check logs
docker-compose logs
```

### Can't access dashboard from browser
```bash
# Check firewall
ufw status

# Allow dashboard port
ufw allow 3000/tcp

# Check service is running
docker ps | grep dashboard
```

### Model not loading
```bash
# Check Ollama logs
docker logs ollama-init

# Pull model manually
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Verify it loaded
docker exec ollama-qwen ollama list
```

## Update Deployment

To update to a new version:

```bash
# On local machine, create new package
./create-deployment-package.sh

# Upload new package to server
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/

# On server
ssh root@YOUR_SERVER_IP
cd cyber-defense
docker-compose down
cd ..
tar -xzf cyber-defense-NEW.tar.gz
cd cyber-defense
./deploy-on-hetzner.sh
```

## Security Recommendations

After initial deployment:

1. **Change database password**:
```bash
nano docker-compose.yml
# Change POSTGRES_PASSWORD
docker-compose down
docker-compose up -d
```

2. **Restrict firewall** (optional):
```bash
# Only allow your IP to access services
ufw delete allow 3000/tcp
ufw delete allow 8000/tcp
ufw allow from YOUR_HOME_IP to any port 3000
ufw allow from YOUR_HOME_IP to any port 8000
```

3. **Set up SSL/TLS** for production use (optional)

4. **Enable automatic updates**:
```bash
apt-get install unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades
```

## Cost Estimation

**Hetzner Server Pricing:**
- **CPX11** (2 vCPU, 2GB RAM): €4.51/month - Too small
- **CPX21** (3 vCPU, 4GB RAM): €8.90/month - Minimum
- **CPX31** (4 vCPU, 8GB RAM): €18.40/month - Recommended ⭐
- **CPX41** (8 vCPU, 16GB RAM): €35.30/month - Best performance

Choose based on your needs and budget.

## Complete Example

```bash
# 1. LOCAL: Create package
./create-deployment-package.sh
# Output: cyber-defense-20251202-143022.tar.gz

# 2. LOCAL: Upload to server
scp cyber-defense-20251202-143022.tar.gz root@65.21.123.45:/root/

# 3. SERVER: Deploy
ssh root@65.21.123.45
tar -xzf cyber-defense-20251202-143022.tar.gz
cd cyber-defense
./deploy-on-hetzner.sh

# 4. Wait 2-3 minutes, then access:
# http://65.21.123.45:3000
```

## Need Help?

- Check logs: `docker-compose logs -f`
- Restart: `docker-compose restart`
- Full reset: `docker-compose down -v && docker-compose up -d`

See README.md in the deployment package for more details.
