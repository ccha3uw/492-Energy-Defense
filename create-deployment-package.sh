#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-agent-$(date +%Y%m%d).tar.gz"

echo "Creating tar.gz package..."
echo ""

# Create temporary directory structure
TEMP_DIR="cyber-defense-deploy"
mkdir -p $TEMP_DIR

# Copy essential files
echo "Copying files..."
cp -r agent $TEMP_DIR/
cp -r backend $TEMP_DIR/
cp -r dashboard $TEMP_DIR/
cp docker-compose.yml $TEMP_DIR/
cp .env.example $TEMP_DIR/.env
cp README.md $TEMP_DIR/
cp check-qwen-model.sh $TEMP_DIR/ 2>/dev/null || true
cp apply-fix.sh $TEMP_DIR/ 2>/dev/null || true
cp test-llm-mode.sh $TEMP_DIR/ 2>/dev/null || true

# Create deployment script inside package
cat > $TEMP_DIR/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
# Automated deployment script for Hetzner (root user)

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense Cybersecurity Agent               ║"
echo "║  Hetzner Deployment (Root User)                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Please run as root (or use sudo)${NC}"
   exit 1
fi

echo -e "${YELLOW}[1/6] Updating system...${NC}"
apt-get update -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${YELLOW}[2/6] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get install -y ca-certificates curl gnupg -qq
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -qq
    
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[3/6] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y docker-compose -qq
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[4/6] Installing additional tools...${NC}"
apt-get install -y jq curl net-tools -qq
echo -e "${GREEN}✓ Tools installed${NC}"
echo ""

echo -e "${YELLOW}[5/6] Starting Docker service...${NC}"
systemctl start docker
systemctl enable docker
echo -e "${GREEN}✓ Docker service running${NC}"
echo ""

echo -e "${YELLOW}[6/6] Building and starting containers...${NC}"
docker-compose build
docker-compose up -d
echo -e "${GREEN}✓ Containers started${NC}"
echo ""

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}Waiting for services to initialize...${NC}"
echo "This will take 1-2 minutes while the Qwen model downloads."
echo "════════════════════════════════════════════════════════"
echo ""

# Wait for ollama-init to complete
echo "Monitoring model download..."
sleep 10
docker logs -f ollama-init 2>&1 | grep -m 1 "Qwen model ready!" || sleep 30

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Service URLs:"
echo "   • Dashboard:     http://$(hostname -I | awk '{print $1}'):3000"
echo "   • Agent API:     http://$(hostname -I | awk '{print $1}'):8000"
echo "   • API Docs:      http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "🔧 Useful Commands:"
echo "   • View logs:        docker-compose logs -f"
echo "   • Check status:     docker-compose ps"
echo "   • Stop services:    docker-compose down"
echo "   • Restart:          docker-compose restart"
echo "   • Test model:       ./check-qwen-model.sh"
echo ""
echo "📝 Next Steps:"
echo "   1. Configure firewall (optional):"
echo "      ufw allow 22/tcp"
echo "      ufw allow 3000/tcp"
echo "      ufw allow 8000/tcp"
echo "      ufw enable"
echo ""
echo "   2. Access dashboard: http://YOUR_SERVER_IP:3000"
echo ""
echo "   3. Monitor logs: docker-compose logs -f"
echo ""
DEPLOY_SCRIPT

chmod +x $TEMP_DIR/deploy.sh

# Create README for deployment
cat > $TEMP_DIR/DEPLOY_README.md << 'README'
# Quick Deployment Guide

## On Your Hetzner Server

### Step 1: Upload the package
```bash
# On your local machine
scp cyber-defense-agent-*.tar.gz root@YOUR_SERVER_IP:/root/

# SSH into server
ssh root@YOUR_SERVER_IP
```

### Step 2: Extract and deploy
```bash
# Extract package
cd /root
tar -xzf cyber-defense-agent-*.tar.gz
cd cyber-defense-deploy

# Run deployment
./deploy.sh
```

### Step 3: Access services

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Firewall Configuration (Optional)

```bash
ufw allow 22/tcp    # SSH
ufw allow 3000/tcp  # Dashboard
ufw allow 8000/tcp  # Agent API
ufw enable
```

## Useful Commands

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Check model loaded
./check-qwen-model.sh
```

## Troubleshooting

### Services not starting
```bash
docker-compose logs
docker-compose restart
```

### Model not loading
```bash
docker exec ollama-qwen ollama list
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

### Fix scoring issues
```bash
./apply-fix.sh
# Choose option 1 for rule-based (recommended)
```

## System Requirements

- Ubuntu 20.04+ or Debian 11+
- 4GB+ RAM (8GB recommended)
- 20GB+ disk space
- Root access

## Support

See README.md for full documentation.
README

# Create the tar.gz package
echo "Packaging files..."
tar -czf $PACKAGE_NAME $TEMP_DIR

# Clean up temp directory
rm -rf $TEMP_DIR

# Get package size
SIZE=$(du -h $PACKAGE_NAME | cut -f1)

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Package created successfully!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📦 Package: $PACKAGE_NAME"
echo "📊 Size: $SIZE"
echo ""
echo "📤 Deploy to Hetzner:"
echo ""
echo "1. Upload to server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH and deploy:"
echo "   ssh root@YOUR_SERVER_IP"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense-deploy"
echo "   ./deploy.sh"
echo ""
echo "🌐 Access dashboard at: http://YOUR_SERVER_IP:3000"
echo ""

