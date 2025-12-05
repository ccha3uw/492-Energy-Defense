#!/bin/bash
# Deploy to Hetzner Server from Local Machine
# Usage: ./deploy-to-hetzner.sh <SERVER_IP> [SSH_USER]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Deploy 492-Energy-Defense to Hetzner                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Server IP required${NC}"
    echo ""
    echo "Usage: ./deploy-to-hetzner.sh <SERVER_IP> [SSH_USER]"
    echo ""
    echo "Examples:"
    echo "  ./deploy-to-hetzner.sh 65.21.123.45"
    echo "  ./deploy-to-hetzner.sh 65.21.123.45 root"
    echo ""
    exit 1
fi

SERVER_IP="$1"
SSH_USER="${2:-cyber}"

echo "Target Server: $SERVER_IP"
echo "SSH User: $SSH_USER"
echo ""

# Test SSH connection
echo -e "${YELLOW}[1/7] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$SERVER_IP exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check server IP is correct: $SERVER_IP"
    echo "2. Ensure SSH key is added: ssh-copy-id $SSH_USER@$SERVER_IP"
    echo "3. Verify server is running"
    echo ""
    exit 1
fi
echo ""

# Create deployment archive
echo -e "${YELLOW}[2/7] Creating deployment archive...${NC}"
tar -czf /tmp/cyber-deploy.tar.gz \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env' \
    --exclude='node_modules' \
    -C "$(pwd)" .
echo -e "${GREEN}✓ Archive created${NC}"
echo ""

# Upload archive
echo -e "${YELLOW}[3/7] Uploading files to server...${NC}"
scp -q /tmp/cyber-deploy.tar.gz $SSH_USER@$SERVER_IP:/tmp/
echo -e "${GREEN}✓ Files uploaded${NC}"
echo ""

# Extract on server
echo -e "${YELLOW}[4/7] Extracting files on server...${NC}"
ssh $SSH_USER@$SERVER_IP << 'ENDSSH'
cd ~/492-energy-defense
tar -xzf /tmp/cyber-deploy.tar.gz
rm /tmp/cyber-deploy.tar.gz
echo "Files extracted"
ENDSSH
echo -e "${GREEN}✓ Files extracted${NC}"
echo ""

# Build and start services
echo -e "${YELLOW}[5/7] Building Docker images...${NC}"
ssh $SSH_USER@$SERVER_IP << 'ENDSSH'
cd ~/492-energy-defense
docker compose build --quiet
echo "Images built"
ENDSSH
echo -e "${GREEN}✓ Images built${NC}"
echo ""

echo -e "${YELLOW}[6/7] Starting services...${NC}"
ssh $SSH_USER@$SERVER_IP << 'ENDSSH'
cd ~/492-energy-defense
docker compose up -d
echo "Services started"
ENDSSH
echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Wait for services
echo -e "${YELLOW}[7/7] Waiting for services to initialize...${NC}"
echo "This may take 2-3 minutes for model download..."
sleep 10

# Check health
echo ""
echo "Checking service health..."
if curl -f -s http://$SERVER_IP:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Agent API is responding${NC}"
else
    echo -e "${YELLOW}⚠ Agent API not yet ready (may still be initializing)${NC}"
fi

if curl -f -s http://$SERVER_IP:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Dashboard is responding${NC}"
else
    echo -e "${YELLOW}⚠ Dashboard not yet ready (may still be initializing)${NC}"
fi
echo ""

# Cleanup
rm -f /tmp/cyber-deploy.tar.gz

echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Access your services:"
echo "   Dashboard:  http://$SERVER_IP:3000"
echo "   Agent API:  http://$SERVER_IP:8000"
echo "   API Docs:   http://$SERVER_IP:8000/docs"
echo ""
echo "📊 Useful commands:"
echo "   SSH to server:      ssh $SSH_USER@$SERVER_IP"
echo "   View logs:          ssh $SSH_USER@$SERVER_IP 'cd ~/492-energy-defense && docker compose logs -f'"
echo "   Check status:       ssh $SSH_USER@$SERVER_IP 'cd ~/492-energy-defense && docker compose ps'"
echo "   Stop services:      ssh $SSH_USER@$SERVER_IP 'cd ~/492-energy-defense && docker compose down'"
echo ""
echo "⏱️  Note: Model download may take 2-3 more minutes."
echo "   Monitor: ssh $SSH_USER@$SERVER_IP 'docker logs -f ollama-init'"
echo ""
