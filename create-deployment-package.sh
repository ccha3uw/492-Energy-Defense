#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-deployment.tar.gz"
TEMP_DIR="cyber-defense-package"

echo "Preparing files..."

# Clean up any previous package
rm -rf "$TEMP_DIR" "$PACKAGE_NAME" 2>/dev/null

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Copy essential files
echo "Copying project files..."
cp -r agent "$TEMP_DIR/"
cp -r backend "$TEMP_DIR/"
cp -r dashboard "$TEMP_DIR/"
cp docker-compose.yml "$TEMP_DIR/"
cp .env.example "$TEMP_DIR/"
cp README.md "$TEMP_DIR/" 2>/dev/null || true
cp check-qwen-model.sh "$TEMP_DIR/" 2>/dev/null || true
cp apply-fix.sh "$TEMP_DIR/" 2>/dev/null || true
cp test-llm-mode.sh "$TEMP_DIR/" 2>/dev/null || true
cp FIX_QWEN_SCORING_ISSUE.md "$TEMP_DIR/" 2>/dev/null || true

# Create deployment script for Hetzner
cat > "$TEMP_DIR/deploy.sh" << 'DEPLOY_EOF'
#!/bin/bash
# Deployment script for Hetzner server

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense Deployment Script                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (or use sudo)"
    exit 1
fi

echo "[1/6] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

echo "[2/6] Installing Docker..."
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

echo "[3/6] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y docker-compose-plugin
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

echo "[4/6] Setting up firewall..."
apt-get install -y ufw
ufw --force enable
ufw allow 22/tcp     # SSH
ufw allow 8000/tcp   # Agent API
ufw allow 3000/tcp   # Dashboard
ufw allow 11434/tcp  # Ollama (optional)
echo "✓ Firewall configured"

echo "[5/6] Setting up environment..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created .env file"
fi

echo "[6/6] Starting services..."
docker compose down 2>/dev/null || true
docker compose up -d

echo ""
echo "════════════════════════════════════════════════════════"
echo "Deployment in progress..."
echo "════════════════════════════════════════════════════════"
echo ""
echo "Waiting for services to initialize (this may take 2-3 minutes)..."
sleep 10

echo ""
echo "Monitoring Qwen model download..."
docker logs -f ollama-init 2>&1 &
LOGS_PID=$!

# Wait for model to be ready (max 5 minutes)
COUNTER=0
while [ $COUNTER -lt 60 ]; do
    if docker logs ollama-init 2>&1 | grep -q "Qwen model ready"; then
        kill $LOGS_PID 2>/dev/null || true
        echo ""
        echo "✓ Qwen model downloaded successfully"
        break
    fi
    sleep 5
    COUNTER=$((COUNTER + 1))
done

if [ $COUNTER -eq 60 ]; then
    echo "⚠ Model download taking longer than expected"
    echo "  Check logs with: docker logs ollama-init"
fi

echo ""
echo "Checking service status..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|cyber|ollama"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Deployment Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Your services are now running:"
echo ""
echo "  • Dashboard:  http://$(hostname -I | awk '{print $1}'):3000"
echo "  • Agent API:  http://$(hostname -I | awk '{print $1}'):8000"
echo "  • API Docs:   http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "Useful commands:"
echo "  • View logs:         docker compose logs -f"
echo "  • Check status:      docker ps"
echo "  • Stop services:     docker compose down"
echo "  • Restart services:  docker compose restart"
echo "  • Test model:        ./check-qwen-model.sh"
echo ""
echo "If you encounter scoring issues with Qwen 0.5B:"
echo "  • Run: ./apply-fix.sh"
echo "  • See: FIX_QWEN_SCORING_ISSUE.md"
echo ""
DEPLOY_EOF

chmod +x "$TEMP_DIR/deploy.sh"

# Create README for deployment
cat > "$TEMP_DIR/DEPLOY_README.md" << 'README_EOF'
# Deployment Package for Hetzner

## Quick Deployment Steps

### 1. Upload to Hetzner Server

```bash
# On your local machine
scp cyber-defense-deployment.tar.gz root@YOUR_SERVER_IP:/root/
```

### 2. Extract and Deploy

