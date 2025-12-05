# Easy Hetzner Deployment Package

## 🚀 One-Command Deployment

This package allows you to deploy the 492-Energy-Defense system to a Hetzner server with a single command.

## Prerequisites

1. **Hetzner Cloud Account**: https://console.hetzner.cloud/
2. **SSH Key**: Your public SSH key added to Hetzner
3. **Local Machine**: Linux/macOS with SSH, rsync, and curl

## Quick Start (5 Minutes)

### Step 1: Create Hetzner Server

1. Go to https://console.hetzner.cloud/
2. Create new project: `cyber-defense`
3. Add server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 4GB RAM) - €9/month (Rule-based)
   - **Type**: CPX31 (4 vCPU, 8GB RAM) - €16/month (For LLM mode)
   - **Location**: Closest to you
   - **SSH Key**: Add your key
   - **Name**: cyber-defense-server
4. **Copy the IP address**: e.g., `65.21.123.45`

### Step 2: Deploy

From your local machine (in the project root):

```bash
cd hetzner-deploy
./deploy.sh 65.21.123.45
```

That's it! The script will:
- ✅ Setup the server (install Docker, configure firewall)
- ✅ Deploy the application
- ✅ Start all services
- ✅ Run health checks

### Step 3: Access

After deployment completes:

- **Dashboard**: http://65.21.123.45:3000
- **Agent API**: http://65.21.123.45:8000
- **SSH Access**: `ssh root@65.21.123.45`

## Server Size Guide

| Server Type | vCPU | RAM | Disk | Cost/Month | Use Case |
|-------------|------|-----|------|------------|----------|
| CX11 | 1 | 2GB | 20GB | €4 | Testing only |
| CPX21 | 3 | 4GB | 80GB | €9 | Rule-based (Recommended) |
| CPX31 | 4 | 8GB | 160GB | €16 | LLM mode with Qwen 1.5B |
| CPX41 | 8 | 16GB | 240GB | €32 | LLM mode with Qwen 3B |

**Recommendation**: Start with CPX21 using rule-based mode (100% accurate, faster)

## What Gets Deployed

- ✅ Docker & Docker Compose
- ✅ All application services (database, agent, backend, dashboard)
- ✅ Firewall configuration (ports 22, 3000, 8000, 8080)
- ✅ Log rotation
- ✅ Auto-restart policies
- ✅ Health monitoring
- ✅ Backup scripts (optional)

## Advanced Options

### Deploy with Custom Configuration

```bash
# Deploy with specific model
./deploy.sh 65.21.123.45 --model qwen2.5:1.5b

# Deploy with rule-based mode (recommended)
./deploy.sh 65.21.123.45 --rule-based

# Deploy with custom SSH user
./deploy.sh 65.21.123.45 --user myuser

# Deploy with SSL/domain
./deploy.sh 65.21.123.45 --domain cyberdefense.example.com
```

### Setup SSL/HTTPS (Optional)

```bash
# After initial deployment
ssh root@65.21.123.45
cd /opt/cyber-defense/hetzner-deploy
./setup-ssl.sh cyberdefense.example.com your@email.com
```

### Enable Monitoring (Optional)

```bash
ssh root@65.21.123.45
cd /opt/cyber-defense/hetzner-deploy
./setup-monitoring.sh
```

## Management Commands

On the server:

```bash
# Status check
cd /opt/cyber-defense
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d

# Backup database
./hetzner-deploy/backup.sh

# View system health
./hetzner-deploy/health-check.sh
```

## Troubleshooting

### Deployment Failed

```bash
# Check logs
./deploy.sh 65.21.123.45 --verbose

# Or manually SSH and check
ssh root@65.21.123.45
cd /opt/cyber-defense
docker-compose logs
```

### Services Not Starting

```bash
ssh root@65.21.123.45
docker ps  # Check running containers
docker-compose ps  # Check all services
docker logs cyber-agent  # Check specific service
```

### Can't Connect

```bash
# Check firewall
ssh root@65.21.123.45
ufw status

# Make sure ports are open
ufw allow 3000/tcp
ufw allow 8000/tcp
```

## Files in This Package

```
hetzner-deploy/
├── README.md                 # This file
├── deploy.sh                 # Main deployment script
├── server-setup.sh          # Server preparation script
├── docker-compose.prod.yml  # Production docker-compose
├── .env.production          # Production environment
├── setup-ssl.sh             # SSL/HTTPS setup
├── setup-monitoring.sh      # Monitoring setup
├── backup.sh                # Database backup script
├── health-check.sh          # Health monitoring
├── nginx/                   # Nginx configs (optional)
│   ├── default.conf
│   └── ssl.conf
└── systemd/                 # Systemd services (optional)
    └── cyber-defense.service
```

## Security Notes

- Default passwords are used (postgres/postgres)
- Firewall is configured but basic
- No SSL by default (use setup-ssl.sh)
- Consider changing database password in production
- Regular backups recommended

## Updating the Deployment

To update an existing deployment:

```bash
./deploy.sh 65.21.123.45 --update
```

## Uninstalling

To remove everything:

```bash
ssh root@65.21.123.45
cd /opt/cyber-defense
docker-compose down -v
cd /
rm -rf /opt/cyber-defense
```

## Support

For issues:
1. Check logs: `docker-compose logs`
2. Check system: `./hetzner-deploy/health-check.sh`
3. Review main README.md in project root

---

**Ready to deploy?**

```bash
./deploy.sh YOUR_SERVER_IP
```
