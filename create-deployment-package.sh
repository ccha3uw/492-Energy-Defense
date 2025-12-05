#!/bin/bash
# Create tar.gz deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name with timestamp
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating deployment package: $PACKAGE_NAME"
echo ""

# Create temporary directory for clean packaging
TMP_DIR=$(mktemp -d)
DEPLOY_DIR="$TMP_DIR/492-energy-defense"

echo "Preparing files..."

# Create deployment directory structure
mkdir -p "$DEPLOY_DIR"

# Copy necessary files
cp -r agent "$DEPLOY_DIR/"
cp -r backend "$DEPLOY_DIR/"
cp -r dashboard "$DEPLOY_DIR/"
cp docker-compose.yml "$DEPLOY_DIR/"
cp .env.example "$DEPLOY_DIR/.env"
cp README.md "$DEPLOY_DIR/"

# Copy deployment scripts
cp check-qwen-model.sh "$DEPLOY_DIR/" 2>/dev/null || true
cp apply-fix.sh "$DEPLOY_DIR/" 2>/dev/null || true

# Create .dockerignore if it doesn't exist
cat > "$DEPLOY_DIR/.dockerignore" << 'DOCKERIGNORE'
**/__pycache__
**/*.pyc
**/*.pyo
**/*.pyd
.git
.gitignore
*.md
!README.md
.env
*.log
.pytest_cache
.coverage
htmlcov/
dist/
build/
*.egg-info
DOCKERIGNORE

# Create .gitignore
cat > "$DEPLOY_DIR/.gitignore" << 'GITIGNORE'
__pycache__/
*.py[cod]
*$py.class
*.so
.env
*.log
.DS_Store
GITIGNORE

echo "✓ Files copied"

# Create deployment instructions
cat > "$DEPLOY_DIR/DEPLOY_INSTRUCTIONS.txt" << 'INSTRUCTIONS'
═══════════════════════════════════════════════════════════
  492-ENERGY-DEFENSE - Hetzner Deployment Instructions
═══════════════════════════════════════════════════════════

SYSTEM REQUIREMENTS:
- Ubuntu 22.04 or 24.04
- 8GB+ RAM (16GB recommended for LLM mode)
- 40GB+ disk space
- Root access

═══════════════════════════════════════════════════════════
DEPLOYMENT STEPS
═══════════════════════════════════════════════════════════

1. UPLOAD PACKAGE TO SERVER
   
   From your local machine:
   scp cyber-defense-*.tar.gz root@YOUR_SERVER_IP:~/
   
   Or use your preferred file transfer method (SFTP, etc.)

2. SSH INTO SERVER
   
   ssh root@YOUR_SERVER_IP

3. EXTRACT PACKAGE
   
   tar -xzf cyber-defense-*.tar.gz
   cd 492-energy-defense

4. INSTALL DOCKER (if not installed)
   
   ./install-docker.sh
   
   Or manually:
   
   # Update system
   apt update && apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Install Docker Compose
   apt install -y docker-compose-plugin
   
   # Verify installation
   docker --version
   docker compose version

5. CONFIGURE FIREWALL (optional but recommended)
   
   # Install UFW if not present
   apt install -y ufw
   
   # Allow SSH (IMPORTANT - do this first!)
   ufw allow 22/tcp
   
   # Allow application ports
   ufw allow 8000/tcp   # Agent API
   ufw allow 3000/tcp   # Dashboard
   ufw allow 11434/tcp  # Ollama (optional)
   
   # Enable firewall
   ufw --force enable
   
   # Check status
   ufw status

6. START THE APPLICATION
   
   # Option A: Quick start (recommended)
   docker compose up -d
   
   # Option B: Start with logs visible
   docker compose up
   
   # Wait 1-2 minutes for model download

7. VERIFY DEPLOYMENT
   
   # Check containers are running
   docker ps
   
   # You should see:
   # - ollama-qwen
   # - cyber-agent
   # - cyber-backend
   # - cyber-events-db
   # - cyber-dashboard
   
   # Check agent health
   curl http://localhost:8000/health
   
   # Check from your local machine
   curl http://YOUR_SERVER_IP:8000/health

8. ACCESS THE APPLICATION
   
   From your browser:
   - Dashboard: http://YOUR_SERVER_IP:3000
   - API Docs:  http://YOUR_SERVER_IP:8000/docs
   - Agent API: http://YOUR_SERVER_IP:8000

═══════════════════════════════════════════════════════════
COMMON COMMANDS
═══════════════════════════════════════════════════════════

# View logs
docker compose logs -f

# Check status
docker compose ps

# Restart services
docker compose restart

# Stop everything
docker compose down

# Update application
docker compose down
docker compose pull
docker compose up -d

# Check model is loaded
docker exec ollama-qwen ollama list

# Check disk space
df -h

# Check memory usage
free -h

═══════════════════════════════════════════════════════════
CONFIGURATION
═══════════════════════════════════════════════════════════

Edit .env file to customize:

# Use Rule-Based Mode (100% accurate, no LLM)
USE_LLM=false

# Use LLM Mode (AI-powered)
USE_LLM=true

# Change model (if using LLM)
OLLAMA_MODEL=qwen2.5:0.5b   # Small, fast
OLLAMA_MODEL=qwen2.5:1.5b   # Medium, accurate
OLLAMA_MODEL=qwen2.5:3b     # Large, most accurate

After editing .env:
docker compose restart agent

═══════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════

Problem: Container won't start
Solution: Check logs
  docker compose logs [service-name]
  
Problem: Port already in use
Solution: Check what's using the port
  netstat -tlnp | grep [port]
  Kill the process or change port in docker-compose.yml

Problem: Out of memory
Solution: 
  - Switch to rule-based mode (USE_LLM=false)
  - Use smaller model (qwen2.5:0.5b)
  - Add swap space

Problem: Can't connect from outside
Solution: Check firewall
  ufw status
  ufw allow [port]/tcp

Problem: Model not downloading
Solution: Check internet connection and manually pull
  docker exec ollama-qwen ollama pull qwen2.5:0.5b

═══════════════════════════════════════════════════════════
SECURITY RECOMMENDATIONS
═══════════════════════════════════════════════════════════

1. Change default passwords in .env file
2. Enable UFW firewall
3. Set up SSH key authentication (disable password auth)
4. Keep system updated: apt update && apt upgrade
5. Use HTTPS/SSL for production (add reverse proxy)
6. Regular backups of database volume

═══════════════════════════════════════════════════════════
BACKUP & RESTORE
═══════════════════════════════════════════════════════════

Backup database:
  docker exec cyber-events-db pg_dump -U postgres cyber_events > backup.sql

Restore database:
  cat backup.sql | docker exec -i cyber-events-db psql -U postgres cyber_events

Backup volumes:
  docker run --rm -v workspace_postgres_data:/data -v $(pwd):/backup \
    ubuntu tar czf /backup/postgres-backup.tar.gz /data

═══════════════════════════════════════════════════════════

For more information, see README.md

Support: Check logs with 'docker compose logs'

═══════════════════════════════════════════════════════════
INSTRUCTIONS

echo "✓ Created deployment instructions"

# Create Docker installation script
cat > "$DEPLOY_DIR/install-docker.sh" << 'DOCKERINSTALL'
#!/bin/bash
# Install Docker and Docker Compose on Ubuntu

echo "Installing Docker..."

# Update system
apt update
apt upgrade -y

# Install prerequisites
apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify installation
echo ""
echo "Docker version:"
docker --version

echo ""
echo "Docker Compose version:"
docker compose version

echo ""
echo "✅ Docker installation complete!"
echo ""
echo "Test with: docker run hello-world"
DOCKERINSTALL

chmod +x "$DEPLOY_DIR/install-docker.sh"
echo "✓ Created Docker installation script"

# Create quick start script
cat > "$DEPLOY_DIR/start.sh" << 'STARTSCRIPT'
#!/bin/bash
# Quick start script

echo "Starting 492-Energy-Defense..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    ./install-docker.sh
fi

echo "Starting services..."
docker compose up -d

echo ""
echo "Waiting for services to initialize..."
sleep 10

echo ""
echo "Checking status..."
docker compose ps

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Services are starting!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Wait 1-2 minutes for Qwen model to download."
echo ""
echo "Monitor progress:"
echo "  docker logs -f ollama-init"
echo ""
echo "Access points:"
echo "  • Dashboard: http://$(hostname -I | awk '{print $1}'):3000"
echo "  • Agent API: http://$(hostname -I | awk '{print $1}'):8000"
echo "  • API Docs:  http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "Check logs:"
echo "  docker compose logs -f"
echo ""
echo "═══════════════════════════════════════════════════════"
STARTSCRIPT

chmod +x "$DEPLOY_DIR/start.sh"
echo "✓ Created start script"

# Create the tar.gz
echo ""
echo "Creating archive..."
cd "$TMP_DIR"
tar -czf "$PACKAGE_NAME" 492-energy-defense/

# Move to current directory
mv "$PACKAGE_NAME" "$OLDPWD/"
cd "$OLDPWD"

# Cleanup
rm -rf "$TMP_DIR"

# Get file size
SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)

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
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:~/"
echo ""
echo "2. SSH to server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd 492-energy-defense"
echo "   ./start.sh"
echo ""
echo "See DEPLOY_INSTRUCTIONS.txt in the package for details."
echo ""

