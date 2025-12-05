#!/bin/bash
# Hetzner Server Setup Script
# Run this ON the Hetzner server as root

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - Hetzner Server Setup              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use: sudo bash hetzner-setup.sh)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${YELLOW}[2/8] Installing required packages...${NC}"
apt-get install -y -qq \
    curl \
    wget \
    git \
    jq \
    ufw \
    htop \
    ca-certificates \
    gnupg \
    lsb-release
echo -e "${GREEN}✓ Packages installed${NC}"
echo ""

echo -e "${YELLOW}[3/8] Installing Docker...${NC}"
if command -v docker &> /dev/null; then
    echo "Docker already installed"
else
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
echo -e "${GREEN}✓ Docker installed${NC}"
echo ""

echo -e "${YELLOW}[4/8] Starting Docker service...${NC}"
systemctl enable docker
systemctl start docker
echo -e "${GREEN}✓ Docker running${NC}"
echo ""

echo -e "${YELLOW}[5/8] Creating deployment user...${NC}"
if id "cyber" &>/dev/null; then
    echo "User 'cyber' already exists"
else
    useradd -m -s /bin/bash cyber
    usermod -aG docker cyber
    echo -e "${GREEN}✓ User 'cyber' created${NC}"
fi
echo ""

echo -e "${YELLOW}[6/8] Setting up firewall...${NC}"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 8000/tcp comment 'Agent API'
ufw allow 3000/tcp comment 'Dashboard'
ufw allow 5432/tcp comment 'PostgreSQL (optional)'
ufw --force reload
echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

echo -e "${YELLOW}[7/8] Creating project directory...${NC}"
mkdir -p /home/cyber/492-energy-defense
chown -R cyber:cyber /home/cyber/492-energy-defense
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo -e "${YELLOW}[8/8] Optimizing system...${NC}"
# Increase max open files
echo "fs.file-max = 65536" >> /etc/sysctl.conf
sysctl -p > /dev/null 2>&1

# Enable swap if not present
if [ $(swapon --show | wc -l) -eq 0 ]; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile > /dev/null 2>&1
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab > /dev/null
    echo -e "${GREEN}✓ 4GB swap created${NC}"
else
    echo "Swap already configured"
fi
echo ""

echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Hetzner server setup complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Switch to deployment user: su - cyber"
echo "2. Upload project files to: /home/cyber/492-energy-defense"
echo "3. Run: cd /home/cyber/492-energy-defense && docker compose up -d"
echo ""
echo "Server is ready for deployment!"
echo ""
