#!/bin/bash
# One-Command Deployment to Hetzner
# Run this from your LOCAL machine

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - One-Command Hetzner Deployment  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get server IP
echo -e "${YELLOW}Enter your Hetzner server IP address:${NC}"
read -p "IP: " SERVER_IP

# Get SSH user
echo -e "${YELLOW}Enter SSH username (default: root):${NC}"
read -p "User: " SSH_USER
SSH_USER=${SSH_USER:-root}

echo ""
echo "Configuration:"
echo "  Server IP: $SERVER_IP"
echo "  SSH User:  $SSH_USER"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 1: Setting up server"
echo "════════════════════════════════════════════════════════"
echo ""

# Test SSH
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$SERVER_IP exit 2>/dev/null; then
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Setting up SSH key..."
    ssh-copy-id $SSH_USER@$SERVER_IP
fi

# Transfer setup script
echo "Transferring setup script..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
scp $SCRIPT_DIR/setup-hetzner-server.sh $SSH_USER@$SERVER_IP:/tmp/

# Run setup
echo "Running server setup (this takes 3-5 minutes)..."
ssh $SSH_USER@$SERVER_IP "bash /tmp/setup-hetzner-server.sh"

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 2: Deploying application"
echo "════════════════════════════════════════════════════════"
echo ""

# Run deployment
bash $SCRIPT_DIR/deploy-to-hetzner.sh $SERVER_IP cyber

echo ""
echo "════════════════════════════════════════════════════════"
echo "STEP 3: Verification"
echo "════════════════════════════════════════════════════════"
echo ""

sleep 5

echo "Checking service health..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:8000/health)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Agent API is responding${NC}"
else
    echo -e "${YELLOW}⚠ Agent API not ready yet (may still be initializing)${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "🌐 Access URLs:"
echo "   Dashboard:  http://$SERVER_IP:3000"
echo "   Agent API:  http://$SERVER_IP:8000"
echo "   API Docs:   http://$SERVER_IP:8000/docs"
echo ""
echo "📊 Monitor logs:"
echo "   ssh cyber@$SERVER_IP 'cd app && docker compose logs -f'"
echo ""
echo "🔐 Security:"
echo "   • Firewall is enabled (UFW)"
echo "   • Only ports 22, 3000, 8000, 5432 are open"
echo "   • Change default passwords in .env file!"
echo ""
echo "📚 Documentation:"
echo "   ssh cyber@$SERVER_IP 'cd app && cat README.md'"
echo ""
