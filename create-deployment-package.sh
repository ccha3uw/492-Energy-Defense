#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Hetzner Deployment Package                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-deploy.tar.gz"

echo "Packaging files..."

# Create a clean directory structure
mkdir -p deploy-temp/cyber-defense

# Copy essential files
cp -r agent deploy-temp/cyber-defense/
cp -r backend deploy-temp/cyber-defense/
cp -r dashboard deploy-temp/cyber-defense/
cp docker-compose.yml deploy-temp/cyber-defense/
cp .env.example deploy-temp/cyber-defense/.env
cp README.md deploy-temp/cyber-defense/
cp check-qwen-model.sh deploy-temp/cyber-defense/
cp test-llm-mode.sh deploy-temp/cyber-defense/
cp apply-fix.sh deploy-temp/cyber-defense/

# Copy deployment scripts
cp HETZNER_DEPLOYMENT_GUIDE.md deploy-temp/cyber-defense/ 2>/dev/null || true

# Create the tar.gz
cd deploy-temp
tar -czf ../$PACKAGE_NAME cyber-defense/
cd ..

# Cleanup
rm -rf deploy-temp

# Get file size
SIZE=$(du -h $PACKAGE_NAME | cut -f1)

echo ""
echo "✅ Package created: $PACKAGE_NAME"
echo "   Size: $SIZE"
echo ""
echo "Next steps:"
echo "1. Upload to Hetzner: scp $PACKAGE_NAME root@YOUR_IP:/root/"
echo "2. SSH to server: ssh root@YOUR_IP"
echo "3. Extract and run setup"
echo ""
echo "See HETZNER_SIMPLE_DEPLOY.md for full instructions"

