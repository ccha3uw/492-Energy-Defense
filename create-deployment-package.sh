#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating deployment package: $PACKAGE_NAME"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
PROJECT_DIR="$TEMP_DIR/492-energy-defense"

echo "Copying files..."
mkdir -p "$PROJECT_DIR"

# Copy essential files
cp -r agent "$PROJECT_DIR/"
cp -r backend "$PROJECT_DIR/"
cp -r dashboard "$PROJECT_DIR/"
cp docker-compose.yml "$PROJECT_DIR/"
cp docker-compose-simple.yml "$PROJECT_DIR/"
cp .env.example "$PROJECT_DIR/"
cp .gitignore "$PROJECT_DIR/" 2>/dev/null || true

# Copy scripts
cp start.sh "$PROJECT_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$PROJECT_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$PROJECT_DIR/" 2>/dev/null || true
cp apply-fix.sh "$PROJECT_DIR/" 2>/dev/null || true

# Copy documentation
cp README.md "$PROJECT_DIR/" 2>/dev/null || true
cp PROJECT_SUMMARY.md "$PROJECT_DIR/" 2>/dev/null || true
cp FIX_QWEN_SCORING_ISSUE.md "$PROJECT_DIR/" 2>/dev/null || true
cp MIGRATION_COMPLETE.md "$PROJECT_DIR/" 2>/dev/null || true

# Make scripts executable
chmod +x "$PROJECT_DIR"/*.sh 2>/dev/null || true

# Create deployment instructions
cat > "$PROJECT_DIR/DEPLOY_INSTRUCTIONS.txt" << 'DEPLOY'
═══════════════════════════════════════════════════════════════
  HETZNER DEPLOYMENT INSTRUCTIONS
═══════════════════════════════════════════════════════════════

STEP 1: Install Docker on Hetzner
──────────────────────────────────────────────────────────────
Run these commands on your Hetzner server:

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install -y docker-compose

# Verify installation
docker --version
docker-compose --version


STEP 2: Extract and Start
──────────────────────────────────────────────────────────────
# Extract the package
tar -xzf cyber-defense-*.tar.gz
cd 492-energy-defense

# Start the system
docker-compose up -d

# Watch model download (1-2 minutes)
docker logs -f ollama-init

# When you see "Qwen model ready!", press Ctrl+C


STEP 3: Verify It's Working
──────────────────────────────────────────────────────────────
# Check all containers are running
docker ps

# Test the agent
curl http://localhost:8000/health

# Open dashboard (if port 3000 is accessible)
# http://YOUR_SERVER_IP:3000


STEP 4: Configure Firewall (Optional)
──────────────────────────────────────────────────────────────
# Allow SSH and web access
ufw allow 22/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw enable


TROUBLESHOOTING
──────────────────────────────────────────────────────────────
# If Qwen model shows "low" for critical events:
./apply-fix.sh
# Choose option 1 (Rule-Based Mode) for 100% accuracy

# View logs
docker logs cyber-agent
docker logs cyber-backend
docker logs ollama-qwen

# Restart services
docker-compose restart

# Fresh start
docker-compose down -v
docker-compose up -d


QUICK REFERENCE
──────────────────────────────────────────────────────────────
Start:   docker-compose up -d
Stop:    docker-compose down
Logs:    docker logs -f cyber-agent
Status:  docker ps

Dashboard:  http://YOUR_IP:3000
API:        http://YOUR_IP:8000
API Docs:   http://YOUR_IP:8000/docs


NOTES
──────────────────────────────────────────────────────────────
- First startup downloads ~400MB Qwen model (1-2 minutes)
- System generates events every 30 minutes
- Default: Rule-based mode (USE_LLM=false) for accuracy
- To enable LLM: Edit docker-compose.yml, set USE_LLM=true

For more information, see README.md

═══════════════════════════════════════════════════════════════
DEPLOY

echo "✓ Copied project files"
echo ""

# Create tarball
cd "$TEMP_DIR"
tar -czf "$PACKAGE_NAME" 492-energy-defense/

# Move to workspace
mv "$PACKAGE_NAME" /workspace/

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ Deployment package created: $PACKAGE_NAME"
echo ""
echo "Package size:"
du -h "/workspace/$PACKAGE_NAME"
echo ""
echo "To deploy to Hetzner:"
echo "  1. Copy this file to your Hetzner server:"
echo "     scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "  2. SSH into server and extract:"
echo "     ssh root@YOUR_SERVER_IP"
echo "     tar -xzf $PACKAGE_NAME"
echo "     cd 492-energy-defense"
echo ""
echo "  3. Read DEPLOY_INSTRUCTIONS.txt for setup steps"
echo ""
echo "Or use the automated deployment script:"
echo "  ./deploy-to-hetzner-simple.sh YOUR_SERVER_IP"
echo ""

