# Hetzner Deployment with tar.gz Package

## Quick Deployment Guide for Root User

This guide shows how to deploy the cybersecurity agent to Hetzner using a tar.gz package with root user and password authentication.

---

## Step 1: Create Deployment Package

On your **local machine**, create the deployment package:

```bash
./create-deployment-package.sh
```

This creates a file like: `cyber-defense-20251202_143022.tar.gz`

**What's included:**
- All application code (agent, backend, dashboard)
- Docker configuration files
- Deployment script
- Documentation

**What's excluded:**
- .git directory
- Python cache files
- Local environment files
- Unnecessary documentation

---

## Step 2: Upload to Hetzner Server

### Option A: Using SCP (with password)

```bash
# Replace with your server IP
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
# Enter password when prompted
```

### Option B: Using SFTP

```bash
sftp root@YOUR_SERVER_IP
# Enter password
put cyber-defense-*.tar.gz
bye
```

### Option C: Using Web-Based SFTP Client

Use tools like:
- FileZilla
- WinSCP (Windows)
- Cyberduck (Mac)

Connect to: `YOUR_SERVER_IP:22`
User: `root`
Upload the tar.gz file to `/root/`

---

## Step 3: SSH to Server

```bash
ssh root@YOUR_SERVER_IP
# Enter password when prompted
```

---

## Step 4: Extract and Deploy

Once logged in to your Hetzner server:

```bash
# Go to root directory
cd /root

# Extract the package
tar -xzf cyber-defense-*.tar.gz

# Enter the directory
cd cyber-defense-deploy

# Run deployment script
./deploy.sh
```

The deployment script will:
1. ✅ Install Docker (if not present)
2. ✅ Install Docker Compose (if not present)
3. ✅ Start all services
4. ✅ Download Qwen model (~400MB, 1-2 minutes)
5. ✅ Initialize database
6. ✅ Start event generation

**Watch for:** `Qwen model ready!` - then press Ctrl+C

---

## Step 5: Verify Deployment

### Check running containers

```bash
docker-compose ps
```

Should show 5 containers running:
- cyber-events-db
- ollama-qwen
- cyber-agent
- cyber-backend
- cyber-dashboard

### Check agent health

```bash
curl http://localhost:8000/health
```

### Access dashboard

Open in browser: **http://YOUR_SERVER_IP:3000**

---

## Step 6: Configure Firewall

Open necessary ports:

```bash
# Allow SSH
ufw allow 22/tcp

# Allow Dashboard
ufw allow 3000/tcp

# Optional: Allow API access
ufw allow 8000/tcp

# Enable firewall
ufw enable
```

**Warning:** Make sure SSH (22) is allowed before enabling firewall!

---

## Complete Example

Here's a complete deployment example:

```bash
# On local machine:
./create-deployment-package.sh
# Creates: cyber-defense-20251202_143022.tar.gz

# Upload to server
scp cyber-defense-20251202_143022.tar.gz root@65.108.123.45:/root/
# Enter password: ********

# Connect to server
ssh root@65.108.123.45
# Enter password: ********

# On the server:
cd /root
tar -xzf cyber-defense-20251202_143022.tar.gz
cd cyber-defense-deploy
./deploy.sh

# Wait for "Qwen model ready!" then press Ctrl+C

# Configure firewall
ufw allow 22/tcp
ufw allow 3000/tcp
ufw enable

# Access dashboard
# Open: http://65.108.123.45:3000
```

---

## Useful Commands on Server

### View all logs
```bash
cd /root/cyber-defense-deploy
docker-compose logs -f
```

### View specific service logs
```bash
docker-compose logs -f cyber-agent      # Agent
docker-compose logs -f cyber-backend    # Backend
docker-compose logs -f cyber-dashboard  # Dashboard
docker-compose logs -f ollama-qwen      # Ollama
```

### Check service status
```bash
docker-compose ps
```

### Restart services
```bash
docker-compose restart
```

### Stop services
```bash
docker-compose down
```

### Update code
```bash
# Upload new package
# Extract to new directory
# Stop old deployment
cd /root/cyber-defense-deploy
docker-compose down

# Start new deployment
cd /root/cyber-defense-deploy-new
docker-compose up -d
```

---

## Resource Usage

Expected resource consumption:

| Service | RAM | CPU |
|---------|-----|-----|
| Database | ~200MB | Low |
| Ollama (Qwen 0.5B) | ~2-3GB | Medium |
| Agent | ~300MB | Low |
| Backend | ~200MB | Low |
| Dashboard | ~100MB | Low |
| **Total** | **~3-4GB** | **Low-Medium** |

---

## Troubleshooting

### Problem: Cannot connect to server

```bash
# Test connection
ping YOUR_SERVER_IP

# Test SSH
ssh -v root@YOUR_SERVER_IP
```

