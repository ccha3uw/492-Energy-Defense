#!/bin/bash
# Server preparation script for Hetzner
# This runs on the remote server

set -e

echo "════════════════════════════════════════════════════════"
echo "  Server Setup for 492-Energy-Defense"
echo "════════════════════════════════════════════════════════"
echo ""

# Update system
echo "[1/6] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq
echo "✓ System updated"
echo ""

# Install required packages
echo "[2/6] Installing required packages..."
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    jq \
    ufw \
    htop
echo "✓ Packages installed"
echo ""

# Install Docker
echo "[3/6] Installing Docker..."
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
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi
echo ""

# Install Docker Compose standalone
echo "[4/6] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi
echo ""

# Configure firewall
echo "[5/6] Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 3000/tcp comment 'Dashboard'
ufw allow 8000/tcp comment 'Agent API'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
echo "✓ Firewall configured"
echo ""

# Setup log rotation
echo "[6/6] Setting up log rotation..."
cat > /etc/logrotate.d/docker-containers << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
}
EOF
echo "✓ Log rotation configured"
echo ""

echo "════════════════════════════════════════════════════════"
echo "✓ Server setup complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
echo ""
