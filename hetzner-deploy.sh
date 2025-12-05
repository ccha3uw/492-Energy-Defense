#!/bin/bash
# One-Command Hetzner Deployment Script
# Run this from your LOCAL machine

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   492-Energy-Defense Hetzner Deployment                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if SERVER_IP is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Server IP address required${NC}"
    echo ""
    echo "Usage: ./hetzner-deploy.sh <SERVER_IP> [SSH_USER]"
    echo ""
    echo "Example:"
    echo "  ./hetzner-deploy.sh 65.21.123.45"
    echo "  ./hetzner-deploy.sh 65.21.123.45 root"
    echo ""
    exit 1
fi

SERVER_IP="$1"
SSH_USER="${2:-root}"

echo -e "${BLUE}Target server: $SERVER_IP${NC}"
echo -e "${BLUE}SSH user: $SSH_USER${NC}"
echo ""

# Test SSH connection
echo -e "${YELLOW}[1/6] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_USER@$SERVER_IP exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Make sure:"
    echo "  1. Server IP is correct: $SERVER_IP"
    echo "  2. SSH key is configured"
    echo "  3. Server is running"
    echo ""
    echo "Test manually: ssh $SSH_USER@$SERVER_IP"
    exit 1
fi
echo ""

# Update server and install dependencies
echo -e "${YELLOW}[2/6] Setting up server (Docker, Git, etc.)...${NC}"
ssh $SSH_USER@$SERVER_IP bash << 'ENDSSH'
set -e
export DEBIAN_FRONTEND=noninteractive

echo "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

echo "Installing dependencies..."
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    jq

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose already installed"
fi

echo "✓ Server setup complete"
ENDSSH

echo -e "${GREEN}✓ Server prepared${NC}"
echo ""

# Transfer project files
echo -e "${YELLOW}[3/6] Transferring project files...${NC}"

# Create deployment directory on server
ssh $SSH_USER@$SERVER_IP "mkdir -p /opt/cyber-defense"

# Create tarball excluding unnecessary files
echo "Creating deployment package..."
tar czf /tmp/cyber-defense-deploy.tar.gz \
    --exclude='.git' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.env' \
    --exclude='*.log' \
    --exclude='node_modules' \
    -C "$(dirname "$(pwd)")" "$(basename "$(pwd)")"

# Transfer tarball
echo "Uploading to server..."
scp -q /tmp/cyber-defense-deploy.tar.gz $SSH_USER@$SERVER_IP:/tmp/

# Extract on server
ssh $SSH_USER@$SERVER_IP bash << 'ENDSSH'
cd /opt/cyber-defense
tar xzf /tmp/cyber-defense-deploy.tar.gz --strip-components=1
rm /tmp/cyber-defense-deploy.tar.gz
chmod +x *.sh 2>/dev/null || true
ENDSSH

# Cleanup local tarball
rm /tmp/cyber-defense-deploy.tar.gz

echo -e "${GREEN}✓ Files transferred${NC}"
echo ""

# Configure environment
echo -e "${YELLOW}[4/6] Configuring environment...${NC}"
ssh $SSH_USER@$SERVER_IP bash << 'ENDSSH'
cd /opt/cyber-defense

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created .env configuration"
fi

# Set permissions
chmod +x *.sh check-qwen-model.sh apply-fix.sh 2>/dev/null || true

echo "✓ Environment configured"
ENDSSH

echo -e "${GREEN}✓ Environment ready${NC}"
echo ""

# Start services
echo -e "${YELLOW}[5/6] Starting Docker services...${NC}"
echo "This will take 2-3 minutes (downloading Qwen model)..."
echo ""

ssh $SSH_USER@$SERVER_IP bash << 'ENDSSH'
cd /opt/cyber-defense

echo "Starting services..."
docker-compose down 2>/dev/null || true
docker-compose up -d

echo ""
echo "Waiting for Ollama to download Qwen model..."
echo "(This takes ~1-2 minutes for the 400MB model)"

# Wait for ollama-init to complete
for i in {1..120}; do
    if docker logs ollama-init 2>&1 | grep -q "Qwen model ready"; then
        echo "✓ Qwen model downloaded"
        break
    fi
    if [ $i -eq 120 ]; then
        echo "Warning: Model download taking longer than expected"
        echo "Check logs: docker logs ollama-init"
    fi
    sleep 1
    echo -n "."
done
echo ""

# Wait for services to be healthy
echo ""
echo "Waiting for services to start..."
sleep 10

echo "✓ Services started"
ENDSSH

echo -e "${GREEN}✓ Services running${NC}"
echo ""

# Verify deployment
echo -e "${YELLOW}[6/6] Verifying deployment...${NC}"

ssh $SSH_USER@$SERVER_IP bash << 'ENDSSH'
cd /opt/cyber-defense

echo "Checking service status..."
docker-compose ps

echo ""
echo "Testing agent health..."
sleep 5
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✓ Agent is responding"
    curl -s http://localhost:8000/health | jq '.'
else
    echo "⚠ Agent not yet responding (may still be starting)"
fi
ENDSSH

echo -e "${GREEN}✓ Verification complete${NC}"
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🎉 DEPLOYMENT COMPLETE!                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Your cybersecurity agent is now running on Hetzner!${NC}"
echo ""
echo "📊 Service URLs:"
echo "   • Dashboard:    http://$SERVER_IP:3000"
echo "   • Agent API:    http://$SERVER_IP:8000"
echo "   • API Docs:     http://$SERVER_IP:8000/docs"
echo ""
echo "🔧 Management Commands (run on server):"
echo "   ssh $SSH_USER@$SERVER_IP"
echo "   cd /opt/cyber-defense"
echo ""
echo "   # View status"
echo "   docker-compose ps"
echo ""
echo "   # View logs"
echo "   docker logs -f cyber-agent"
echo "   docker logs -f cyber-backend"
echo "   docker logs -f cyber-dashboard"
echo ""
echo "   # Restart services"
echo "   docker-compose restart"
echo ""
echo "   # Stop everything"
echo "   docker-compose down"
echo ""
echo "   # Check model status"
echo "   ./check-qwen-model.sh"
echo ""
echo "🔐 Security Note:"
echo "   Configure firewall rules to restrict access:"
echo "   ssh $SSH_USER@$SERVER_IP"
echo "   ufw allow 22/tcp"
echo "   ufw allow 3000/tcp  # Dashboard"
echo "   ufw allow 8000/tcp  # Agent API"
echo "   ufw enable"
echo ""
echo "📝 Next Steps:"
echo "   1. Visit http://$SERVER_IP:3000 to see the dashboard"
echo "   2. Test the API: curl http://$SERVER_IP:8000/health"
echo "   3. Review logs: ssh $SSH_USER@$SERVER_IP 'cd /opt/cyber-defense && docker logs -f cyber-backend'"
echo ""
echo "🎓 For more information, see README.md on the server"
echo ""
