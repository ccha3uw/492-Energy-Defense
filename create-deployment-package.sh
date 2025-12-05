#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating tar.gz package..."
echo ""

# Create tar.gz excluding unnecessary files
tar -czf "$PACKAGE_NAME" \
  --exclude='.git' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='.env' \
  --exclude='venv' \
  --exclude='node_modules' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)
    echo "✅ Package created successfully!"
    echo ""
    echo "   File: $PACKAGE_NAME"
    echo "   Size: $SIZE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "NEXT STEPS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Upload to Hetzner server:"
    echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
    echo ""
    echo "2. SSH into your server:"
    echo "   ssh root@YOUR_SERVER_IP"
    echo ""
    echo "3. On the server, run:"
    echo "   tar -xzf $PACKAGE_NAME"
    echo "   cd $(basename $PACKAGE_NAME .tar.gz)"
    echo "   ./hetzner-deploy.sh"
    echo ""
else
    echo "❌ Failed to create package"
    exit 1
fi
