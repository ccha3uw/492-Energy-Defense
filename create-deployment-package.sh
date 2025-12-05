#!/bin/bash
# Create deployment package for Hetzner

echo "════════════════════════════════════════════════════════"
echo "  Creating Hetzner Deployment Package"
echo "════════════════════════════════════════════════════════"
echo ""

# Package name with date
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "📦 Packaging application files..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
APP_DIR="$TEMP_DIR/492-energy-defense"
mkdir -p "$APP_DIR"

# Copy application files
echo "  ✓ Copying application code..."
cp -r agent "$APP_DIR/"
cp -r backend "$APP_DIR/"
cp -r dashboard "$APP_DIR/"

# Copy configuration files
echo "  ✓ Copying configuration..."
cp docker-compose.yml "$APP_DIR/"
cp docker-compose-simple.yml "$APP_DIR/"
cp .env.example "$APP_DIR/"
cp .gitignore "$APP_DIR/" 2>/dev/null || true

# Copy scripts
echo "  ✓ Copying scripts..."
cp start.sh "$APP_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$APP_DIR/" 2>/dev/null || true
cp apply-fix.sh "$APP_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$APP_DIR/" 2>/dev/null || true
cp troubleshoot.sh "$APP_DIR/" 2>/dev/null || true

# Copy essential documentation
echo "  ✓ Copying documentation..."
cp README.md "$APP_DIR/" 2>/dev/null || true
cp PROJECT_SUMMARY.md "$APP_DIR/" 2>/dev/null || true
cp FIX_QWEN_SCORING_ISSUE.md "$APP_DIR/" 2>/dev/null || true
cp MIGRATION_COMPLETE.md "$APP_DIR/" 2>/dev/null || true

# Create deployment script for Hetzner
cat > "$APP_DIR/deploy-on-server.sh" << 'DEPLOY_SCRIPT'
#!/bin/bash
# Run this script on your Hetzner server

echo "════════════════════════════════════════════════════════"
echo "  492-Energy-Defense - Server Setup"
echo "════════════════════════════════════════════════════════"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (or use sudo)"
    exit 1
fi

echo "📦 Installing dependencies..."

# Update system
apt-get update -qq

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "  Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "  ✓ Docker installed"
else
    echo "  ✓ Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "  Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "  ✓ Docker Compose installed"
else
    echo "  ✓ Docker Compose already installed"
fi

# Install useful tools
apt-get install -y jq curl wget htop nano -qq

echo ""
echo "🚀 Starting application..."
cd "$(dirname "$0")"

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Start services
docker-compose up -d

echo ""
echo "⏳ Waiting for services to initialize..."
echo "   (This will take 1-2 minutes for Qwen model download)"
echo ""

# Wait for Ollama init
sleep 15
echo "📥 Downloading Qwen model..."
docker logs ollama-init 2>&1 | tail -5

echo ""
echo "Waiting for agent to be ready..."
sleep 20

# Try to connect to agent
for i in {1..10}; do
    if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Agent is ready!"
        break
    fi
    echo "  Waiting... ($i/10)"
    sleep 3
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Deployment Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Services:"
echo "   • Agent API:    http://localhost:8000"
echo "   • API Docs:     http://localhost:8000/docs"
echo "   • Dashboard:    http://localhost:3000"
echo "   • Database:     localhost:5432"
echo ""
echo "🔍 Check status:"
echo "   docker-compose ps"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f"
echo ""
echo "🔧 Quick fix (if scoring issues):"
echo "   ./apply-fix.sh"
echo ""
echo "🌐 To access from outside the server:"
echo "   1. Configure firewall: ufw allow 8000/tcp"
echo "   2. Access via: http://YOUR_SERVER_IP:8000"
echo ""
DEPLOY_SCRIPT

chmod +x "$APP_DIR/deploy-on-server.sh"

echo "  ✓ Created deployment script"
echo ""

# Create README for deployment
cat > "$APP_DIR/DEPLOY_README.txt" << 'DEPLOY_README'
╔══════════════════════════════════════════════════════════╗
║  492-ENERGY-DEFENSE - DEPLOYMENT PACKAGE                ║
╚══════════════════════════════════════════════════════════╝

QUICK START (On Hetzner Server):

1. Upload this folder to your server:
   - Use scp, sftp, or web upload
   - Or extract the tar.gz on the server

2. SSH into your server:
   ssh root@YOUR_SERVER_IP

3. Navigate to the folder:
   cd 492-energy-defense

4. Run the deployment script:
   chmod +x deploy-on-server.sh
   ./deploy-on-server.sh

5. Wait 1-2 minutes for setup to complete

6. Access the services:
   • Agent API: http://YOUR_SERVER_IP:8000
   • Dashboard: http://YOUR_SERVER_IP:3000

══════════════════════════════════════════════════════════

WHAT IT DOES:

✓ Installs Docker and Docker Compose
✓ Sets up all services
✓ Downloads Qwen AI model (~400MB)
✓ Starts the cybersecurity agent
✓ Initializes database

══════════════════════════════════════════════════════════

REQUIREMENTS:

• Ubuntu 20.04+ or Debian 11+
• 4GB+ RAM (recommended: 8GB)
• 20GB+ disk space
• Root access

══════════════════════════════════════════════════════════

USEFUL COMMANDS:

Check status:
  docker-compose ps

View logs:
  docker-compose logs -f

Stop services:
  docker-compose down

Restart:
  docker-compose restart

Fix scoring issues:
  ./apply-fix.sh

══════════════════════════════════════════════════════════

FIREWALL SETUP (Optional):

To access from your local machine:

  ufw allow 22/tcp    # SSH
  ufw allow 8000/tcp  # Agent API
  ufw allow 3000/tcp  # Dashboard
  ufw enable

══════════════════════════════════════════════════════════

For full documentation, see README.md

Support: Check logs with 'docker-compose logs'
DEPLOY_README

echo "  ✓ Created deployment README"
echo ""

# Create the tar.gz
echo "📦 Creating archive..."
cd "$TEMP_DIR"
tar -czf "/workspace/$PACKAGE_NAME" 492-energy-defense/

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Package created successfully!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📦 Package: $PACKAGE_NAME"
echo "📏 Size: $(du -h /workspace/$PACKAGE_NAME | cut -f1)"
echo ""
echo "📤 DEPLOYMENT STEPS:"
echo ""
echo "1. Download the package to your local machine:"
echo ""
echo "2. Upload to Hetzner server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "3. SSH into server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "4. Extract and deploy:"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd 492-energy-defense"
echo "   ./deploy-on-server.sh"
echo ""
echo "5. Access your services:"
echo "   http://YOUR_SERVER_IP:8000 (Agent API)"
echo "   http://YOUR_SERVER_IP:3000 (Dashboard)"
echo ""
echo "════════════════════════════════════════════════════════"

