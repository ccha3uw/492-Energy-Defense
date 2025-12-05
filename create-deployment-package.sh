#!/bin/bash
# Create deployment package for Hetzner

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Creating Deployment Package for Hetzner              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PACKAGE_NAME="cyber-defense-agent-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "Creating package: $PACKAGE_NAME"
echo ""

# Create list of files to include
cat > /tmp/package-files.txt << 'FILELIST'
agent/
backend/
dashboard/
docker-compose.yml
docker-compose-simple.yml
.env.example
.gitignore
README.md
PROJECT_SUMMARY.md
start.sh
test-llm-mode.sh
troubleshoot.sh
check-qwen-model.sh
apply-fix.sh
manage.sh
test.sh
start-simple.sh
test-dashboard-updates.sh
test-db_connection.sh
FIX_QWEN_SCORING_ISSUE.md
MIGRATION_COMPLETE.md
MODEL_MIGRATION_SUMMARY.md
FILELIST

echo "Files to include:"
cat /tmp/package-files.txt
echo ""

# Create the tarball
echo "Creating tarball..."
tar -czf "$PACKAGE_NAME" \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='.git' \
  --exclude='*.log' \
  --exclude='.env' \
  -T /tmp/package-files.txt 2>/dev/null

if [ $? -eq 0 ]; then
    SIZE=$(ls -lh "$PACKAGE_NAME" | awk '{print $5}')
    echo ""
    echo "✅ Package created successfully!"
    echo ""
    echo "📦 File: $PACKAGE_NAME"
    echo "📊 Size: $SIZE"
    echo ""
    echo "Next steps:"
    echo "1. Upload this file to your Hetzner server"
    echo "2. Extract: tar -xzf $PACKAGE_NAME"
    echo "3. Run: cd workspace && ./start.sh"
    echo ""
    echo "Or use the quick deploy script:"
    echo "  ./deploy-tarball.sh <server-ip> <password>"
else
    echo "❌ Failed to create package"
    exit 1
fi

rm /tmp/package-files.txt
