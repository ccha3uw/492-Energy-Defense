#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "📦 Packaging files..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
DEPLOY_DIR="$TEMP_DIR/cyber-defense"
mkdir -p "$DEPLOY_DIR"

# Copy essential files
echo "  → Copying application files..."
cp -r agent "$DEPLOY_DIR/"
cp -r backend "$DEPLOY_DIR/"
cp -r dashboard "$DEPLOY_DIR/"
cp docker-compose.yml "$DEPLOY_DIR/"
cp .env.example "$DEPLOY_DIR/.env"

# Copy documentation
echo "  → Copying documentation..."
cp README.md "$DEPLOY_DIR/" 2>/dev/null || true
cp FIX_QWEN_SCORING_ISSUE.md "$DEPLOY_DIR/" 2>/dev/null || true

# Copy utility scripts
echo "  → Copying utility scripts..."
cp start.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp apply-fix.sh "$DEPLOY_DIR/" 2>/dev/null || true

# Create deployment script for Hetzner
cat > "$DEPLOY_DIR/deploy-on-hetzner.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
# Deployment script for Hetzner server

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
    echo -e "${RED}Please run as root (use: sudo ./deploy-on-hetzner.sh)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/6] Updating system packages...${NC}"
apt-get update -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${YELLOW}[2/6] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[3/6] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[4/6] Starting Docker service...${NC}"
systemctl start docker
systemctl enable docker
echo -e "${GREEN}✓ Docker service started${NC}"
echo ""

echo -e "${YELLOW}[5/6] Configuring firewall...${NC}"
# Install ufw if not present
if ! command -v ufw &> /dev/null; then
    apt-get install -y ufw
fi

# Configure firewall
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 3000/tcp  # Dashboard
ufw allow 8000/tcp  # Agent API
echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

echo -e "${YELLOW}[6/6] Starting application...${NC}"
cd "$(dirname "$0")"

# Start services
docker-compose up -d

echo -e "${GREEN}✓ Services starting...${NC}"
echo ""

echo "⏳ Waiting for services to initialize (this may take 2-3 minutes)..."
echo "   The Qwen model will download in the background (~400MB)"
echo ""

# Wait a bit for services to start
sleep 15

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Access your services:"
echo ""
echo "  Dashboard:  http://$(hostname -I | awk '{print $1}'):3000"
echo "  Agent API:  http://$(hostname -I | awk '{print $1}'):8000"
echo "  API Docs:   http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "📝 Useful commands:"
echo ""
echo "  Check status:     docker-compose ps"
echo "  View logs:        docker-compose logs -f"
echo "  Stop services:    docker-compose down"
echo "  Restart:          docker-compose restart"
echo ""
echo "  Check Qwen model: docker exec ollama-qwen ollama list"
echo "  Agent health:     curl http://localhost:8000/health"
echo ""
echo "⚠️  Note: Model download continues in background."
echo "    Check progress: docker logs -f ollama-init"
echo ""
echo "📚 For more information, see README.md"
echo "════════════════════════════════════════════════════════"
DEPLOY_SCRIPT

chmod +x "$DEPLOY_DIR/deploy-on-hetzner.sh"

# Create README for deployment
cat > "$DEPLOY_DIR/DEPLOY_README.md" << 'DEPLOY_README'
# Quick Deployment to Hetzner

## Prerequisites

- Hetzner Cloud Server (CPX21 or better)
- Ubuntu 22.04 or 24.04
- Root access with password

## Deployment Steps

### 1. Upload Package to Server

**Option A: Using scp (if you have it)**
```bash
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

**Option B: Using SFTP client (FileZilla, WinSCP, etc.)**
- Connect to: YOUR_SERVER_IP
- Username: root
- Password: [your password]
- Upload the .tar.gz file to /root/

**Option C: Using rsync**
```bash
rsync -avz cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

### 2. SSH into Server

```bash
ssh root@YOUR_SERVER_IP
# Enter your password when prompted
```

### 3. Extract and Deploy

```bash
# Extract the package
tar -xzf cyber-defense-*.tar.gz

# Enter directory
cd cyber-defense

# Run deployment script
chmod +x deploy-on-hetzner.sh
./deploy-on-hetzner.sh
```

