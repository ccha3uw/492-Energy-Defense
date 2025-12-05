#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-qwen-deploy.tar.gz"

echo "📦 Packaging files..."

# Create temporary directory for clean packaging
mkdir -p /tmp/cyber-defense-deploy

# Copy necessary files
echo "  → Copying application files..."
cp -r agent /tmp/cyber-defense-deploy/
cp -r backend /tmp/cyber-defense-deploy/
cp -r dashboard /tmp/cyber-defense-deploy/
cp docker-compose.yml /tmp/cyber-defense-deploy/
cp docker-compose-simple.yml /tmp/cyber-defense-deploy/
cp .env.example /tmp/cyber-defense-deploy/
cp .gitignore /tmp/cyber-defense-deploy/ 2>/dev/null || true

echo "  → Copying scripts..."
cp start.sh /tmp/cyber-defense-deploy/
cp test-llm-mode.sh /tmp/cyber-defense-deploy/
cp troubleshoot.sh /tmp/cyber-defense-deploy/
cp check-qwen-model.sh /tmp/cyber-defense-deploy/
cp apply-fix.sh /tmp/cyber-defense-deploy/

echo "  → Copying documentation..."
cp README.md /tmp/cyber-defense-deploy/
cp PROJECT_SUMMARY.md /tmp/cyber-defense-deploy/ 2>/dev/null || true
cp FIX_QWEN_SCORING_ISSUE.md /tmp/cyber-defense-deploy/ 2>/dev/null || true
cp MIGRATION_COMPLETE.md /tmp/cyber-defense-deploy/ 2>/dev/null || true
cp HETZNER_DEPLOYMENT_GUIDE.md /tmp/cyber-defense-deploy/ 2>/dev/null || true

# Create deployment instructions
cat > /tmp/cyber-defense-deploy/DEPLOY.md << 'DEPLOYEOF'
# Quick Deployment to Hetzner

## On Your Local Machine

1. Upload this package to your server:
```bash
scp cyber-defense-qwen-deploy.tar.gz root@YOUR_SERVER_IP:/root/
```

## On Hetzner Server (as root)

1. Extract the package:
```bash
cd /root
tar -xzf cyber-defense-qwen-deploy.tar.gz
cd cyber-defense-deploy
```

2. Install Docker (if not already installed):
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

3. Start the system:
```bash
chmod +x *.sh
docker-compose up -d
```

4. Watch the model download:
```bash
docker logs -f ollama-init
# Wait for "Qwen model ready!"
```

5. Test it works:
```bash
./check-qwen-model.sh
```

## Access the System

- **Dashboard**: http://YOUR_SERVER_IP:3000
- **API**: http://YOUR_SERVER_IP:8000
- **API Docs**: http://YOUR_SERVER_IP:8000/docs

## Configure Firewall (Optional but Recommended)

```bash
ufw allow 22/tcp    # SSH
ufw allow 3000/tcp  # Dashboard
ufw allow 8000/tcp  # API
ufw enable
```

## Troubleshooting

If issues occur:
```bash
./troubleshoot.sh
```

To use rule-based mode (no LLM, more reliable):
```bash
./apply-fix.sh
# Choose option 1
```
DEPLOYEOF

# Create quick setup script for server
cat > /tmp/cyber-defense-deploy/setup-server.sh << 'SETUPEOF'
#!/bin/bash
# Quick setup script for Hetzner server

echo "╔════════════════════════════════════════════════════════╗"
echo "║  492-Energy-Defense - Hetzner Setup                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root"
    exit 1
fi

echo "📦 Step 1: Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

echo ""
echo "🔧 Step 2: Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    # Install docker-compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

echo ""
echo "📝 Step 3: Creating environment file..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env file"
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🚀 Step 4: Starting services..."
chmod +x *.sh
docker-compose up -d

echo ""
echo "⏳ Step 5: Waiting for model download..."
echo "   (This will take 1-2 minutes)"
sleep 15

echo ""
echo "📊 Checking status..."
docker-compose ps

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🎉 Setup Complete!                                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Your services are starting up..."
echo ""
echo "🌐 Access Points:"
echo "   • Dashboard: http://$(hostname -I | awk '{print $1}'):3000"
echo "   • API:       http://$(hostname -I | awk '{print $1}'):8000"
echo "   • API Docs:  http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "📝 Next Steps:"
echo "   1. Wait 2-3 minutes for initialization"
echo "   2. Check model status: ./check-qwen-model.sh"
echo "   3. Monitor logs: docker-compose logs -f"
echo ""
echo "🔒 Security Recommendations:"
echo "   • Configure firewall: ufw allow 22,3000,8000/tcp && ufw enable"
echo "   • Change database password in docker-compose.yml"
echo "   • Use HTTPS in production"
echo ""
SETUPEOF

chmod +x /tmp/cyber-defense-deploy/setup-server.sh

# Create the tar.gz
echo ""
echo "📦 Creating archive..."
cd /tmp
tar -czf "/workspace/${PACKAGE_NAME}" cyber-defense-deploy/

# Cleanup
rm -rf /tmp/cyber-defense-deploy

echo ""
echo "✅ Package created: ${PACKAGE_NAME}"
echo ""
echo "📊 Package size:"
ls -lh "/workspace/${PACKAGE_NAME}" | awk '{print "   " $5}'
echo ""
echo "📤 To deploy to Hetzner:"
echo ""
echo "1. Upload to your server:"
echo "   scp ${PACKAGE_NAME} root@YOUR_SERVER_IP:/root/"
echo ""
echo "2. On the server, extract and run:"
echo "   cd /root"
echo "   tar -xzf ${PACKAGE_NAME}"
echo "   cd cyber-defense-deploy"
echo "   ./setup-server.sh"
echo ""
echo "Done! 🚀"
