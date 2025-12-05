#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="492-energy-defense-deploy.tar.gz"

echo "Preparing files..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
PROJECT_DIR="$TEMP_DIR/492-energy-defense"
mkdir -p "$PROJECT_DIR"

# Copy essential files
echo "Copying application files..."
cp -r agent "$PROJECT_DIR/"
cp -r backend "$PROJECT_DIR/"
cp -r dashboard "$PROJECT_DIR/"
cp docker-compose.yml "$PROJECT_DIR/"
cp .env.example "$PROJECT_DIR/.env"
cp -r .gitignore "$PROJECT_DIR/" 2>/dev/null || true

# Copy useful scripts
echo "Copying scripts..."
cp start.sh "$PROJECT_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$PROJECT_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$PROJECT_DIR/" 2>/dev/null || true
cp apply-fix.sh "$PROJECT_DIR/" 2>/dev/null || true

# Copy README
cp README.md "$PROJECT_DIR/" 2>/dev/null || true

# Create deployment script
echo "Creating deployment script..."
cat > "$PROJECT_DIR/deploy-hetzner.sh" << 'DEPLOY_EOF'
#!/bin/bash
# Hetzner deployment script - Run as root

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - Hetzner Deployment              ║"
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
apt-get upgrade -y -qq

echo -e "${YELLOW}[2/6] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get install -y -qq apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

echo -e "${YELLOW}[3/6] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi

echo -e "${YELLOW}[4/6] Starting Docker service...${NC}"
systemctl start docker
systemctl enable docker
echo -e "${GREEN}✓ Docker service running${NC}"

echo -e "${YELLOW}[5/6] Configuring firewall...${NC}"
# Install ufw if not present
if ! command -v ufw &> /dev/null; then
    apt-get install -y -qq ufw
fi

# Configure firewall
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 8000/tcp  # Agent API
ufw allow 3000/tcp  # Dashboard
ufw allow 5432/tcp  # PostgreSQL (optional, for external access)
echo -e "${GREEN}✓ Firewall configured${NC}"

echo -e "${YELLOW}[6/6] Starting application...${NC}"
cd /root/492-energy-defense

# Build and start services
docker-compose build
docker-compose up -d

echo ""
echo "Waiting for services to initialize..."
sleep 15

# Wait for Qwen model download
echo "Downloading Qwen model (1-2 minutes)..."
docker logs -f ollama-init &
LOGS_PID=$!
sleep 60
kill $LOGS_PID 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Your services are now running:"
echo ""
echo "  📊 Dashboard:    http://$(curl -s ifconfig.me):3000"
echo "  🤖 Agent API:    http://$(curl -s ifconfig.me):8000"
echo "  📚 API Docs:     http://$(curl -s ifconfig.me):8000/docs"
echo "  🗄️  Database:     $(curl -s ifconfig.me):5432"
echo ""
echo "Useful commands:"
echo "  View logs:       docker-compose logs -f"
echo "  Check status:    docker-compose ps"
echo "  Stop services:   docker-compose down"
echo "  Restart:         docker-compose restart"
echo ""
echo "Check model status:"
echo "  docker exec ollama-qwen ollama list"
echo ""
echo "Test the agent:"
echo "  curl http://localhost:8000/health | jq"
echo ""

DEPLOY_EOF

chmod +x "$PROJECT_DIR/deploy-hetzner.sh"

# Create quick start guide
cat > "$PROJECT_DIR/HETZNER_DEPLOY.md" << 'GUIDE_EOF'
# Quick Deployment to Hetzner

## Step 1: Create Server

1. Go to https://console.hetzner.cloud/
2. Create new server:
   - **Image**: Ubuntu 22.04 LTS
   - **Type**: CPX21 (3 vCPU, 8GB RAM) - €15/month minimum
   - **Location**: Closest to you
   - **Add SSH Key** (or use password)
3. Copy the server IP address

## Step 2: Upload Package

From your local machine:

```bash
# Upload the deployment package
scp 492-energy-defense-deploy.tar.gz root@YOUR_SERVER_IP:/root/

# Or if you have the extracted directory
scp -r 492-energy-defense root@YOUR_SERVER_IP:/root/
```

## Step 3: Deploy

SSH into your server:

```bash
ssh root@YOUR_SERVER_IP
```

Then run:

```bash
# If you uploaded the tar.gz
cd /root
tar -xzf 492-energy-defense-deploy.tar.gz
cd 492-energy-defense

# Run deployment script
chmod +x deploy-hetzner.sh
./deploy-hetzner.sh
```

That's it! The script will:
- Install Docker & Docker Compose
- Configure firewall
- Download Qwen model
- Start all services

## Step 4: Access Your System

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Troubleshooting

### Check if services are running
```bash
docker-compose ps
```

### View logs
```bash
docker-compose logs -f
```

### Check Qwen model
```bash
docker exec ollama-qwen ollama list
```

### Restart services
```bash
docker-compose restart
```

### Fresh start
```bash
docker-compose down
docker-compose up -d
```

## Security Notes

**For production, you should:**
1. Change default passwords in `.env`
2. Set up a domain with SSL/TLS
3. Restrict database port (5432) in firewall
4. Create a non-root user
5. Set up automatic backups

## Resource Requirements

- **Minimum**: CPX21 (8GB RAM, 3 vCPU) - €15/month
- **Recommended**: CPX31 (16GB RAM, 4 vCPU) - €30/month

The Qwen 2.5 0.5B model needs ~2-4GB RAM.

## Support

View logs if something goes wrong:
```bash
docker-compose logs agent
docker-compose logs ollama-qwen
docker-compose logs backend
```
GUIDE_EOF

# Create the tar.gz
echo "Creating archive..."
cd "$TEMP_DIR"
tar -czf "$PACKAGE_NAME" 492-energy-defense/

# Move to current directory
mv "$PACKAGE_NAME" /workspace/

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Package created successfully!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Package: $PACKAGE_NAME"
echo "Size: $(du -h /workspace/$PACKAGE_NAME | cut -f1)"
echo ""
echo "To deploy to Hetzner:"
echo ""
echo "1. Upload to your server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH into server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd 492-energy-defense"
echo "   ./deploy-hetzner.sh"
echo ""
echo "See 492-energy-defense/HETZNER_DEPLOY.md for full instructions."
echo ""

