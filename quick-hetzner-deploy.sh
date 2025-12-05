#!/bin/bash
# Interactive deployment helper for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Hetzner Quick Deploy Helper                         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if package exists
if [ ! -f "cyber-agent-deployment.tar.gz" ]; then
    echo -e "${YELLOW}Package not found. Creating deployment package...${NC}"
    ./create-deployment-package.sh
fi

echo ""
echo -e "${GREEN}Step 1: Package ready ✓${NC}"
echo "File: cyber-agent-deployment.tar.gz"
echo "Size: $(du -h cyber-agent-deployment.tar.gz | cut -f1)"
echo ""

# Get server IP
read -p "Enter your Hetzner server IP address: " SERVER_IP

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Error: Server IP is required${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Uploading to server...${NC}"
echo "You will be prompted for the root password"
echo ""

# Upload package
scp cyber-agent-deployment.tar.gz root@$SERVER_IP:~/

if [ $? -ne 0 ]; then
    echo -e "${RED}Upload failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Upload complete ✓${NC}"
echo ""

# Ask if user wants to auto-deploy
read -p "Do you want to automatically deploy now? (y/n): " AUTO_DEPLOY

if [ "$AUTO_DEPLOY" = "y" ] || [ "$AUTO_DEPLOY" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}Step 3: Deploying on server...${NC}"
    echo ""
    
    ssh root@$SERVER_IP << 'REMOTE_COMMANDS'
echo "Extracting package..."
tar -xzf cyber-agent-deployment.tar.gz
cd cyber-agent-deploy

echo ""
echo "Starting deployment..."
./deploy.sh

echo ""
echo "Setting up firewall..."
apt-get install -y ufw
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw --force enable

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                 ║"
echo "╚════════════════════════════════════════════════════════╝"
REMOTE_COMMANDS

    echo ""
    echo -e "${GREEN}Deployment successful! ✓${NC}"
    echo ""
    echo "Your application is now running at:"
    echo "  • Dashboard:  http://$SERVER_IP:3000"
    echo "  • Agent API:  http://$SERVER_IP:8000"
    echo "  • API Docs:   http://$SERVER_IP:8000/docs"
    echo ""
    echo "Test it now:"
    echo "  curl http://$SERVER_IP:8000/health"
    echo ""
else
    echo ""
    echo "Manual deployment instructions:"
    echo ""
    echo "1. SSH to your server:"
    echo "   ssh root@$SERVER_IP"
    echo ""
    echo "2. Extract and deploy:"
    echo "   tar -xzf cyber-agent-deployment.tar.gz"
    echo "   cd cyber-agent-deploy"
    echo "   ./deploy.sh"
    echo ""
    echo "3. Open firewall:"
    echo "   ufw allow 22/tcp"
    echo "   ufw allow 3000/tcp"
    echo "   ufw allow 8000/tcp"
    echo "   ufw --force enable"
    echo ""
    echo "4. Access your application:"
    echo "   http://$SERVER_IP:3000"
    echo ""
fi