That's it! The script will:
- Install Docker and Docker Compose
- Configure the firewall
- Start all services
- Download the Qwen model

### 4. Access Your Application

After deployment completes (2-3 minutes):

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Verify Deployment

```bash
# Check all services are running
docker-compose ps

# Check Qwen model is loaded
docker exec ollama-qwen ollama list

# Test agent
curl http://localhost:8000/health | jq
```

## Common Commands

```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Update and restart
docker-compose down
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Services won't start
```bash
# Check Docker status
systemctl status docker

# View logs
docker-compose logs
```

### Can't access from browser
```bash
# Check firewall
ufw status

# Allow port if needed
ufw allow 3000/tcp
```

### Model not loading
```bash
# Pull model manually
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# Check logs
docker logs ollama-init
```

## Server Requirements

**Minimum:**
- 2 vCPUs
- 4 GB RAM
- 20 GB disk

**Recommended:**
- 4 vCPUs
- 8 GB RAM
- 40 GB disk

**Hetzner Server Types:**
- **CPX21** (3 vCPU, 4GB RAM, €9/mo) - Minimum
- **CPX31** (4 vCPU, 8GB RAM, €19/mo) - Recommended
- **CPX41** (8 vCPU, 16GB RAM, €35/mo) - Best performance

## Security Notes

After deployment, consider:

1. **Change default database password** in docker-compose.yml
2. **Set up SSL/TLS** for production use
3. **Restrict firewall** to only needed IPs
4. **Enable automatic updates**

```bash
# Change database password
nano docker-compose.yml
# Edit POSTGRES_PASSWORD
docker-compose down
docker-compose up -d
```

## Need Help?

See the included README.md for full documentation.
DEPLOY_README

# Create quick start guide
cat > "$DEPLOY_DIR/QUICK_START.txt" << 'QUICKSTART'
╔════════════════════════════════════════════════════════╗
║  QUICK START - Hetzner Deployment                     ║
╚════════════════════════════════════════════════════════╝

1. Upload this package to your Hetzner server:
   scp cyber-defense-*.tar.gz root@YOUR_IP:/root/

2. SSH to your server:
   ssh root@YOUR_IP

3. Extract and deploy:
   tar -xzf cyber-defense-*.tar.gz
   cd cyber-defense
   ./deploy-on-hetzner.sh

4. Wait 2-3 minutes, then access:
   http://YOUR_IP:3000  (Dashboard)
   http://YOUR_IP:8000  (API)

Done! 🎉

For detailed instructions, see DEPLOY_README.md
QUICKSTART

echo "  → Created deployment script"
echo "  → Created deployment README"
echo ""

# Create the tar.gz
echo "🗜️  Creating archive..."
cd "$TEMP_DIR"
tar -czf "/workspace/$PACKAGE_NAME" cyber-defense/

# Cleanup
rm -rf "$TEMP_DIR"

# Get file size
SIZE=$(du -h "/workspace/$PACKAGE_NAME" | cut -f1)

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "✅ ${GREEN}Deployment package created!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📦 Package: $PACKAGE_NAME"
echo "📏 Size: $SIZE"
echo "📍 Location: /workspace/$PACKAGE_NAME"
echo ""
echo "📤 Upload to Hetzner:"
echo ""
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "   Or use FileZilla/WinSCP:"
echo "     Host: YOUR_SERVER_IP"
echo "     User: root"
echo "     Password: [your password]"
echo ""
echo "🚀 Deploy on server:"
echo ""
echo "   ssh root@YOUR_SERVER_IP"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense"
echo "   ./deploy-on-hetzner.sh"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "📚 See cyber-defense/DEPLOY_README.md for full instructions"
echo ""

# Show next steps
cat << 'NEXTSTEPS'
🎯 NEXT STEPS:

1. Upload package to your Hetzner server (root@YOUR_IP)
   
2. Extract: tar -xzf cyber-defense-*.tar.gz
   
3. Deploy: cd cyber-defense && ./deploy-on-hetzner.sh
   
4. Access: http://YOUR_IP:3000

NEXTSTEPS

