#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name with timestamp
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Packaging project files..."

# Create temporary directory
TEMP_DIR="cyber-defense-deploy"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# Copy essential files
echo "  - Copying application files..."
cp -r agent $TEMP_DIR/
cp -r backend $TEMP_DIR/
cp -r dashboard $TEMP_DIR/
cp docker-compose.yml $TEMP_DIR/
cp .env.example $TEMP_DIR/.env
cp README.md $TEMP_DIR/

# Copy helpful scripts
echo "  - Copying deployment scripts..."
cp apply-fix.sh $TEMP_DIR/ 2>/dev/null || true
cp check-qwen-model.sh $TEMP_DIR/ 2>/dev/null || true
cp test-llm-mode.sh $TEMP_DIR/ 2>/dev/null || true

# Create server setup script
cat > $TEMP_DIR/hetzner-setup.sh << 'SETUPEOF'
#!/bin/bash
# Server setup script for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Hetzner Server Setup                                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Update system
echo "1. Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo ""
echo "2. Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Install Docker Compose
echo ""
echo "3. Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

# Install useful tools
echo ""
echo "4. Installing utilities..."
apt-get install -y curl jq htop net-tools

# Configure firewall
echo ""
echo "5. Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 3000/tcp  # Dashboard
ufw allow 8000/tcp  # Agent API
echo "✓ Firewall configured"

# Show Docker info
echo ""
echo "6. Verifying installation..."
docker --version
docker-compose --version

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Setup Complete!                                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. cd /root/cyber-defense"
echo "  2. docker-compose up -d"
echo "  3. docker logs -f ollama-init  (wait for model download)"
echo ""
SETUPEOF

# Create start script
cat > $TEMP_DIR/start-system.sh << 'STARTEOF'
#!/bin/bash
# Start the cyber defense system

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Starting 492-Energy-Defense System                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Start all services
echo "Starting Docker containers..."
docker-compose up -d

echo ""
echo "Waiting for services to initialize..."
sleep 5

# Check status
echo ""
echo "Container status:"
docker-compose ps

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  System Started!                                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Monitor model download:"
echo "  docker logs -f ollama-init"
echo ""
echo "Access the system:"
echo "  Dashboard: http://YOUR_SERVER_IP:3000"
echo "  Agent API: http://YOUR_SERVER_IP:8000"
echo "  API Docs:  http://YOUR_SERVER_IP:8000/docs"
echo ""
echo "Check logs:"
echo "  docker logs cyber-agent"
echo "  docker logs cyber-backend"
echo "  docker logs cyber-dashboard"
echo ""
STARTEOF

chmod +x $TEMP_DIR/hetzner-setup.sh
chmod +x $TEMP_DIR/start-system.sh

# Create README for deployment
cat > $TEMP_DIR/DEPLOY_INSTRUCTIONS.md << 'READMEEOF'
# Hetzner Deployment Instructions

## Quick Start (5 minutes)

### 1. Upload to Server

On your **local machine**, upload the package:

```bash
# Replace YOUR_SERVER_IP with your Hetzner server IP
scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/
```

Enter your root password when prompted.

### 2. SSH to Server

```bash
ssh root@YOUR_SERVER_IP
```

### 3. Extract and Setup

```bash
# Extract the package
cd /root
tar -xzf cyber-defense-*.tar.gz
mv cyber-defense-deploy cyber-defense
cd cyber-defense

# Run setup script (installs Docker, etc.)
chmod +x hetzner-setup.sh
./hetzner-setup.sh
```

### 4. Start the System

```bash
# Start all services
./start-system.sh

# Watch model download (takes 1-2 minutes)
docker logs -f ollama-init

# Press Ctrl+C when you see "Qwen model ready!"
```

### 5. Access the System

Open in your browser:
- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000/docs

---

## Troubleshooting

### Check if containers are running
```bash
docker ps
```

### View logs
```bash
docker logs cyber-agent
docker logs ollama-qwen
docker logs cyber-backend
```

### Restart services
```bash
docker-compose restart
```

### Check Qwen model
```bash
docker exec ollama-qwen ollama list
```

### Manual model pull (if needed)
```bash
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

---

## Server Requirements

- **Minimum**: 2 vCPU, 4GB RAM, 20GB SSD
- **Recommended**: 4 vCPU, 8GB RAM, 40GB SSD

---

## Configuration

### Use Rule-Based Mode (Recommended)

For 100% accurate scoring without LLM overhead:

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change line:
# - USE_LLM=true
# to:
# - USE_LLM=false

# Restart
docker-compose restart agent
```

### Upgrade Qwen Model

For better LLM performance:

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change:
# OLLAMA_MODEL=qwen2.5:0.5b
# to:
# OLLAMA_MODEL=qwen2.5:1.5b

# Pull new model and restart
docker exec ollama-qwen ollama pull qwen2.5:1.5b
docker-compose restart agent
```

---

## Security Notes

- Change default PostgreSQL password in docker-compose.yml
- Use a firewall (already configured by setup script)
- Consider using a reverse proxy with SSL for production

---

## Support

Check the main README.md for detailed documentation.
READMEEOF

# Create the tar.gz package
echo ""
echo "Creating tar.gz archive..."
tar -czf $PACKAGE_NAME $TEMP_DIR

# Clean up
rm -rf $TEMP_DIR

# Get file size
SIZE=$(du -h $PACKAGE_NAME | cut -f1)

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Package Created Successfully!                         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Package: $PACKAGE_NAME"
echo "Size: $SIZE"
echo ""
echo "Next steps:"
echo ""
echo "1. Upload to Hetzner server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH to server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense-deploy"
echo "   ./hetzner-setup.sh"
echo "   ./start-system.sh"
echo ""
echo "See cyber-defense-deploy/DEPLOY_INSTRUCTIONS.md for details"
echo ""
