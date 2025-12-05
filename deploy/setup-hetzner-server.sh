#!/bin/bash
# Hetzner Server Setup Script
# Run this ON the Hetzner server as root

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense Hetzner Server Setup              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use: sudo bash setup-hetzner-server.sh)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${YELLOW}[2/8] Installing required packages...${NC}"
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    jq \
    ufw \
    htop
echo -e "${GREEN}✓ Packages installed${NC}"
echo ""

echo -e "${YELLOW}[3/8] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Enable Docker
    systemctl enable docker
    systemctl start docker
    
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

echo -e "${YELLOW}[4/8] Creating application user...${NC}"
if ! id "cyber" &>/dev/null; then
    useradd -m -s /bin/bash cyber
    usermod -aG docker cyber
    echo -e "${GREEN}✓ User 'cyber' created${NC}"
else
    echo -e "${GREEN}✓ User 'cyber' already exists${NC}"
fi
echo ""

echo -e "${YELLOW}[5/8] Setting up application directory...${NC}"
mkdir -p /home/cyber/app
chown -R cyber:cyber /home/cyber/app
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo -e "${YELLOW}[6/8] Configuring firewall...${NC}"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 8000/tcp  # Agent API
ufw allow 3000/tcp  # Dashboard
ufw allow 5432/tcp  # PostgreSQL (optional, for external access)
ufw reload
echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

echo -e "${YELLOW}[7/8] Optimizing system for Docker...${NC}"
# Increase file descriptors
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
EOF

# Optimize Docker
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker
echo -e "${GREEN}✓ System optimized${NC}"
echo ""

echo -e "${YELLOW}[8/8] Setting up automatic updates...${NC}"
apt-get install -y -qq unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
echo -e "${GREEN}✓ Automatic updates enabled${NC}"
echo ""

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Server setup complete!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Switch to cyber user: su - cyber"
echo "2. Wait for deployment from local machine"
echo ""
echo "Or manually deploy:"
echo "  cd /home/cyber/app"
echo "  git clone <your-repo> ."
echo "  docker compose up -d"
echo ""
