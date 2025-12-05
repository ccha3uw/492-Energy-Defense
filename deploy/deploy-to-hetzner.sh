#!/bin/bash
# Deploy 492-Energy-Defense to Hetzner Server
# Run this FROM your LOCAL machine

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deploy 492-Energy-Defense to Hetzner                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get server IP
if [ -z "$1" ]; then
    echo -e "${YELLOW}Enter your Hetzner server IP address:${NC}"
    read -p "IP: " SERVER_IP
else
    SERVER_IP="$1"
fi

# Get username (default: cyber)
if [ -z "$2" ]; then
    USERNAME="cyber"
else
    USERNAME="$2"
fi

echo ""
echo "Target server: $SERVER_IP"
echo "Username: $USERNAME"
echo ""

# Verify SSH connection
echo -e "${YELLOW}[1/7] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes $USERNAME@$SERVER_IP exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if server IP is correct: $SERVER_IP"
    echo "2. Make sure SSH key is added to server"
    echo "3. Try manually: ssh $USERNAME@$SERVER_IP"
    echo ""
    echo "To add your SSH key:"
    echo "  ssh-copy-id $USERNAME@$SERVER_IP"
    exit 1
fi
echo ""

# Create deployment package
echo -e "${YELLOW}[2/7] Creating deployment package...${NC}"
TEMP_DIR=$(mktemp -d)
cd "$(dirname "$0")/.."

# Copy necessary files
cp -r agent backend dashboard deploy $TEMP_DIR/
cp docker-compose.yml docker-compose-simple.yml $TEMP_DIR/
cp .env.example README.md $TEMP_DIR/
cp *.sh $TEMP_DIR/ 2>/dev/null || true

# Create tarball
cd $TEMP_DIR
tar -czf /tmp/cyber-defense-deploy.tar.gz .
cd - > /dev/null
echo -e "${GREEN}✓ Package created${NC}"
echo ""

# Transfer to server
echo -e "${YELLOW}[3/7] Transferring files to server...${NC}"
scp /tmp/cyber-defense-deploy.tar.gz $USERNAME@$SERVER_IP:/home/$USERNAME/
echo -e "${GREEN}✓ Files transferred${NC}"
echo ""

# Extract on server
echo -e "${YELLOW}[4/7] Extracting files on server...${NC}"
ssh $USERNAME@$SERVER_IP << 'ENDSSH'
cd ~
rm -rf app
mkdir -p app
cd app
tar -xzf ../cyber-defense-deploy.tar.gz
rm ../cyber-defense-deploy.tar.gz
chmod +x *.sh 2>/dev/null || true
echo "✓ Files extracted"
ENDSSH
echo -e "${GREEN}✓ Extraction complete${NC}"
echo ""

# Setup environment
echo -e "${YELLOW}[5/7] Configuring environment...${NC}"
ssh $USERNAME@$SERVER_IP << 'ENDSSH'
cd ~/app
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Environment file created"
fi
ENDSSH
echo -e "${GREEN}✓ Environment configured${NC}"
echo ""

# Start services
echo -e "${YELLOW}[6/7] Starting Docker services...${NC}"
echo "This will take 3-5 minutes (downloading Qwen model)..."
ssh $USERNAME@$SERVER_IP << 'ENDSSH'
cd ~/app
docker compose down 2>/dev/null || true
docker compose up -d
echo "✓ Services started"
ENDSSH
echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Wait for services
echo -e "${YELLOW}[7/7] Waiting for services to be ready...${NC}"
echo "Waiting for model download and initialization..."
sleep 10

# Check if services are running
ssh $USERNAME@$SERVER_IP << 'ENDSSH'
cd ~/app
echo "Checking service status..."
docker compose ps
ENDSSH

echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""

# Cleanup
rm -f /tmp/cyber-defense-deploy.tar.gz
rm -rf $TEMP_DIR

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}🎉 Deployment Successful!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Access your services:"
echo "   • Dashboard:  http://$SERVER_IP:3000"
echo "   • Agent API:  http://$SERVER_IP:8000"
echo "   • API Docs:   http://$SERVER_IP:8000/docs"
echo ""
echo "🔍 Monitor deployment:"
echo "   ssh $USERNAME@$SERVER_IP 'cd app && docker compose logs -f'"
echo ""
echo "📝 Useful commands:"
echo "   • Check status:  ssh $USERNAME@$SERVER_IP 'cd app && docker compose ps'"
echo "   • View logs:     ssh $USERNAME@$SERVER_IP 'cd app && docker compose logs -f agent'"
echo "   • Restart:       ssh $USERNAME@$SERVER_IP 'cd app && docker compose restart'"
echo "   • Stop:          ssh $USERNAME@$SERVER_IP 'cd app && docker compose down'"
echo ""
echo "⚠️  Note: Model download may still be in progress."
echo "    Check with: ssh $USERNAME@$SERVER_IP 'docker logs ollama-init'"
echo ""