### Problem: Package upload fails

```bash
# Check package exists
ls -lh cyber-defense-*.tar.gz

# Try with explicit file name
scp cyber-defense-20251202_143022.tar.gz root@YOUR_SERVER_IP:/root/
```

### Problem: Docker not starting

```bash
# Check Docker status
systemctl status docker

# Start Docker
systemctl start docker

# Enable Docker on boot
systemctl enable docker
```

### Problem: Port already in use

```bash
# Check what's using port 3000
lsof -i :3000

# Or use netstat
netstat -tulpn | grep 3000

# Stop conflicting service or change port in docker-compose.yml
```

### Problem: Services won't start

```bash
# Check disk space
df -h

# Check memory
free -h

# Check Docker logs
docker-compose logs

# Restart Docker
systemctl restart docker
```

### Problem: Can't access dashboard from outside

```bash
# Check firewall
ufw status

# Check if service is listening
netstat -tulpn | grep 3000

# Check container is running
docker ps | grep dashboard

# Try from server first
curl http://localhost:3000
```

---

## Server Requirements

### Minimum
- **OS:** Ubuntu 20.04+ or Debian 11+
- **CPU:** 2 vCPUs
- **RAM:** 4GB
- **Disk:** 10GB free
- **Network:** 100 Mbps

### Recommended (for Hetzner)
- **Server:** CPX21 or CX31
- **CPU:** 3-4 vCPUs
- **RAM:** 8GB
- **Disk:** 40GB SSD
- **Cost:** ~€10-15/month

---

## Security Considerations

### For Production Use

1. **Change default passwords:**
   ```bash
   # Edit docker-compose.yml
   # Change POSTGRES_PASSWORD
   ```

2. **Use SSH keys instead of password:**
   ```bash
   # On local machine
   ssh-keygen
   ssh-copy-id root@YOUR_SERVER_IP
   
   # Then disable password auth on server
   # Edit /etc/ssh/sshd_config
   # PasswordAuthentication no
   systemctl restart sshd
   ```

3. **Restrict firewall:**
   ```bash
   # Only allow your IP to access dashboard
   ufw allow from YOUR_IP to any port 3000
   ```

4. **Enable automatic updates:**
   ```bash
   apt update
   apt install unattended-upgrades
   dpkg-reconfigure unattended-upgrades
   ```

5. **Set up monitoring:**
   ```bash
   # Install monitoring tools
   apt install htop nethogs iotop
   ```

---

## Backup and Restore

### Backup database

```bash
cd /root/cyber-defense-deploy
docker-compose exec db pg_dump -U postgres cyber_events > backup.sql
```

### Restore database

```bash
cd /root/cyber-defense-deploy
docker-compose exec -T db psql -U postgres cyber_events < backup.sql
```

### Backup entire deployment

```bash
cd /root
tar -czf cyber-defense-backup-$(date +%Y%m%d).tar.gz cyber-defense-deploy/
```

---

## Update Procedure

To update to a new version:

```bash
# Create backup
cd /root/cyber-defense-deploy
docker-compose down
cd /root
tar -czf cyber-defense-backup-$(date +%Y%m%d).tar.gz cyber-defense-deploy/

# Upload new package
# ... upload new tar.gz ...

# Extract new version
tar -xzf cyber-defense-NEW.tar.gz -C /root/cyber-defense-new

# Copy database volume (if needed)
# Start new version
cd /root/cyber-defense-new
docker-compose up -d
```

---

## Quick Reference Card

```
╔════════════════════════════════════════════════════════╗
║  Quick Reference Card                                  ║
╚════════════════════════════════════════════════════════╝

Create Package:     ./create-deployment-package.sh
Upload:             scp package.tar.gz root@IP:/root/
Extract:            tar -xzf package.tar.gz
Deploy:             cd cyber-defense-deploy && ./deploy.sh
Access:             http://SERVER_IP:3000

Status:             docker-compose ps
Logs:               docker-compose logs -f
Restart:            docker-compose restart
Stop:               docker-compose down

Firewall:           ufw allow 22,3000/tcp && ufw enable
Backup DB:          docker-compose exec db pg_dump ...
Monitor:            htop, docker stats

Support: Check logs first, then README.md
```

---

## Success Indicators

Your deployment is successful when:

✅ All 5 containers show as "running" in `docker-compose ps`  
✅ `curl http://localhost:8000/health` returns healthy status  
✅ Dashboard accessible at `http://YOUR_SERVER_IP:3000`  
✅ Events being generated (check logs: `docker logs cyber-backend`)  
✅ Database has data: `docker exec cyber-events-db psql -U postgres -d cyber_events -c "SELECT COUNT(*) FROM event_analyses;"`

---

**Deployment should take 5-10 minutes total!**
