#!/bin/bash
# One-Command Deployment to Hetzner Server
# Usage: ./deploy-to-hetzner.sh <SERVER_IP> [SSH_USER]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     492-ENERGY-DEFENSE CYBERSECURITY AGENT                  ║
║     Automated Hetzner Deployment                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Server IP required${NC}"
    echo ""
    echo "Usage: $0 <SERVER_IP> [SSH_USER]"
    echo ""
    echo "Example:"
    echo "  $0 65.21.123.45"
    echo "  $0 65.21.123.45 cyber"
    echo ""
    exit 1
fi

SERVER_IP="$1"
SSH_USER="${2:-root}"

echo -e "${GREEN}Deployment Configuration:${NC}"
echo "  Server IP: $SERVER_IP"
echo "  SSH User:  $SSH_USER"
echo ""

# Test SSH connection
echo -e "${YELLOW}[1/7] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$SERVER_IP" exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Please ensure:"
    echo "  1. Server IP is correct: $SERVER_IP"
    echo "  2. SSH key is configured"
    echo "  3. User exists: $SSH_USER"
    echo ""
    echo "To add your SSH key:"
    echo "  ssh-copy-id $SSH_USER@$SERVER_IP"
    exit 1
fi
echo ""

# Create deployment package
echo -e "${YELLOW}[2/7] Creating deployment package...${NC}"
TEMP_DIR=$(mktemp -d)
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

# Copy project files (exclude .git and node_modules)
tar -czf "$TEMP_DIR/$PACKAGE_NAME" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.env' \
    -C "$(dirname "$0")" \
    .

echo -e "${GREEN}✓ Package created: $PACKAGE_NAME${NC}"
echo ""

# Upload deployment package
echo -e "${YELLOW}[3/7] Uploading to server...${NC}"
scp "$TEMP_DIR/$PACKAGE_NAME" "$SSH_USER@$SERVER_IP:/tmp/"
echo -e "${GREEN}✓ Upload complete${NC}"
echo ""

# Setup server and deploy
echo -e "${YELLOW}[4/7] Setting up server environment...${NC}"
ssh "$SSH_USER@$SERVER_IP" bash << REMOTE_SCRIPT
set -e

echo "Installing dependencies..."

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# Install required packages
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    ufw

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo "✓ Dependencies installed"
REMOTE_SCRIPT

echo -e "${GREEN}✓ Server setup complete${NC}"
echo ""

# Extract and deploy application
echo -e "${YELLOW}[5/7] Deploying application...${NC}"
ssh "$SSH_USER@$SERVER_IP" bash << REMOTE_SCRIPT
set -e

# Create deployment directory
DEPLOY_DIR="/opt/cyber-defense"
mkdir -p "\$DEPLOY_DIR"

# Extract package
cd "\$DEPLOY_DIR"
tar -xzf "/tmp/$PACKAGE_NAME"
rm "/tmp/$PACKAGE_NAME"

# Set permissions
chmod +x *.sh 2>/dev/null || true

echo "✓ Application deployed to \$DEPLOY_DIR"
REMOTE_SCRIPT

echo -e "${GREEN}✓ Application deployed${NC}"
echo ""

# Configure firewall
echo -e "${YELLOW}[6/7] Configuring firewall...${NC}"
ssh "$SSH_USER@$SERVER_IP" bash << REMOTE_SCRIPT
set -e

# Enable firewall if not already enabled
if ! ufw status | grep -q "Status: active"; then
    ufw --force enable
fi

# Allow SSH (prevent lockout)
ufw allow 22/tcp

# Allow application ports
ufw allow 8000/tcp   # Agent API
ufw allow 3000/tcp   # Dashboard
ufw allow 5432/tcp   # PostgreSQL (optional, for remote access)

echo "✓ Firewall configured"
REMOTE_SCRIPT

echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

# Start application
echo -e "${YELLOW}[7/7] Starting application...${NC}"
ssh "$SSH_USER@$SERVER_IP" bash << 'REMOTE_SCRIPT'
set -e

cd /opt/cyber-defense

# Start services
docker-compose down 2>/dev/null || true
docker-compose up -d

# Wait for services to start
echo "Waiting for services to initialize..."
sleep 15

# Check status
echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "Waiting for model download (may take 1-2 minutes)..."
timeout 180 docker logs -f ollama-init 2>&1 | grep -m 1 "model ready" || echo "Model download in progress..."

REMOTE_SCRIPT

echo -e "${GREEN}✓ Application started${NC}"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

# Display results
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║  🎉 DEPLOYMENT SUCCESSFUL!                                   ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Access your application:${NC}"
echo ""
echo "  📊 Dashboard:      http://$SERVER_IP:3000"
echo "  🤖 Agent API:      http://$SERVER_IP:8000"
echo "  📚 API Docs:       http://$SERVER_IP:8000/docs"
echo "  💾 PostgreSQL:     $SERVER_IP:5432"
echo ""
echo -e "${GREEN}Useful commands:${NC}"
echo ""
echo "  # SSH into server"
echo "  ssh $SSH_USER@$SERVER_IP"
echo ""
echo "  # View logs"
echo "  ssh $SSH_USER@$SERVER_IP 'cd /opt/cyber-defense && docker-compose logs -f'"
echo ""
echo "  # Check status"
echo "  ssh $SSH_USER@$SERVER_IP 'cd /opt/cyber-defense && docker-compose ps'"
echo ""
echo "  # Restart services"
echo "  ssh $SSH_USER@$SERVER_IP 'cd /opt/cyber-defense && docker-compose restart'"
echo ""
echo "  # Stop services"
echo "  ssh $SSH_USER@$SERVER_IP 'cd /opt/cyber-defense && docker-compose down'"
echo ""
echo -e "${YELLOW}Note: The Qwen model is downloading in the background.${NC}"
echo "      It will be ready in 1-2 minutes."
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Open http://$SERVER_IP:3000 to view the dashboard"
echo "  2. Test the API: curl http://$SERVER_IP:8000/health"
echo "  3. Review logs: ssh $SSH_USER@$SERVER_IP 'cd /opt/cyber-defense && docker-compose logs'"
echo ""
