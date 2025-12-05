#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Packaging project files..."

# Create tar.gz excluding unnecessary files
tar -czf "$PACKAGE_NAME" \
  --exclude='.git' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='*.log' \
  --exclude='.env' \
  --exclude='venv' \
  --exclude='node_modules' \
  --exclude='*.tar.gz' \
  --exclude='*.backup' \
  --exclude='*_backup.py' \
  --exclude='main_improved.py' \
  .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)
    echo ""
    echo "✅ Package created successfully!"
    echo ""
    echo "   File: $PACKAGE_NAME"
    echo "   Size: $SIZE"
    echo ""
    echo "Next steps:"
    echo "1. Upload this file to your Hetzner server"
    echo "2. Run the deployment script on the server"
    echo ""
    echo "Quick upload command:"
    echo "   scp $PACKAGE_NAME root@YOUR_SERVER_IP:/root/"
    echo ""
else
    echo "❌ Failed to create package"
    exit 1
fi
