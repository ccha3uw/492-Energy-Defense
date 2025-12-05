# Simple Hetzner Deployment Guide (Root + Password)

## Quick Deployment (3 Commands)

### On Your Local Machine:

```bash
# 1. Create deployment package
./create-deployment-package.sh

# 2. Deploy to Hetzner (you'll be prompted for password)
./deploy-to-hetzner-simple.sh YOUR_SERVER_IP

# Or provide password directly (less secure but convenient)
./deploy-to-hetzner-simple.sh YOUR_SERVER_IP yourpassword
```

That's it! The script will:
- ✅ Install Docker on the server
- ✅ Upload the application
- ✅ Start all services
- ✅ Verify everything is running

---

## Manual Deployment (If Scripts Don't Work)

### Step 1: Create Package

On your local machine:
```bash
./create-deployment-package.sh
```

This creates: `cyber-defense-YYYYMMDD-HHMMSS.tar.gz`

### Step 2: Copy to Server

```bash
# Copy package to server
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

Enter your root password when prompted.

### Step 3: SSH Into Server

```bash
ssh root@YOUR_SERVER_IP
```

### Step 4: Install Docker (One-Time)

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install -y docker-compose

# Verify
docker --version
docker-compose --version
```

### Step 5: Extract and Start

```bash
# Extract package
tar -xzf cyber-defense-*.tar.gz
cd 492-energy-defense

# Start services
docker-compose up -d

# Watch model download (1-2 minutes)
docker logs -f ollama-init
# Press Ctrl+C when you see "Qwen model ready!"
```

### Step 6: Verify

```bash
# Check containers
docker ps

# Test API
curl http://localhost:8000/health

# View logs
docker logs cyber-agent
```

---

## Access Your Application

### From Browser:
- **Dashboard**: `http://YOUR_SERVER_IP:3000`
- **API**: `http://YOUR_SERVER_IP:8000`
- **API Docs**: `http://YOUR_SERVER_IP:8000/docs`

### Configure Firewall (Optional):

```bash
# On the server
ufw allow 22/tcp    # SSH
ufw allow 3000/tcp  # Dashboard
ufw allow 8000/tcp  # API
ufw enable
```

---

## Troubleshooting

### Problem: "Low" severity for critical events

**Solution:**
```bash
# SSH into server
ssh root@YOUR_SERVER_IP

# Navigate to project
cd /root/492-energy-defense

# Run fix script
./apply-fix.sh
# Choose option 1 for Rule-Based Mode (100% accurate)
```

### Problem: Can't connect to server

**Check:**
```bash
# Verify server is accessible
ping YOUR_SERVER_IP

# Check SSH is enabled
telnet YOUR_SERVER_IP 22
```

### Problem: sshpass not installed (for password auth)

**Ubuntu/Debian:**
```bash
sudo apt install sshpass
```

**macOS:**
```bash
brew install hudochenkov/sshpass/sshpass
```

**Windows:**
Use WSL2 or manually copy files with WinSCP

### Problem: Docker not running

```bash
# On server
systemctl start docker
systemctl enable docker
```

### Problem: Services not starting

```bash
# On server, in project directory
cd /root/492-energy-defense

# Check what's wrong
docker-compose ps
docker-compose logs

# Restart
docker-compose down
docker-compose up -d
```

---

## Useful Commands

### On Your Local Machine:

```bash
# Create new deployment package
./create-deployment-package.sh

# Deploy to server
./deploy-to-hetzner-simple.sh YOUR_SERVER_IP

# SSH into server
ssh root@YOUR_SERVER_IP
```

### On The Server:

```bash
# Navigate to project
cd /root/492-energy-defense

# View status
docker ps

# View logs
docker logs cyber-agent          # Agent logs
docker logs cyber-backend        # Backend logs
docker logs ollama-qwen          # LLM logs
docker logs cyber-dashboard      # Dashboard logs

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Fresh start (removes data)
docker-compose down -v
docker-compose up -d

# Apply scoring fix
./apply-fix.sh
```

---

## Package Contents

The deployment package includes:

```
492-energy-defense/
├── agent/                      # AI agent service
├── backend/                    # Data generator
├── dashboard/                  # Web dashboard
├── docker-compose.yml          # Main orchestration
├── docker-compose-simple.yml   # Simplified version
├── .env.example                # Configuration template
├── start.sh                    # Quick start script
├── apply-fix.sh                # Fix scoring issues
├── check-qwen-model.sh         # Verify model loaded
├── test-llm-mode.sh            # Test LLM mode
├── README.md                   # Full documentation
├── FIX_QWEN_SCORING_ISSUE.md   # Troubleshooting guide
└── DEPLOY_INSTRUCTIONS.txt     # Quick reference
```

---

## Performance on Different Hetzner Plans

### CX21 (2 vCPU, 4GB RAM) - €6/month
- ✅ Works with Rule-Based mode
- ⚠️ Struggles with LLM mode
- **Recommended**: Use `USE_LLM=false`

### CPX21 (3 vCPU, 4GB RAM) - €9/month
- ✅ Works well with Rule-Based
- ⚠️ Marginal with Qwen 0.5B
- **Recommended**: Use Rule-Based

### CPX31 (4 vCPU, 8GB RAM) - €15/month
- ✅ Works great with Rule-Based
- ✅ Good with Qwen 1.5B
- **Recommended**: Qwen 1.5B or Rule-Based

### CPX41 (8 vCPU, 16GB RAM) - €30/month
- ✅ Excellent with any mode
- ✅ Can run Qwen 3B
- **Recommended**: Qwen 3B for best AI

---

## Security Notes

### Change Default Passwords

The application uses default credentials for the database. For production:

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change these:
POSTGRES_PASSWORD: your_secure_password
```

### Firewall Configuration

Only open necessary ports:
```bash
ufw allow 22/tcp     # SSH
ufw allow 3000/tcp   # Dashboard (optional)
ufw allow 8000/tcp   # API (optional)
ufw enable
```

### SSL/HTTPS (Optional)

For production, consider adding nginx with SSL:
```bash
apt install -y nginx certbot python3-certbot-nginx
certbot --nginx -d yourdomain.com
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Create package | `./create-deployment-package.sh` |
| Deploy to server | `./deploy-to-hetzner-simple.sh IP` |
| SSH to server | `ssh root@YOUR_IP` |
| Start services | `docker-compose up -d` |
| Stop services | `docker-compose down` |
| View logs | `docker logs cyber-agent` |
| Fix scoring | `./apply-fix.sh` |
| Check status | `docker ps` |
| Dashboard | `http://YOUR_IP:3000` |
| API | `http://YOUR_IP:8000` |

---

## Support

If you encounter issues:

1. Check logs: `docker logs cyber-agent`
2. Read: `DEPLOY_INSTRUCTIONS.txt` on server
3. Read: `FIX_QWEN_SCORING_ISSUE.md` for scoring issues
4. Verify Docker is running: `systemctl status docker`
5. Try fresh start: `docker-compose down -v && docker-compose up -d`

---

**Ready to deploy?**

```bash
./create-deployment-package.sh
./deploy-to-hetzner-simple.sh YOUR_SERVER_IP
```

Done! 🚀
