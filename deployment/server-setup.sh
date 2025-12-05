#!/bin/bash
# Server setup script - runs on the Hetzner server
# Installs Docker, creates user, configures firewall

set -e

echo "Setting up Hetzner server..."

# Update system
echo "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install required packages
echo "Installing required packages..."
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
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
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

# Create cyber user if not exists
if ! id -u cyber &> /dev/null; then
    echo "Creating cyber user..."
    useradd -m -s /bin/bash cyber
    usermod -aG docker cyber
    echo "✓ User created"
else
    echo "✓ User already exists"
    # Ensure user is in docker group
    usermod -aG docker cyber
fi

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp     # SSH
ufw allow 3000/tcp   # Dashboard
ufw allow 8000/tcp   # Agent API
ufw allow 5432/tcp   # PostgreSQL (optional, for remote access)
echo "✓ Firewall configured"

# Set up log rotation for Docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

echo "✓ Server setup complete!"
