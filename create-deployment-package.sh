#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Package name
PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating tar.gz package..."
echo ""

# Create deployment package (exclude unnecessary files)
tar -czf "$PACKAGE_NAME" \
  --exclude='.git' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='.pytest_cache' \
  --exclude='*.log' \
  --exclude='venv' \
  --exclude='env' \
  --exclude='.env' \
  --exclude='*.swp' \
  --exclude='.DS_Store' \
  --exclude='*.tar.gz' \
  agent/ \
  backend/ \
  dashboard/ \
  docker-compose.yml \
  docker-compose-simple.yml \
  .env.example \
  .gitignore \
  README.md \
  start.sh \
  test-llm-mode.sh \
  troubleshoot.sh \
  check-qwen-model.sh \
  apply-fix.sh \
  manage.sh \
  test.sh \
  HETZNER_DEPLOY_SIMPLE.md \
  2>/dev/null

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)
    echo "✅ Package created successfully!"
    echo ""
    echo "📦 Package: $PACKAGE_NAME"
    echo "📊 Size: $SIZE"
    echo ""
    echo "Next steps:"
    echo "1. Copy this file to your Hetzner server:"
    echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
    echo ""
    echo "2. SSH to your server:"
    echo "   ssh root@YOUR_SERVER_IP"
    echo ""
    echo "3. Extract and run:"
    echo "   tar -xzf $PACKAGE_NAME"
    echo "   cd cyber-defense-*/  # or appropriate directory"
    echo "   ./HETZNER_DEPLOY_SIMPLE.md  # Follow the guide"
    echo ""
else
    echo "❌ Error creating package"
    exit 1
fi
