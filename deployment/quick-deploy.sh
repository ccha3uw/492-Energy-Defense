#!/bin/bash
# Ultra-quick deployment for Hetzner
# For users who just want it running NOW

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Quick Deploy - 492-Energy-Defense                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if server IP is provided
if [ -z "$1" ]; then
    echo "Usage: ./quick-deploy.sh <SERVER_IP>"
    echo ""
    echo "Example: ./quick-deploy.sh 65.21.123.45"
    exit 1
fi

SERVER_IP="$1"

echo "📦 Deploying to: $SERVER_IP"
echo ""

# Create deployment package
echo "[1/4] Creating deployment package..."
tar czf /tmp/cyber-defense-deploy.tar.gz \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env' \
    -C .. .

# Copy to server
echo "[2/4] Uploading to server..."
scp /tmp/cyber-defense-deploy.tar.gz root@$SERVER_IP:/tmp/

# Run deployment on server
echo "[3/4] Installing on server..."
ssh root@$SERVER_IP << 'ENDSSH'
# Install Docker if needed
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Extract files
mkdir -p /root/cyber-defense
cd /root/cyber-defense
tar xzf /tmp/cyber-defense-deploy.tar.gz
rm /tmp/cyber-defense-deploy.tar.gz

# Configure firewall
ufw --force enable
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp

# Start services
docker-compose up -d

echo "✅ Deployment complete!"
ENDSSH

echo "[4/4] Verifying deployment..."
sleep 10

# Check if services are up
if curl -sf http://$SERVER_IP:8000/health > /dev/null; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅ SUCCESS! Your agent is running!                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "🌐 Access your application:"
    echo "   Dashboard: http://$SERVER_IP:3000"
    echo "   API:       http://$SERVER_IP:8000"
    echo "   Docs:      http://$SERVER_IP:8000/docs"
    echo ""
else
    echo "⚠️  Services are starting... Give it 2-3 more minutes."
    echo "   Check status: ssh root@$SERVER_IP 'cd /root/cyber-defense && docker-compose ps'"
fi

# Cleanup
rm /tmp/cyber-defense-deploy.tar.gz 2>/dev/null || true
