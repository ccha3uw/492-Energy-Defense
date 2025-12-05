#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name
PACKAGE_NAME="cyber-defense-agent-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating package: $PACKAGE_NAME"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
APP_DIR="$TEMP_DIR/cyber-defense-agent"
mkdir -p "$APP_DIR"

echo "Copying files..."

# Copy application files
cp -r agent "$APP_DIR/"
cp -r backend "$APP_DIR/"
cp -r dashboard "$APP_DIR/"

# Copy configuration files
cp docker-compose.yml "$APP_DIR/"
cp .env.example "$APP_DIR/.env"
cp .gitignore "$APP_DIR/" 2>/dev/null || true

# Copy scripts
cp start.sh "$APP_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$APP_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$APP_DIR/" 2>/dev/null || true

# Copy documentation (only essential ones)
cp README.md "$APP_DIR/" 2>/dev/null || true
cp MIGRATION_COMPLETE.md "$APP_DIR/" 2>/dev/null || true
cp FIX_QWEN_SCORING_ISSUE.md "$APP_DIR/" 2>/dev/null || true

echo "✓ Files copied"

# Create deployment script for Hetzner
cat > "$APP_DIR/deploy-on-hetzner.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
# Run this script on your Hetzner server

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - Hetzner Deployment              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (or use sudo)"
    exit 1
fi

echo "Step 1: Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Update packages
    apt-get update
    
    # Install prerequisites
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

echo ""
echo "Step 2: Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

echo ""
echo "Step 3: Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp    # SSH
    ufw allow 8000/tcp  # Agent API
    ufw allow 3000/tcp  # Dashboard
    ufw allow 5432/tcp  # PostgreSQL (optional, for external access)
    echo "✓ Firewall configured"
else
    echo "⚠ UFW not installed, skipping firewall setup"
fi

echo ""
echo "Step 4: Starting services..."
cd "$(dirname "$0")"

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Start Docker Compose
docker-compose up -d

echo ""
echo "Step 5: Waiting for services to initialize..."
echo "This may take 2-3 minutes (Qwen model download)..."
sleep 30

echo ""
echo "Checking service status..."
docker-compose ps

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Access your services:"
echo ""
echo "  Dashboard:  http://$(curl -s ifconfig.me):3000"
echo "  Agent API:  http://$(curl -s ifconfig.me):8000"
echo "  API Docs:   http://$(curl -s ifconfig.me):8000/docs"
echo ""
echo "📋 Useful commands:"
echo "  docker-compose logs -f        # View all logs"
echo "  docker-compose ps             # Check status"
echo "  docker-compose restart        # Restart services"
echo "  docker-compose down           # Stop services"
echo ""
echo "📊 Monitor model download:"
echo "  docker logs -f ollama-init"
echo ""
echo "✅ System is ready to use!"
echo ""
DEPLOY_SCRIPT

chmod +x "$APP_DIR/deploy-on-hetzner.sh"

echo "✓ Deployment script created"

# Create README for deployment
cat > "$APP_DIR/DEPLOY_README.txt" << 'DEPLOY_README'
╔════════════════════════════════════════════════════════════╗
║  492-Energy-Defense Cybersecurity Agent                   ║
║  Hetzner Deployment Package                                ║
╚════════════════════════════════════════════════════════════╝

QUICK DEPLOYMENT STEPS:

1. Upload this package to your Hetzner server:
   
   Using SCP (from your local machine):
   $ scp cyber-defense-agent-*.tar.gz root@YOUR_SERVER_IP:/root/

   Or using a file transfer tool (WinSCP, FileZilla, etc.)

2. SSH into your Hetzner server:
   
   $ ssh root@YOUR_SERVER_IP

3. Extract the package:
   
   $ cd /root
   $ tar -xzf cyber-defense-agent-*.tar.gz
   $ cd cyber-defense-agent

4. Run the deployment script:
   
   $ bash deploy-on-hetzner.sh

5. Wait 2-3 minutes for services to start

6. Access your services:
   
   Dashboard: http://YOUR_SERVER_IP:3000
   Agent API: http://YOUR_SERVER_IP:8000/docs

═══════════════════════════════════════════════════════════

SYSTEM REQUIREMENTS:

- Ubuntu 20.04+ or Debian 11+
- 4GB+ RAM (8GB recommended)
- 20GB+ disk space
- Root access

═══════════════════════════════════════════════════════════

INCLUDED FILES:

- agent/          Agent service code
- backend/        Backend service code  
- dashboard/      Dashboard service code
- docker-compose.yml  Service orchestration
- .env            Environment configuration
- deploy-on-hetzner.sh  Auto-deployment script
- README.md       Full documentation
- *.sh            Helper scripts

═══════════════════════════════════════════════════════════

TROUBLESHOOTING:

If services don't start:
$ docker-compose logs

To restart:
$ docker-compose restart

To stop:
$ docker-compose down

For help, see README.md

═══════════════════════════════════════════════════════════
DEPLOY_README

echo "✓ Deployment README created"

# Create the tar.gz package
echo ""
echo "Creating archive..."
cd "$TEMP_DIR"
tar -czf "/tmp/$PACKAGE_NAME" cyber-defense-agent/

# Move to current directory
mv "/tmp/$PACKAGE_NAME" "$(pwd)/$PACKAGE_NAME"
FINAL_PATH="$(pwd)/$PACKAGE_NAME"

# Cleanup
rm -rf "$TEMP_DIR"

# Get file size
SIZE=$(du -h "$FINAL_PATH" | cut -f1)

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Package Created Successfully!                         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Package: $PACKAGE_NAME"
echo "📊 Size: $SIZE"
echo "📍 Location: $FINAL_PATH"
echo ""
echo "Next steps:"
echo ""
echo "1. Upload to Hetzner:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH to server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense-agent"
echo "   bash deploy-on-hetzner.sh"
echo ""

