#!/bin/bash
# Create deployment package for Hetzner

echo "════════════════════════════════════════════════════════"
echo "  Creating Deployment Package for Hetzner"
echo "════════════════════════════════════════════════════════"
echo ""

# Package name
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Packaging files..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
PROJECT_DIR="$TEMP_DIR/cyber-defense"
mkdir -p "$PROJECT_DIR"

# Copy necessary files (exclude .git, docs, etc.)
echo "Copying project files..."
rsync -av --progress \
  --exclude='.git' \
  --exclude='*.md' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.env' \
  --exclude='venv' \
  --exclude='node_modules' \
  --include='README.md' \
  ./ "$PROJECT_DIR/"

# Create deployment script
cat > "$PROJECT_DIR/deploy.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
# Hetzner Deployment Script - Run this on your server

set -e

echo "════════════════════════════════════════════════════════"
echo "  492-Energy-Defense - Hetzner Deployment"
echo "════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}[1/6] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[2/6] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[3/6] Setting up firewall...${NC}"
if command -v ufw &> /dev/null; then
    echo "Configuring UFW firewall..."
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp
    ufw allow 8000/tcp
    echo -e "${GREEN}✓ Firewall configured${NC}"
else
    echo -e "${YELLOW}⚠ UFW not installed, skipping firewall setup${NC}"
fi
echo ""

echo -e "${YELLOW}[4/6] Building Docker images...${NC}"
docker-compose build
echo -e "${GREEN}✓ Images built${NC}"
echo ""

echo -e "${YELLOW}[5/6] Starting services...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

echo -e "${YELLOW}[6/6] Waiting for services to initialize...${NC}"
echo "This may take 1-2 minutes (downloading Qwen model)..."
sleep 20

# Wait for database
echo "Waiting for database..."
until docker-compose exec -T db pg_isready -U postgres &>/dev/null; do
    sleep 2
done
echo -e "${GREEN}✓ Database ready${NC}"

# Wait for agent
echo "Waiting for agent..."
until curl -s http://localhost:8000/health &>/dev/null; do
    sleep 2
done
echo -e "${GREEN}✓ Agent ready${NC}"

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✅ Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Your system is now running!"
echo ""
echo "📊 Access Points:"
echo "  • Dashboard:  http://$(curl -s ifconfig.me):3000"
echo "  • Agent API:  http://$(curl -s ifconfig.me):8000"
echo "  • API Docs:   http://$(curl -s ifconfig.me):8000/docs"
echo ""
echo "🔍 Useful Commands:"
echo "  • Check status:    docker-compose ps"
echo "  • View logs:       docker-compose logs -f"
echo "  • Stop system:     docker-compose down"
echo "  • Restart system:  docker-compose restart"
echo ""
echo "📝 Next Steps:"
echo "  1. Test agent: curl http://localhost:8000/health | jq"
echo "  2. Open dashboard in browser"
echo "  3. Monitor logs: docker-compose logs -f cyber-agent"
echo ""
DEPLOY_SCRIPT

chmod +x "$PROJECT_DIR/deploy.sh"

# Create README for deployment
cat > "$PROJECT_DIR/DEPLOY_README.txt" << 'DEPLOY_README'
════════════════════════════════════════════════════════
  492-Energy-Defense - Hetzner Deployment Package
════════════════════════════════════════════════════════

QUICK START:

1. Upload this tar.gz file to your Hetzner server
2. Extract it
3. Run the deployment script
4. Access your dashboard

════════════════════════════════════════════════════════

STEP-BY-STEP INSTRUCTIONS:

1. UPLOAD TO SERVER (from your local machine):

   scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/

2. LOGIN TO SERVER:

   ssh root@YOUR_SERVER_IP

3. EXTRACT:

   cd /root
   tar -xzf cyber-defense-*.tar.gz
   cd cyber-defense

4. DEPLOY:

   chmod +x deploy.sh
   ./deploy.sh

   Wait 1-2 minutes for initialization.

5. ACCESS:

   Dashboard: http://YOUR_SERVER_IP:3000
   API:       http://YOUR_SERVER_IP:8000/docs

════════════════════════════════════════════════════════

REQUIREMENTS:

• Ubuntu 20.04+ or Debian 11+
• 4GB+ RAM (8GB recommended)
• 20GB+ disk space
• Root access

════════════════════════════════════════════════════════

TROUBLESHOOTING:

Check logs:
  docker-compose logs -f

Check status:
  docker-compose ps

Restart:
  docker-compose restart

Stop:
  docker-compose down

Fresh start:
  docker-compose down -v
  ./deploy.sh

════════════════════════════════════════════════════════

WHAT GETS INSTALLED:

✓ Docker & Docker Compose
✓ PostgreSQL database
✓ Ollama with Qwen AI model
✓ FastAPI agent service
✓ Web dashboard
✓ Firewall rules (ports 22, 80, 443, 3000, 8000)

════════════════════════════════════════════════════════
DEPLOY_README

# Create quick reference card
cat > "$PROJECT_DIR/COMMANDS.txt" << 'COMMANDS'
Quick Reference - Useful Commands
════════════════════════════════════════════════════════

START/STOP:
  docker-compose up -d          Start all services
  docker-compose down           Stop all services
  docker-compose restart        Restart all services

STATUS:
  docker-compose ps             Show container status
  docker ps                     Show running containers

LOGS:
  docker-compose logs -f        All logs (follow)
  docker logs cyber-agent -f    Agent logs
  docker logs cyber-backend -f  Backend logs
  docker logs ollama-qwen -f    Ollama logs

HEALTH CHECKS:
  curl http://localhost:8000/health | jq
  curl http://localhost:3000/health | jq

DATABASE:
  docker exec -it cyber-events-db psql -U postgres -d cyber_events

MODEL:
  docker exec ollama-qwen ollama list
  docker exec ollama-qwen ollama pull qwen2.5:0.5b

MAINTENANCE:
  docker-compose pull           Update images
  docker-compose build          Rebuild containers
  docker system prune -a        Clean up disk space

FIREWALL (UFW):
  ufw status                    Check firewall status
  ufw allow 8000/tcp            Allow port
  ufw delete allow 8000/tcp     Remove rule

════════════════════════════════════════════════════════
COMMANDS

echo "Creating tarball..."
cd "$TEMP_DIR"
tar -czf "$PACKAGE_NAME" cyber-defense/
mv "$PACKAGE_NAME" "$OLDPWD/"
cd "$OLDPWD"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}✅ Package created: $PACKAGE_NAME${NC}"
echo ""
echo "File size: $(du -h "$PACKAGE_NAME" | cut -f1)"
echo ""
echo "════════════════════════════════════════════════════════"
echo "  NEXT STEPS:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. Upload to your Hetzner server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH to your server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense"
echo "   ./deploy.sh"
echo ""
echo "4. Access your dashboard:"
echo "   http://YOUR_SERVER_IP:3000"
echo ""