```bash
# SSH into your Hetzner server
ssh root@YOUR_SERVER_IP

# Extract the package
cd /root
tar -xzf cyber-defense-deployment.tar.gz
cd cyber-defense-package

# Run deployment script
./deploy.sh
```

That's it! The script will:
- ✅ Install Docker and Docker Compose
- ✅ Configure firewall
- ✅ Start all services
- ✅ Download Qwen model
- ✅ Set up the dashboard

### 3. Access Your Services

After deployment completes (2-3 minutes):

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **Agent API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Server Requirements

### Minimum (Budget)
- **RAM**: 8GB
- **CPU**: 2 vCPUs
- **Storage**: 20GB
- **Cost**: ~€8-15/month

Recommended Hetzner: **CPX21** (3 vCPU, 8GB RAM)

### Recommended (Better Performance)
- **RAM**: 16GB
- **CPU**: 4 vCPUs
- **Storage**: 40GB
- **Cost**: ~€30/month

Recommended Hetzner: **CPX31** (4 vCPU, 16GB RAM)

## Troubleshooting

### Model Not Loading
```bash
# Check logs
docker logs ollama-init

# Manually pull model
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

### Services Not Starting
```bash
# Check all logs
docker compose logs

# Restart everything
docker compose down
docker compose up -d
```

### Firewall Issues
```bash
# Check firewall status
ufw status

# Open required ports
ufw allow 8000/tcp
ufw allow 3000/tcp
```

### Qwen Model Scoring Incorrectly
The 0.5B model may give inaccurate scores. Fix options:

```bash
# Option 1: Switch to rule-based (most accurate)
./apply-fix.sh  # Choose option 1

# Option 2: Upgrade to Qwen 1.5B (better AI)
./apply-fix.sh  # Choose option 2
```

See `FIX_QWEN_SCORING_ISSUE.md` for details.

## Manual Deployment (Alternative)

If the deploy.sh script doesn't work, you can manually:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
apt-get install docker-compose-plugin

# Configure firewall
ufw allow 22/tcp
ufw allow 8000/tcp
ufw allow 3000/tcp

# Start services
docker compose up -d

# Watch model download
docker logs -f ollama-init
```

## Configuration

### Change Model
Edit `docker-compose.yml`:
```yaml
environment:
  - OLLAMA_MODEL=qwen2.5:1.5b  # Change to 1.5b or 3b
```

### Disable LLM (Use Rule-Based)
Edit `docker-compose.yml`:
```yaml
environment:
  - USE_LLM=false  # Use accurate rule-based scoring
```

### Change Database Password
Edit `.env` or `docker-compose.yml`:
```yaml
environment:
  POSTGRES_PASSWORD: your_secure_password
```

## Support Files Included

- `deploy.sh` - Automated deployment script
- `check-qwen-model.sh` - Verify model is loaded
- `apply-fix.sh` - Fix scoring issues
- `test-llm-mode.sh` - Test the system
- `FIX_QWEN_SCORING_ISSUE.md` - Detailed troubleshooting

## Next Steps After Deployment

1. **Test the system**:
   ```bash
   ./check-qwen-model.sh
   ```

2. **Access the dashboard**:
   Open http://YOUR_SERVER_IP:3000 in browser

3. **Test the API**:
   ```bash
   curl http://localhost:8000/health | jq
   ```

4. **Monitor logs**:
   ```bash
   docker compose logs -f
   ```

---

**Questions? Check the main README.md or FIX_QWEN_SCORING_ISSUE.md**
README_EOF

echo ""
echo "Creating tarball..."
tar -czf "$PACKAGE_NAME" -C "$TEMP_DIR" .

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Package created: $PACKAGE_NAME"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Package size:"
ls -lh "$PACKAGE_NAME" | awk '{print "  " $9 ": " $5}'
echo ""
echo "📦 Deployment Instructions:"
echo ""
echo "1. Upload to Hetzner server:"
echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. SSH into server:"
echo "   ssh root@YOUR_SERVER_IP"
echo ""
echo "3. Extract and deploy:"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd cyber-defense-package"
echo "   ./deploy.sh"
echo ""
echo "4. Access services:"
echo "   Dashboard: http://YOUR_SERVER_IP:3000"
echo "   API:       http://YOUR_SERVER_IP:8000"
echo ""

