#!/bin/bash
# Simple deployment script for Hetzner using password authentication

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Deploy to Hetzner Server (Password Auth)             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if server IP provided
if [ -z "$1" ]; then
    echo "❌ Error: Server IP address required"
    echo ""
    echo "Usage: $0 <SERVER_IP> [PASSWORD]"
    echo ""
    echo "Example:"
    echo "  $0 65.21.123.45"
    echo "  $0 65.21.123.45 yourpassword"
    echo ""
    exit 1
fi

SERVER_IP="$1"
PASSWORD="$2"

echo "Server: $SERVER_IP"
echo ""

# Create deployment package if it doesn't exist
if [ ! -f cyber-defense-*.tar.gz ]; then
    echo "Creating deployment package..."
    ./create-deployment-package.sh
    echo ""
fi

# Get the latest package
PACKAGE=$(ls -t cyber-defense-*.tar.gz | head -1)

if [ -z "$PACKAGE" ]; then
    echo "❌ Error: No deployment package found"
    echo "Run: ./create-deployment-package.sh"
    exit 1
fi

echo "Using package: $PACKAGE"
echo ""

# Function to run commands with password or prompt
run_ssh() {
    if [ -n "$PASSWORD" ]; then
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER_IP "$1"
    else
        ssh -o StrictHostKeyChecking=no root@$SERVER_IP "$1"
    fi
}

run_scp() {
    if [ -n "$PASSWORD" ]; then
        sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no "$1" root@$SERVER_IP:"$2"
    else
        scp -o StrictHostKeyChecking=no "$1" root@$SERVER_IP:"$2"
    fi
}

# Check if sshpass is available for password auth
if [ -n "$PASSWORD" ]; then
    if ! command -v sshpass &> /dev/null; then
        echo "⚠️  Warning: sshpass not installed. Install it for password authentication:"
        echo "    Ubuntu/Debian: apt install sshpass"
        echo "    macOS: brew install hudochenkov/sshpass/sshpass"
        echo ""
        echo "Falling back to interactive SSH (you'll need to enter password manually)..."
        PASSWORD=""
    fi
fi

echo "═══════════════════════════════════════════════════════"
echo "STEP 1: Testing Connection"
echo "═══════════════════════════════════════════════════════"
echo ""

if run_ssh "echo 'Connection successful'"; then
    echo "✅ Connection to $SERVER_IP successful"
else
    echo "❌ Cannot connect to $SERVER_IP"
    echo ""
    echo "Make sure:"
    echo "  - Server is running"
    echo "  - IP address is correct"
    echo "  - Password is correct (if provided)"
    echo "  - SSH is enabled on the server"
    exit 1
fi
echo ""

echo "═══════════════════════════════════════════════════════"
echo "STEP 2: Installing Docker"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Checking if Docker is installed..."
if run_ssh "docker --version" 2>/dev/null; then
    echo "✅ Docker is already installed"
else
    echo "Installing Docker..."
    run_ssh "curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh"
    echo "✅ Docker installed"
fi
echo ""

echo "Checking if Docker Compose is installed..."
if run_ssh "docker-compose --version" 2>/dev/null; then
    echo "✅ Docker Compose is already installed"
else
    echo "Installing Docker Compose..."
    run_ssh "apt update && apt install -y docker-compose"
    echo "✅ Docker Compose installed"
fi
echo ""

echo "═══════════════════════════════════════════════════════"
echo "STEP 3: Uploading Application"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Uploading $PACKAGE to server..."
run_scp "$PACKAGE" "/root/"
echo "✅ Package uploaded"
echo ""

echo "Extracting package..."
PACKAGE_NAME=$(basename "$PACKAGE")
run_ssh "cd /root && tar -xzf $PACKAGE_NAME && cd 492-energy-defense && ls -la"
echo "✅ Package extracted"
echo ""

echo "═══════════════════════════════════════════════════════"
echo "STEP 4: Starting Services"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Starting Docker containers..."
run_ssh "cd /root/492-energy-defense && docker-compose up -d"
echo "✅ Services started"
echo ""

echo "Waiting for services to initialize (30 seconds)..."
sleep 30
echo ""

echo "═══════════════════════════════════════════════════════"
echo "STEP 5: Verification"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Checking container status..."
run_ssh "cd /root/492-energy-defense && docker ps"
echo ""

echo "Checking agent health..."
run_ssh "curl -s http://localhost:8000/health" || echo "⚠️  Agent not responding yet (may need more time)"
echo ""

echo "═══════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Your application is now running on: $SERVER_IP"
echo ""
echo "Access Points:"
echo "  • Dashboard:  http://$SERVER_IP:3000"
echo "  • API:        http://$SERVER_IP:8000"
echo "  • API Docs:   http://$SERVER_IP:8000/docs"
echo ""
echo "Useful Commands (run on server):"
echo "  • View logs:      docker logs -f cyber-agent"
echo "  • Check status:   docker ps"
echo "  • Restart:        docker-compose restart"
echo "  • Stop:           docker-compose down"
echo ""
echo "To SSH into your server:"
echo "  ssh root@$SERVER_IP"
echo ""
echo "Note: If you see 'low' severity for critical events:"
echo "  ssh root@$SERVER_IP 'cd /root/492-energy-defense && ./apply-fix.sh'"
echo ""

