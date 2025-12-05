# Hetzner Deployment Guide - Easy Mode

## 🚀 One-Command Deployment

The easiest way to deploy:

```bash
cd deploy
bash one-command-deploy.sh
```

That's it! The script will:
1. ✅ Setup the Hetzner server (install Docker, configure firewall, etc.)
2. ✅ Deploy the application
3. ✅ Start all services
4. ✅ Verify everything is working

**Time: ~10 minutes**

---

## 📋 Prerequisites

### On Your Local Machine
- SSH client
- Bash shell
- Your Hetzner server IP address

### Hetzner Server Requirements
- **OS**: Ubuntu 22.04 or 24.04
- **RAM**: 8GB minimum (16GB recommended)
- **CPU**: 2 vCPUs minimum (4 recommended)
- **Disk**: 40GB minimum
- **Root access** or sudo privileges

### Recommended Hetzner Servers

| Server Type | vCPU | RAM | Disk | Price/mo | Best For |
|-------------|------|-----|------|----------|----------|
| CPX21 | 3 | 8GB | 80GB | ~€15 | Testing |
| CPX31 | 4 | 16GB | 160GB | ~€30 | Production |
| CPX41 | 8 | 32GB | 240GB | ~€60 | High Load |

---

## 🎯 Deployment Methods

### Method 1: One-Command (Recommended)

```bash
cd deploy
bash one-command-deploy.sh
```

Enter your server IP when prompted. Done!

---

### Method 2: Two-Step Deployment

If you want more control:

**Step 1: Setup Server (on Hetzner server)**
```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Download setup script
curl -O https://raw.githubusercontent.com/your-repo/492-energy-defense/main/deploy/setup-hetzner-server.sh

# Run setup
bash setup-hetzner-server.sh
```

**Step 2: Deploy Application (from local machine)**
```bash
cd deploy
bash deploy-to-hetzner.sh YOUR_SERVER_IP
```

---

### Method 3: Manual Deployment

**On your Hetzner server:**

```bash
# 1. Run setup script
sudo bash setup-hetzner-server.sh

# 2. Switch to cyber user
su - cyber

# 3. Clone repository
cd ~
git clone <your-repo-url> app
cd app

# 4. Start services
docker compose up -d

# 5. Check status
docker compose ps
docker logs -f ollama-init  # Wait for "Qwen model ready!"
```

---

## 🔍 Post-Deployment

### Access Your Services

```bash
# Dashboard
http://YOUR_SERVER_IP:3000

# Agent API
http://YOUR_SERVER_IP:8000

# API Documentation
http://YOUR_SERVER_IP:8000/docs
```

### Check Status

```bash
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose ps'
```

### View Logs

```bash
# All logs
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose logs -f'

# Specific service
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose logs -f agent'
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose logs -f backend'
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose logs -f dashboard'
```

### Test Agent

```bash
curl http://YOUR_SERVER_IP:8000/health | jq
```

---

## 🔧 Configuration

### Change LLM Mode

```bash
# SSH into server
ssh cyber@YOUR_SERVER_IP

# Edit docker-compose.yml
cd app
nano docker-compose.yml

# Change USE_LLM=true to USE_LLM=false (or vice versa)
# Save and restart
docker compose restart agent
```

### Change Database Password

```bash
cd app
nano .env

# Change POSTGRES_PASSWORD=postgres to something secure
# Restart services
docker compose down
docker compose up -d
```

### Update Application

```bash
ssh cyber@YOUR_SERVER_IP
cd app
git pull
docker compose down
docker compose build
docker compose up -d
```

---

## 🔒 Security Recommendations

### 1. Change Default Passwords

```bash
ssh cyber@YOUR_SERVER_IP
cd app
nano .env

# Change these:
POSTGRES_PASSWORD=your_secure_password_here
```

### 2. Setup HTTPS (Optional)

Install Nginx and Certbot for HTTPS:

```bash
# On server
sudo apt install nginx certbot python3-certbot-nginx

# Configure Nginx reverse proxy
sudo nano /etc/nginx/sites-available/cyber-defense

# Add:
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
    }

    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/cyber-defense /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

### 3. Restrict Database Access

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Remove or comment out the database port exposure:
# ports:
#   - "5432:5432"

# Restart
docker compose down
docker compose up -d
```

