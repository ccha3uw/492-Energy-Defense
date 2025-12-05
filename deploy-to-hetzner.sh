#!/bin/bash
# One-command deployment script for Hetzner
# Usage: ./deploy-to-hetzner.sh <server-ip> [ssh-user]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - Hetzner Deployment                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Server IP address required${NC}"
    echo ""
    echo "Usage: ./deploy-to-hetzner.sh <SERVER_IP> [SSH_USER]"
    echo ""
    echo "Example:"
    echo "  ./deploy-to-hetzner.sh 65.21.123.45"
    echo "  ./deploy-to-hetzner.sh 65.21.123.45 root"
    echo ""
    exit 1
fi

SERVER_IP="$1"
SSH_USER="${2:-root}"
APP_DIR="/home/cyber/cyber-defense"

echo -e "${BLUE}Target Server:${NC} $SERVER_IP"
echo -e "${BLUE}SSH User:${NC} $SSH_USER"
echo -e "${BLUE}Install Directory:${NC} $APP_DIR"
echo ""

# Test SSH connection
echo -e "${YELLOW}[1/8] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=10 -o BatchMode=yes $SSH_USER@$SERVER_IP exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Please ensure:"
    echo "  1. Server IP is correct: $SERVER_IP"
    echo "  2. SSH key is configured"
    echo "  3. Server is running"
    echo ""
    echo "Test manually: ssh $SSH_USER@$SERVER_IP"
    exit 1
fi
echo ""

# Setup server (install Docker, create user, etc.)
echo -e "${YELLOW}[2/8] Setting up server environment...${NC}"
ssh $SSH_USER@$SERVER_IP 'bash -s' < ./deployment/server-setup.sh
echo -e "${GREEN}✓ Server environment ready${NC}"
echo ""

# Create app directory
echo -e "${YELLOW}[3/8] Creating application directory...${NC}"
ssh $SSH_USER@$SERVER_IP "mkdir -p $APP_DIR"
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

# Copy project files
echo -e "${YELLOW}[4/8] Copying project files...${NC}"
rsync -avz --exclude='.git' \
           --exclude='__pycache__' \
           --exclude='*.pyc' \
           --exclude='.env' \
           --exclude='venv' \
           --exclude='node_modules' \
           ./ $SSH_USER@$SERVER_IP:$APP_DIR/
echo -e "${GREEN}✓ Files copied${NC}"
echo ""

# Set permissions
echo -e "${YELLOW}[5/8] Setting permissions...${NC}"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && chmod +x *.sh && chown -R cyber:cyber $APP_DIR"
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Pull Docker images and build
echo -e "${YELLOW}[6/8] Building Docker images...${NC}"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose build"
echo -e "${GREEN}✓ Images built${NC}"
echo ""

# Start services
echo -e "${YELLOW}[7/8] Starting services...${NC}"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose up -d"
echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Wait for services to be ready
echo -e "${YELLOW}[8/8] Waiting for services to initialize...${NC}"
echo "This may take 2-3 minutes while the Qwen model downloads..."
sleep 30

# Check service status
echo ""
echo -e "${YELLOW}Checking service health...${NC}"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose ps"
echo ""

# Display access information
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  🎉 Deployment Complete!                                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Your cybersecurity agent is now running!${NC}"
echo ""
echo "📊 Access URLs:"
echo "   • Dashboard:    http://$SERVER_IP:3000"
echo "   • Agent API:    http://$SERVER_IP:8000"
echo "   • API Docs:     http://$SERVER_IP:8000/docs"
echo "   • Health Check: http://$SERVER_IP:8000/health"
echo ""
echo "🔒 Next Steps:"
echo "   1. Configure firewall (if needed):"
echo "      ssh $SSH_USER@$SERVER_IP 'ufw allow 3000/tcp && ufw allow 8000/tcp'"
echo ""
echo "   2. Watch the logs:"
echo "      ssh $SSH_USER@$SERVER_IP 'cd $APP_DIR && docker-compose logs -f'"
echo ""
echo "   3. Test the deployment:"
echo "      curl http://$SERVER_IP:8000/health | jq"
echo ""
echo "   4. Run tests:"
echo "      ssh $SSH_USER@$SERVER_IP 'cd $APP_DIR && ./test-llm-mode.sh'"
echo ""
echo "📝 Management Commands (on server):"
echo "   cd $APP_DIR"
echo "   docker-compose ps          # Check status"
echo "   docker-compose logs -f     # View logs"
echo "   docker-compose restart     # Restart all"
echo "   docker-compose down        # Stop all"
echo "   ./check-qwen-model.sh      # Verify model"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
