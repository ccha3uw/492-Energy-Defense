#!/bin/bash
# Hetzner Deployment Script - Run this ON the Hetzner server

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - Hetzner Deployment             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Updating system...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${YELLOW}[2/5] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Start Docker
    systemctl start docker
    systemctl enable docker

    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[3/5] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y -qq docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[4/5] Installing additional tools...${NC}"
apt-get install -y -qq curl jq htop net-tools
echo -e "${GREEN}✓ Tools installed${NC}"
echo ""

echo -e "${YELLOW}[5/5] Starting application...${NC}"
# Build and start containers
docker-compose build
docker-compose up -d

echo -e "${GREEN}✓ Containers starting${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Waiting for services to initialize...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Waiting for database..."
sleep 10
echo -e "${GREEN}✓ Database ready${NC}"
echo ""

echo "Waiting for Ollama (this may take 2-3 minutes to download Qwen model)..."
echo "You can monitor progress with: docker logs -f ollama-init"
echo ""

# Wait up to 5 minutes for model download
for i in {1..60}; do
    if docker logs ollama-init 2>&1 | grep -q "model ready\|success"; then
        echo -e "${GREEN}✓ Qwen model downloaded${NC}"
        break
    fi
    sleep 5
    echo -n "."
done
echo ""
echo ""

echo "Waiting for agent..."
sleep 15
echo -e "${GREEN}✓ Agent ready${NC}"
echo ""

# Get server IP
SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || hostname -I | awk '{print $1}')

echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT COMPLETE                                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Your server IP: $SERVER_IP"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SERVICE ENDPOINTS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Dashboard:   http://$SERVER_IP:3000"
echo "  Agent API:   http://$SERVER_IP:8000"
echo "  API Docs:    http://$SERVER_IP:8000/docs"
echo "  Database:    $SERVER_IP:5432"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "USEFUL COMMANDS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  View logs:           docker-compose logs -f"
echo "  Check status:        docker-compose ps"
echo "  Restart services:    docker-compose restart"
echo "  Stop services:       docker-compose down"
echo ""
echo "  Agent logs:          docker logs -f cyber-agent"
echo "  Backend logs:        docker logs -f cyber-backend"
echo "  Dashboard logs:      docker logs -f cyber-dashboard"
echo ""
echo "  Check health:        curl http://localhost:8000/health"
echo "  Run tests:           ./test-llm-mode.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FIREWALL SETUP (IMPORTANT):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To access from your computer, configure firewall:"
echo ""
echo "  1. Using UFW (recommended):"
echo "     ufw allow 22/tcp    # SSH"
echo "     ufw allow 3000/tcp  # Dashboard"
echo "     ufw allow 8000/tcp  # Agent API"
echo "     ufw enable"
echo ""
echo "  2. Or use Hetzner Cloud Console:"
echo "     - Go to your server in Hetzner Console"
echo "     - Click 'Firewalls' tab"
echo "     - Add rules for ports 22, 3000, 8000"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Configure firewall (see above)"
echo "2. Open http://$SERVER_IP:3000 in your browser"
echo "3. Monitor logs: docker-compose logs -f"
echo "4. Events generate every 30 minutes automatically"
echo ""
echo "🎉 System is running!"
echo ""
