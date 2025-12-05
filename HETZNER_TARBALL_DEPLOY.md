# Deploy to Hetzner Using Tar.gz (Password Authentication)

Quick deployment guide for Hetzner Cloud using tarball and password authentication.

## Prerequisites

- Hetzner Cloud Server created
- Root user with password
- Local machine with `sshpass` (will be installed automatically if missing)

## Quick Deploy (2 Steps)

### Step 1: Create Deployment Package

On your **local machine** (in the project directory):

```bash
./create-deployment-package.sh
```

This creates a tarball like: `cyber-defense-agent-20251202-143022.tar.gz`

### Step 2: Deploy to Hetzner

```bash
./deploy-tarball.sh
```

You'll be prompted for:
- Server IP address
- Root password

The script will:
1. ✅ Test connection
2. ✅ Upload package
3. ✅ Extract files
4. ✅ Install Docker (if needed)
5. ✅ Configure firewall
6. ✅ Start application

**Done!** Your services will be running in 2-3 minutes.

---

## Manual Deployment (If Automated Script Fails)

### 1. Create Package

```bash
./create-deployment-package.sh
```

### 2. Upload to Server

**Using SCP with password:**
```bash
# Install sshpass first
sudo apt-get install sshpass  # Ubuntu/Debian
brew install hudochenkov/sshpass/sshpass  # macOS

# Upload file
sshpass -p 'YOUR_PASSWORD' scp cyber-defense-agent-*.tar.gz root@YOUR_SERVER_IP:/root/
```

**Or use SFTP client:**
- FileZilla
- WinSCP (Windows)
- Cyberduck (macOS)

### 3. SSH into Server

```bash
ssh root@YOUR_SERVER_IP
# Enter password when prompted
```

### 4. Extract Package

```bash
cd /root
tar -xzf cyber-defense-agent-*.tar.gz
cd workspace
```

### 5. Install Docker

```bash
# Update system
apt-get update

# Install prerequisites
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
systemctl start docker
systemctl enable docker

# Verify installation
docker --version
docker-compose --version
```

### 6. Configure Firewall

```bash
# Install ufw
apt-get install -y ufw

# Configure firewall
ufw --force enable
ufw allow 22/tcp      # SSH
ufw allow 8000/tcp    # Agent API
ufw allow 3000/tcp    # Dashboard
ufw allow 5432/tcp    # PostgreSQL (optional)
ufw allow 11434/tcp   # Ollama (optional)

# Check status
ufw status
```

### 7. Start Application

```bash
cd /root/workspace

# Make scripts executable
chmod +x *.sh

# Start services
docker-compose up -d

# Watch model download (1-2 minutes)
docker logs -f ollama-init
# Press Ctrl+C when you see "Qwen model ready!"
```

### 8. Verify Deployment

```bash
# Check all containers are running
docker ps

# Should see 5 containers:
# - cyber-events-db
# - ollama-qwen
# - cyber-agent
# - cyber-backend
# - cyber-dashboard

# Test agent health
curl http://localhost:8000/health | jq

# Test dashboard
curl http://localhost:3000/health
```

---

## Access Your Services

Once deployed, access via:

| Service | URL | Description |
|---------|-----|-------------|
| **Dashboard** | `http://YOUR_SERVER_IP:3000` | Web interface |
| **Agent API** | `http://YOUR_SERVER_IP:8000` | REST API |
| **API Docs** | `http://YOUR_SERVER_IP:8000/docs` | Swagger UI |

Replace `YOUR_SERVER_IP` with your actual Hetzner server IP.

---

## Quick Commands

### Monitor Logs

```bash
# All logs
docker-compose logs -f

# Specific service
docker logs -f cyber-agent
docker logs -f cyber-backend
docker logs -f cyber-dashboard
docker logs -f ollama-qwen
```

### Check Status

```bash
docker ps
docker-compose ps
```

### Restart Services

```bash
docker-compose restart
docker-compose restart agent  # Restart specific service
```

### Stop Everything

```bash
docker-compose down
```

### Clean Restart

```bash
docker-compose down -v  # Remove volumes
docker-compose up -d
```

---

## Troubleshooting

### Problem: Cannot connect to server

**Solution:**
```bash
# Test connection
ping YOUR_SERVER_IP

# Check SSH port
nc -zv YOUR_SERVER_IP 22

# Try with verbose SSH
ssh -v root@YOUR_SERVER_IP
```

### Problem: Permission denied during upload

**Solution:**
```bash
# Make sure you're using root user
# Or create a dedicated user:
ssh root@YOUR_SERVER_IP
adduser cyberdefense
usermod -aG sudo cyberdefense
```

### Problem: Docker installation fails

**Solution:**
```bash
# Try alternative method
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Or install manually following official docs:
# https://docs.docker.com/engine/install/ubuntu/
```

### Problem: Services not accessible from outside

**Solution:**
```bash
# Check firewall
ufw status

# Check if services are running
docker ps

# Check if ports are listening
netstat -tulpn | grep -E '3000|8000'

# Make sure Docker containers use correct ports
docker-compose ps
```

### Problem: Out of disk space

**Solution:**
```bash
# Check disk usage
df -h

# Clean Docker
docker system prune -a

# Remove old images
docker images
docker rmi IMAGE_ID
```

---

## Server Recommendations

### Minimum Requirements
- **CPX21**: 3 vCPUs, 8GB RAM, 80GB SSD (~€15/month)
- Suitable for testing

### Recommended
- **CPX31**: 4 vCPUs, 16GB RAM, 160GB SSD (~€30/month)
- Good for production use

### High Performance
- **CPX41**: 8 vCPUs, 32GB RAM, 240GB SSD (~€60/month)
- Best for high load

---

## Security Recommendations

### 1. Change Default Passwords

```bash
# Create .env file
cd /root/workspace
cp .env.example .env

# Edit and set strong passwords
nano .env
```

### 2. Restrict Database Access

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Comment out database port mapping:
# ports:
#   - "5432:5432"
```

### 3. Enable HTTPS (Optional)

```bash
# Install Nginx and Certbot
apt-get install -y nginx certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d your-domain.com
```

### 4. Create Non-Root User (Recommended)

```bash
# Create user
adduser cyberdefense
usermod -aG docker cyberdefense
usermod -aG sudo cyberdefense

# Move application
mv /root/workspace /home/cyberdefense/
chown -R cyberdefense:cyberdefense /home/cyberdefense/workspace

# Switch to new user
su - cyberdefense
```

---

## Backup and Maintenance

### Backup Database

```bash
# Backup all data
docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

# Download backup to local machine
scp root@YOUR_SERVER_IP:/root/backup.sql ./
```

### Update Application

```bash
# On local machine: create new package
./create-deployment-package.sh

# Deploy new version
./deploy-tarball.sh YOUR_SERVER_IP

# Or manually:
sshpass -p 'PASSWORD' scp cyber-defense-agent-*.tar.gz root@YOUR_SERVER_IP:/root/
ssh root@YOUR_SERVER_IP
cd /root
tar -xzf cyber-defense-agent-*.tar.gz
cd workspace
docker-compose down
docker-compose up -d
```

### Monitor Resources

```bash
# Check memory/CPU
docker stats

# Check disk
df -h

# Check system resources
htop
```

---

## Summary

**Easiest deployment:**
```bash
# On local machine
./create-deployment-package.sh
./deploy-tarball.sh
```

**Access services:**
- Dashboard: `http://YOUR_SERVER_IP:3000`
- API: `http://YOUR_SERVER_IP:8000`

**That's it!** 🚀
