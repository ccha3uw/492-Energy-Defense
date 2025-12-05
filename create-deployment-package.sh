#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="cyber-defense-${TIMESTAMP}.tar.gz"

echo "Creating package: $PACKAGE_NAME"
echo ""

# Create temporary directory
TMP_DIR="/tmp/cyber-defense-deploy"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

echo "Copying files..."

# Copy essential files and directories
cp -r agent $TMP_DIR/
cp -r backend $TMP_DIR/
cp -r dashboard $TMP_DIR/
cp docker-compose.yml $TMP_DIR/
cp .env.example $TMP_DIR/
cp *.sh $TMP_DIR/ 2>/dev/null || true
cp README.md $TMP_DIR/ 2>/dev/null || true

# Create .gitignore for the package
cat > $TMP_DIR/.gitignore << 'GITIGNORE'
__pycache__/
*.py[cod]
*$py.class
.env
*.log
.DS_Store
GITIGNORE

# Create deployment script
cat > $TMP_DIR/deploy.sh << 'DEPLOY'
#!/bin/bash
# Deployment script for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense Deployment                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Docker Compose not found. Installing..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

echo ""
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to initialize..."
echo "(This may take 1-2 minutes for Qwen model download)"
sleep 10

echo ""
echo "Watching model download..."
echo "Press Ctrl+C once you see 'Qwen model ready!'"
echo ""
docker logs -f ollama-init 2>&1 || true

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Services are running:"
echo "  • Dashboard:  http://$(hostname -I | awk '{print $1}'):3000"
echo "  • Agent API:  http://$(hostname -I | awk '{print $1}'):8000"
echo "  • Database:   localhost:5432"
echo ""
echo "Useful commands:"
echo "  docker-compose ps              # Check status"
echo "  docker-compose logs -f         # View logs"
echo "  docker-compose down            # Stop services"
echo "  docker-compose restart         # Restart services"
echo ""
DEPLOY

chmod +x $TMP_DIR/deploy.sh

# Create quick README
cat > $TMP_DIR/DEPLOY_README.txt << 'README'
╔════════════════════════════════════════════════════════╗
║  492-Energy-Defense Deployment Package                ║
╚════════════════════════════════════════════════════════╝

QUICK DEPLOYMENT TO HETZNER
============================

1. Upload this package to your Hetzner server:
   
   scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:/root/

2. SSH into your server:
   
   ssh root@YOUR_SERVER_IP

3. Extract and deploy:
   
   cd /root
   tar -xzf cyber-defense-*.tar.gz
   cd cyber-defense-deploy
   ./deploy.sh

4. Access your services:
   
   • Dashboard: http://YOUR_SERVER_IP:3000
   • API: http://YOUR_SERVER_IP:8000

FIREWALL SETUP
==============

If needed, open ports:

   ufw allow 22/tcp    # SSH
   ufw allow 3000/tcp  # Dashboard
   ufw allow 8000/tcp  # API (optional)
   ufw enable

REQUIREMENTS
============

• Server: Ubuntu 20.04+ or Debian 11+
• RAM: 4GB minimum, 8GB recommended
• Disk: 10GB free space
• Root access

TROUBLESHOOTING
===============

View logs:
   cd /root/cyber-defense-deploy
   docker-compose logs -f

Check status:
   docker-compose ps

Restart services:
   docker-compose restart

Stop services:
   docker-compose down

SUPPORT
=======

For issues, check the logs and README.md in the package.
README

echo "✓ Files copied"
echo ""

# Create the tar.gz package
cd /tmp
tar -czf "/tmp/$PACKAGE_NAME" cyber-defense-deploy/

# Move to workspace
mv "/tmp/$PACKAGE_NAME" /workspace/

# Clean up
rm -rf $TMP_DIR

echo "✓ Package created"
echo ""
echo "════════════════════════════════════════════════════════"
echo "Package ready: $PACKAGE_NAME"
echo "Size: $(du -h /workspace/$PACKAGE_NAME | cut -f1)"
echo "════════════════════════════════════════════════════════"
echo ""
echo "To deploy to Hetzner:"
echo ""
echo "1. Upload to server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH to server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense-deploy"
echo "   ./deploy.sh"
echo ""
echo "4. Access dashboard:"
echo "   http://YOUR_SERVER_IP:3000"
echo ""

