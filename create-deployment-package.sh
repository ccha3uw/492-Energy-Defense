#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-agent-deployment.tar.gz"
TEMP_DIR="cyber-agent-deploy"

echo "Preparing files..."

# Create temporary directory
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# Copy necessary files
echo "Copying application files..."
cp -r agent $TEMP_DIR/
cp -r backend $TEMP_DIR/
cp -r dashboard $TEMP_DIR/
cp docker-compose.yml $TEMP_DIR/
cp .env.example $TEMP_DIR/.env
cp README.md $TEMP_DIR/
cp start.sh $TEMP_DIR/
cp check-qwen-model.sh $TEMP_DIR/
cp test-llm-mode.sh $TEMP_DIR/
cp apply-fix.sh $TEMP_DIR/ 2>/dev/null || true

# Clean up unnecessary files
echo "Cleaning up..."
find $TEMP_DIR -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find $TEMP_DIR -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find $TEMP_DIR -type f -name "*.pyc" -delete 2>/dev/null || true
find $TEMP_DIR -type f -name "*.pyo" -delete 2>/dev/null || true
find $TEMP_DIR -type f -name ".DS_Store" -delete 2>/dev/null || true

# Create deployment script inside package
cat > $TEMP_DIR/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
# Hetzner Deployment Script

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense Deployment                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    
    # Update package list
    apt-get update
    
    # Install prerequisites
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    
    # Add Docker repository
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    echo "✓ Docker installed successfully"
else
    echo "✓ Docker already installed"
fi

echo ""
echo "Starting application..."

# Make scripts executable
chmod +x *.sh

# Start services
docker-compose up -d

echo ""
echo "Waiting for services to initialize..."
echo "(This will take 1-2 minutes for first-time model download)"
echo ""

sleep 10

echo "Checking Ollama..."
docker-compose ps ollama

echo ""
echo "Watching model download (press Ctrl+C when done)..."
docker logs -f ollama-init 2>&1 | head -50

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Services:"
echo "  • Dashboard:  http://YOUR_SERVER_IP:3000"
echo "  • Agent API:  http://YOUR_SERVER_IP:8000"
echo "  • API Docs:   http://YOUR_SERVER_IP:8000/docs"
echo ""
echo "Useful commands:"
echo "  • Check status:    docker-compose ps"
echo "  • View logs:       docker-compose logs -f"
echo "  • Stop services:   docker-compose down"
echo "  • Restart:         docker-compose restart"
echo ""
echo "Run './check-qwen-model.sh' to verify the AI model loaded."
echo ""
DEPLOY_SCRIPT

chmod +x $TEMP_DIR/deploy.sh

# Create archive
echo "Creating archive..."
tar -czf $PACKAGE_NAME $TEMP_DIR

# Get size
SIZE=$(du -h $PACKAGE_NAME | cut -f1)

# Cleanup
rm -rf $TEMP_DIR

echo ""
echo "✅ Package created: $PACKAGE_NAME ($SIZE)"
echo ""
echo "To deploy to Hetzner:"
echo "  1. scp $PACKAGE_NAME root@YOUR_SERVER_IP:~/"
echo "  2. ssh root@YOUR_SERVER_IP"
echo "  3. tar -xzf $PACKAGE_NAME"
echo "  4. cd $TEMP_DIR"
echo "  5. ./deploy.sh"
echo ""