### 4. Setup Monitoring

```bash
# Install monitoring tools
ssh cyber@YOUR_SERVER_IP
sudo apt install htop iotop nethogs

# View resources
htop           # CPU/Memory
docker stats   # Container stats
```

---

## 🐛 Troubleshooting

### Services Not Starting

```bash
# Check logs
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose logs'

# Check Docker
ssh cyber@YOUR_SERVER_IP 'docker ps'

# Restart everything
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose down && docker compose up -d'
```

### Model Not Loading

```bash
# Check Ollama logs
ssh cyber@YOUR_SERVER_IP 'docker logs ollama-init'

# Manually pull model
ssh cyber@YOUR_SERVER_IP 'docker exec ollama-qwen ollama pull qwen2.5:1.5b'
```

### Out of Memory

```bash
# Check memory usage
ssh cyber@YOUR_SERVER_IP 'free -h'

# Reduce Docker memory limits in docker-compose.yml
# Or upgrade to a larger Hetzner server
```

### Port Already in Use

```bash
# Check what's using ports
ssh cyber@YOUR_SERVER_IP 'sudo netstat -tlnp | grep -E "3000|8000|5432"'

# Stop conflicting services or change ports in docker-compose.yml
```

### Cannot Connect to Server

```bash
# Check firewall
ssh cyber@YOUR_SERVER_IP 'sudo ufw status'

# Make sure ports are open
ssh cyber@YOUR_SERVER_IP 'sudo ufw allow 8000/tcp'
```

---

## 📊 Performance Tuning

### For Low-RAM Servers (8GB)

```yaml
# Edit docker-compose.yml
ollama:
  deploy:
    resources:
      limits:
        memory: 4G  # Reduce from 8G
```

### For High-Traffic

```yaml
# Add more worker processes
agent:
  environment:
    - WORKERS=4  # Increase from default
```

### Database Optimization

```bash
# Connect to database
ssh cyber@YOUR_SERVER_IP
docker exec -it cyber-events-db psql -U postgres -d cyber_events

-- Optimize queries
CREATE INDEX IF NOT EXISTS idx_event_analyses_severity ON event_analyses(severity);
CREATE INDEX IF NOT EXISTS idx_event_analyses_timestamp ON event_analyses(analyzed_at);
```

---

## 🔄 Backup & Restore

### Backup Database

```bash
# Create backup
ssh cyber@YOUR_SERVER_IP 'docker exec cyber-events-db pg_dump -U postgres cyber_events > ~/backup.sql'

# Download backup
scp cyber@YOUR_SERVER_IP:~/backup.sql ./backup-$(date +%Y%m%d).sql
```

### Restore Database

```bash
# Upload backup
scp backup.sql cyber@YOUR_SERVER_IP:~/

# Restore
ssh cyber@YOUR_SERVER_IP 'docker exec -i cyber-events-db psql -U postgres cyber_events < ~/backup.sql'
```

---

## 📞 Support

### Deployment Issues

Check the deployment logs:
```bash
cd deploy
cat deployment.log  # If created by script
```

### Service Issues

```bash
ssh cyber@YOUR_SERVER_IP 'cd app && docker compose logs --tail=100'
```

### Need Help?

1. Check the main README.md
2. Review troubleshooting section above
3. Check Docker logs
4. Verify firewall settings

---

## 🎓 What Gets Deployed

The deployment includes:

- ✅ PostgreSQL database
- ✅ Ollama with Qwen model
- ✅ AI Agent (FastAPI)
- ✅ Backend data generator
- ✅ Web dashboard
- ✅ Automatic restart policies
- ✅ Health checks
- ✅ Log rotation
- ✅ Firewall configuration
- ✅ System optimizations

---

## 📚 Next Steps After Deployment

1. **Access the dashboard**: http://YOUR_SERVER_IP:3000
2. **Review the API docs**: http://YOUR_SERVER_IP:8000/docs
3. **Check the logs**: Monitor for first event generation (every 30 min)
4. **Customize**: Edit configuration in .env file
5. **Secure**: Change default passwords and setup HTTPS

---

**Deployment Time**: ~10 minutes  
**Difficulty**: Easy (one command)  
**Cost**: From €15/month on Hetzner
