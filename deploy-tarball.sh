#!/bin/bash
# Deploy to Hetzner using tarball and password authentication

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deploy to Hetzner via Tar.gz (Password Auth)         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass not found. Installing...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    elif command -v brew &> /dev/null; then
        brew install hudochenkov/sshpass/sshpass
    else
        echo -e "${RED}Please install sshpass manually${NC}"
        echo "Ubuntu/Debian: sudo apt-get install sshpass"
        echo "macOS: brew install hudochenkov/sshpass/sshpass"
        exit 1
    fi
fi

# Get server details
if [ -z "$1" ]; then
    read -p "Enter Hetzner server IP: " SERVER_IP
else
    SERVER_IP="$1"
fi

if [ -z "$2" ]; then
    read -sp "Enter root password: " ROOT_PASSWORD
    echo ""
else
    ROOT_PASSWORD="$2"
fi

USER="${3:-root}"

echo ""
echo "Target: $USER@$SERVER_IP"
echo ""

# Find the most recent package
PACKAGE=$(ls -t cyber-defense-agent-*.tar.gz 2>/dev/null | head -1)

if [ -z "$PACKAGE" ]; then
    echo -e "${RED}No package found!${NC}"
    echo "Run: ./create-deployment-package.sh first"
    exit 1
fi

echo "Using package: $PACKAGE"
echo ""

# Test connection
echo -e "${YELLOW}[1/6] Testing connection...${NC}"
if sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER@$SERVER_IP "echo 'Connection OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ Connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo "Please check:"
    echo "  - IP address is correct"
    echo "  - Password is correct"
    echo "  - Server is running"
    exit 1
fi
echo ""

# Upload package
echo -e "${YELLOW}[2/6] Uploading package...${NC}"
sshpass -p "$ROOT_PASSWORD" scp -o StrictHostKeyChecking=no "$PACKAGE" $USER@$SERVER_IP:/root/
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Package uploaded${NC}"
else
    echo -e "${RED}✗ Upload failed${NC}"
    exit 1
fi
echo ""

# Extract package
echo -e "${YELLOW}[3/6] Extracting package...${NC}"
sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER_IP << 'ENDSSH'
cd /root
tar -xzf cyber-defense-agent-*.tar.gz
echo "✓ Package extracted"
ENDSSH
echo ""

# Install Docker if needed
echo -e "${YELLOW}[4/6] Checking Docker installation...${NC}"
sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER_IP << 'ENDSSH'
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    
    # Update system
    apt-get update
    
    # Install prerequisites
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Install docker-compose if needed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing docker-compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ docker-compose installed"
else
    echo "✓ docker-compose already installed"
fi
ENDSSH
echo ""

# Configure firewall
echo -e "${YELLOW}[5/6] Configuring firewall...${NC}"
sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER_IP << 'ENDSSH'
# Install ufw if needed
if ! command -v ufw &> /dev/null; then
    apt-get install -y ufw
fi

# Configure firewall
ufw --force enable
ufw allow 22/tcp
ufw allow 8000/tcp
ufw allow 3000/tcp
ufw allow 5432/tcp
ufw allow 11434/tcp

echo "✓ Firewall configured"
ENDSSH
echo ""

# Start the application
echo -e "${YELLOW}[6/6] Starting application...${NC}"
sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER_IP << 'ENDSSH'
cd /root/workspace

# Make scripts executable
chmod +x *.sh

# Start the system
echo "Starting services..."
docker-compose up -d

echo ""
echo "✓ Application started!"
echo ""
echo "Services will be available at:"
echo "  - Dashboard: http://$(curl -s ifconfig.me):3000"
echo "  - Agent API: http://$(curl -s ifconfig.me):8000"
echo "  - API Docs:  http://$(curl -s ifconfig.me):8000/docs"
ENDSSH
echo ""

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}Deployment Complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Your services are now running at:"
echo "  🌐 Dashboard: http://$SERVER_IP:3000"
echo "  🤖 Agent API: http://$SERVER_IP:8000"
echo "  📚 API Docs:  http://$SERVER_IP:8000/docs"
echo ""
echo "Monitor deployment:"
echo "  sshpass -p '$ROOT_PASSWORD' ssh root@$SERVER_IP 'docker logs -f ollama-init'"
echo ""
echo "Wait 1-2 minutes for Qwen model to download."
echo ""

