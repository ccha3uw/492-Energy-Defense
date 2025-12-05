#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-deployment.tar.gz"

echo "Packaging files..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
PROJECT_DIR="$TEMP_DIR/cyber-defense"
mkdir -p "$PROJECT_DIR"

# Copy necessary files
echo "  - Copying application files..."
cp -r agent "$PROJECT_DIR/"
cp -r backend "$PROJECT_DIR/"
cp -r dashboard "$PROJECT_DIR/"

echo "  - Copying configuration files..."
cp docker-compose.yml "$PROJECT_DIR/"
cp .env.example "$PROJECT_DIR/.env"
cp -r .git* "$PROJECT_DIR/" 2>/dev/null || true

echo "  - Copying scripts..."
cp start.sh "$PROJECT_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$PROJECT_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$PROJECT_DIR/" 2>/dev/null || true
cp apply-fix.sh "$PROJECT_DIR/" 2>/dev/null || true

echo "  - Creating setup script..."
cat > "$PROJECT_DIR/setup-hetzner.sh" << 'SETUP_EOF'
#!/bin/bash
# Automated setup script for Hetzner server

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Cyber Defense Agent - Hetzner Setup                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Please run as root (or use sudo)"
    exit 1
fi

echo "[1/6] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

echo "[2/6] Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

echo "[3/6] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

echo "[4/6] Installing useful tools..."
apt-get install -y jq curl htop net-tools

echo "[5/6] Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp    # SSH
    ufw allow 8000/tcp  # Agent API
    ufw allow 3000/tcp  # Dashboard
    ufw allow 11434/tcp # Ollama (optional, for external access)
    echo "✓ Firewall configured"
fi

echo "[6/6] Starting application..."
cd /root/cyber-defense

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Start services
docker-compose up -d

echo ""
echo "════════════════════════════════════════════════════════"
echo "Waiting for services to start..."
echo "This will take 1-2 minutes for model download..."
echo "════════════════════════════════════════════════════════"
echo ""

sleep 15

# Monitor ollama-init
docker logs ollama-init

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Installation Complete!                                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Service URLs:"
echo "  • Dashboard:   http://$(curl -s ifconfig.me):3000"
echo "  • Agent API:   http://$(curl -s ifconfig.me):8000"
echo "  • API Docs:    http://$(curl -s ifconfig.me):8000/docs"
echo ""
echo "🔧 Useful commands:"
echo "  • Check status:  docker-compose ps"
echo "  • View logs:     docker-compose logs -f"
echo "  • Stop:          docker-compose down"
echo "  • Restart:       docker-compose restart"
echo ""
echo "📝 To check if Qwen model loaded:"
echo "  docker exec ollama-qwen ollama list"
echo ""
echo "🧪 To test the agent:"
echo "  curl http://localhost:8000/health | jq"
echo ""
SETUP_EOF

chmod +x "$PROJECT_DIR/setup-hetzner.sh"

echo "  - Creating README..."
cat > "$PROJECT_DIR/DEPLOY_README.md" << 'README_EOF'
# Hetzner Deployment Package

## Quick Deploy Instructions

### Step 1: Upload to Hetzner

From your local machine:

```bash
# Upload the package (replace with your server IP)
scp cyber-defense-deployment.tar.gz root@YOUR_SERVER_IP:/root/

# Or use FileZilla/WinSCP with:
# Host: YOUR_SERVER_IP
# User: root
# Password: your_password
# Upload to: /root/
```

### Step 2: SSH into Server

```bash
ssh root@YOUR_SERVER_IP
# Enter your password when prompted
```

### Step 3: Extract and Setup

```bash
cd /root
tar -xzf cyber-defense-deployment.tar.gz
cd cyber-defense
./setup-hetzner.sh
```

That's it! The script will:
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall
- ✅ Start all services
- ✅ Download Qwen model

### Step 4: Access Your System

After 2-3 minutes:

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **API**: http://YOUR_SERVER_IP:8000/docs

## Troubleshooting

### Check if services are running
```bash
docker-compose ps
```

### View logs
```bash
docker-compose logs -f agent
docker-compose logs -f ollama-init
```

### Restart services
```bash
docker-compose restart
```

### Check Qwen model
```bash
docker exec ollama-qwen ollama list
```

## Server Requirements

- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 20GB free space
- **OS**: Ubuntu 20.04/22.04/24.04

## Ports Used

- 3000 - Dashboard
- 8000 - Agent API
- 5432 - PostgreSQL (internal only)
- 11434 - Ollama (internal only)

## Configuration

To change settings, edit `docker-compose.yml`:

```yaml
# Switch to rule-based mode (more reliable)
- USE_LLM=false

# Or use different model
- OLLAMA_MODEL=qwen2.5:1.5b
```

Then restart:
```bash
docker-compose restart agent
```

## Updates

To update the application:

```bash
cd /root/cyber-defense
docker-compose down
docker-compose pull
docker-compose up -d
```

## Support

For issues, check:
1. `docker-compose logs` - View all logs
2. `docker-compose ps` - Check service status
3. `docker stats` - Check resource usage
README_EOF

# Create the tar.gz
echo ""
echo "Creating archive..."
cd "$TEMP_DIR"
tar -czf "$PACKAGE_NAME" cyber-defense/

# Move to workspace
mv "$PACKAGE_NAME" "$OLDPWD/"
cd "$OLDPWD"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Package created: $PACKAGE_NAME"
echo ""
ls -lh "$PACKAGE_NAME"
echo ""
echo "════════════════════════════════════════════════════════"
echo "Next steps:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. Upload to Hetzner:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH into server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and run setup:"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense"
echo "   ./setup-hetzner.sh"
echo ""
echo "Done! 🚀"
