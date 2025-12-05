#!/bin/bash
# Create tar.gz deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating package: $PACKAGE_NAME"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
DEPLOY_DIR="$TEMP_DIR/cyber-defense"
mkdir -p "$DEPLOY_DIR"

echo "Copying files..."

# Copy essential files and directories
cp -r agent "$DEPLOY_DIR/"
cp -r backend "$DEPLOY_DIR/"
cp -r dashboard "$DEPLOY_DIR/"
cp docker-compose.yml "$DEPLOY_DIR/"
cp .env.example "$DEPLOY_DIR/"
cp .gitignore "$DEPLOY_DIR/" 2>/dev/null || true

# Copy scripts
cp start.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp apply-fix.sh "$DEPLOY_DIR/" 2>/dev/null || true

# Copy documentation
cp README.md "$DEPLOY_DIR/" 2>/dev/null || true
cp PROJECT_SUMMARY.md "$DEPLOY_DIR/" 2>/dev/null || true

# Create deployment script for Hetzner
cat > "$DEPLOY_DIR/deploy-on-hetzner.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
# Run this script on your Hetzner server as root

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense Deployment on Hetzner             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "Error: Please run as root"
   exit 1
fi

echo "Step 1/5: Updating system..."
apt-get update -qq
apt-get upgrade -y -qq

echo "Step 2/5: Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Verify Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose not found"
    exit 1
fi

echo "Step 3/5: Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 8000/tcp  # Agent API
    ufw allow 3000/tcp  # Dashboard
    ufw reload
    echo "✓ Firewall configured"
else
    echo "⚠ UFW not available, skipping firewall setup"
fi

echo "Step 4/5: Starting application..."

# Set up environment
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Start services
docker-compose down 2>/dev/null || true
docker-compose up -d

echo "Step 5/5: Waiting for services to start..."
sleep 15

# Check status
docker-compose ps

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ Deployment Complete!                               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Services are starting up. This may take a few minutes."
echo ""
echo "📊 Access your services:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
echo "   • Dashboard:  http://$SERVER_IP:3000"
echo "   • Agent API:  http://$SERVER_IP:8000"
echo "   • API Docs:   http://$SERVER_IP:8000/docs"
echo ""
echo "📝 Useful commands:"
echo "   • Check status:  docker-compose ps"
echo "   • View logs:     docker-compose logs -f"
echo "   • Stop:          docker-compose down"
echo "   • Restart:       docker-compose restart"
echo ""
echo "⏳ Monitor model download:"
echo "   docker logs -f ollama-init"
echo "   (Wait for 'Qwen model ready!')"
echo ""
echo "🧪 Test the system:"
echo "   curl http://localhost:8000/health | jq"
echo ""
DEPLOY_SCRIPT

chmod +x "$DEPLOY_DIR/deploy-on-hetzner.sh"

# Create README for deployment
cat > "$DEPLOY_DIR/DEPLOYMENT_README.md" << 'README'
# Deployment Instructions for Hetzner

## Prerequisites

- Hetzner Cloud server (Ubuntu 22.04 or 24.04)
- Root access with password
- At least 8GB RAM (16GB recommended)
- At least 40GB disk space

## Recommended Server Specs

**Minimum:**
- CPX21: 3 vCPUs, 8 GB RAM (~€15/month)

**Recommended:**
- CPX31: 4 vCPUs, 16 GB RAM (~€30/month)

## Deployment Steps

### 1. Create Hetzner Server

1. Go to: https://console.hetzner.cloud/
2. Create new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX31 (or CPX21 for budget)
   - **Location**: Closest to you
   - **Name**: cyber-defense
3. Set root password
4. Note the server IP address

### 2. Upload Package to Server

From your local machine:

```bash
# Upload the package
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/

# SSH into server
ssh root@YOUR_SERVER_IP
```

### 3. Extract and Deploy

On the Hetzner server:

```bash
# Extract package
cd /root
tar -xzf cyber-defense-*.tar.gz
cd cyber-defense

# Run deployment script
bash deploy-on-hetzner.sh
```

This will:
- Update the system
- Install Docker and Docker Compose
- Configure firewall
- Start all services
- Download the Qwen model

### 4. Monitor Deployment

Watch the model download:
```bash
docker logs -f ollama-init
# Wait for "Qwen model ready!"
```

Check services:
```bash
docker-compose ps
```

### 5. Access Your System

Open in browser:
- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Post-Deployment

### Test the system
```bash
curl http://localhost:8000/health | jq
```

### View logs
```bash
docker-compose logs -f
```

### Check model is loaded
```bash
docker exec ollama-qwen ollama list
```

## Troubleshooting

### Services not starting?
```bash
docker-compose down
docker-compose up -d
docker-compose logs
```

### Firewall blocking access?
```bash
ufw status
ufw allow 3000/tcp
ufw allow 8000/tcp
```

### Model not downloading?
```bash
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

## Security Notes

- Change default passwords in production
- Consider using SSH keys instead of password
- Set up HTTPS if exposing to internet
- Use firewall rules to restrict access

## Support

For issues, check:
- `docker-compose logs`
- `docker ps -a`
- README.md in the package

---

**Deployed with ❤️ for cybersecurity education**
README

echo "✓ Deployment files created"

# Create quick start script
cat > "$DEPLOY_DIR/QUICK_DEPLOY.txt" << 'QUICK'
╔════════════════════════════════════════════════════════╗
║  QUICK DEPLOYMENT GUIDE                                ║
╚════════════════════════════════════════════════════════╝

ON YOUR LOCAL MACHINE:
----------------------

1. Upload package to server:
   scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/

2. SSH to server:
   ssh root@YOUR_SERVER_IP


ON YOUR HETZNER SERVER:
-----------------------

3. Extract and deploy:
   cd /root
   tar -xzf cyber-defense-*.tar.gz
   cd cyber-defense
   bash deploy-on-hetzner.sh

4. Wait for deployment (5-10 minutes)

5. Access at:
   http://YOUR_SERVER_IP:3000 (Dashboard)
   http://YOUR_SERVER_IP:8000 (API)


THAT'S IT! 🎉


Troubleshooting:
- View logs: docker-compose logs -f
- Restart: docker-compose restart
- Check status: docker-compose ps
QUICK

echo ""
echo "Creating tar.gz package..."
cd "$TEMP_DIR"
tar -czf "/tmp/$PACKAGE_NAME" cyber-defense/

# Move to current directory
mv "/tmp/$PACKAGE_NAME" .

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ Package Created Successfully!                      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Package: $PACKAGE_NAME"
echo "Size: $(du -h "$PACKAGE_NAME" | cut -f1)"
echo ""
echo "📦 What's included:"
echo "   • Application code (agent, backend, dashboard)"
echo "   • Docker configuration"
echo "   • Deployment script for Hetzner"
echo "   • Documentation"
echo ""
echo "📤 To deploy to Hetzner:"
echo ""
echo "1. Upload to server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH to server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. On the server, run:"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense"
echo "   bash deploy-on-hetzner.sh"
echo ""
echo "See DEPLOYMENT_README.md in the package for full instructions."
echo ""

# Display the package path
echo "Package location: $(pwd)/$PACKAGE_NAME"
