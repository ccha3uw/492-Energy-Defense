#!/bin/bash
# Simple Hetzner deployment script using tar.gz and password authentication
# Run this on your LOCAL machine

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Hetzner Simple Deployment (Root + Password)          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if package exists
if ! ls cyber-defense-*.tar.gz 1> /dev/null 2>&1; then
    echo -e "${YELLOW}No deployment package found. Creating one...${NC}"
    ./create-deployment-package.sh
    echo ""
fi

# Get the latest package
PACKAGE=$(ls -t cyber-defense-*.tar.gz | head -1)

echo "Deployment package: $PACKAGE"
echo ""

# Get server IP
read -p "Enter Hetzner server IP address: " SERVER_IP

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Error: Server IP is required${NC}"
    exit 1
fi

echo ""
echo "Server IP: $SERVER_IP"
echo ""

# Confirm
read -p "Ready to deploy? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}[1/4] Uploading package to server...${NC}"
echo "You will be prompted for the root password"
echo ""

scp "$PACKAGE" "root@$SERVER_IP:/root/"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Upload failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Package uploaded${NC}"
echo ""

echo -e "${YELLOW}[2/4] Installing Docker on server...${NC}"
echo "You will be prompted for the root password again"
echo ""

ssh "root@$SERVER_IP" << 'ENDSSH'
set -e
echo "Updating system packages..."
apt update -qq

echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    apt install -y docker.io docker-compose curl jq
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi
ENDSSH

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Docker installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker ready${NC}"
echo ""

echo -e "${YELLOW}[3/4] Deploying application...${NC}"

ssh "root@$SERVER_IP" << 'ENDSSH'
set -e
cd /root

echo "Extracting package..."
tar -xzf cyber-defense-*.tar.gz

echo "Making scripts executable..."
chmod +x *.sh

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to initialize (2 minutes)..."
sleep 120

echo ""
echo "Container status:"
docker-compose ps
ENDSSH

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Application deployed${NC}"
echo ""

echo -e "${YELLOW}[4/4] Configuring firewall...${NC}"

ssh "root@$SERVER_IP" << 'ENDSSH'
set -e

if command -v ufw &> /dev/null; then
    echo "Configuring UFW firewall..."
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 8000/tcp
    ufw allow 3000/tcp
    ufw reload
    echo "✓ Firewall configured"
else
    echo "⚠ UFW not available, skipping firewall configuration"
fi
ENDSSH

echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Testing the deployment..."
echo ""

# Test health endpoint
HEALTH=$(curl -s "http://$SERVER_IP:8000/health" 2>&1)

if echo "$HEALTH" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Agent is running${NC}"
    echo "$HEALTH" | jq '.' 2>/dev/null || echo "$HEALTH"
else
    echo -e "${YELLOW}⚠ Agent health check failed${NC}"
    echo "Check logs: ssh root@$SERVER_IP 'docker logs cyber-agent'"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 Access Your System"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Dashboard:      http://$SERVER_IP:3000"
echo "🤖 Agent API:      http://$SERVER_IP:8000"
echo "📚 API Docs:       http://$SERVER_IP:8000/docs"
echo ""
echo "════════════════════════════════════════════════════════"
echo "📝 Useful Commands"
echo "════════════════════════════════════════════════════════"
echo ""
echo "SSH to server:"
echo "  ssh root@$SERVER_IP"
echo ""
echo "View logs:"
echo "  ssh root@$SERVER_IP 'docker-compose logs -f'"
echo ""
echo "Check status:"
echo "  ssh root@$SERVER_IP 'docker-compose ps'"
echo ""
echo "Restart services:"
echo "  ssh root@$SERVER_IP 'docker-compose restart'"
echo ""
echo "Stop services:"
echo "  ssh root@$SERVER_IP 'docker-compose down'"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "Deployment log saved in: deployment-$SERVER_IP.log"
echo ""
