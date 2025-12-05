#!/bin/bash
# Complete automated deployment script for Hetzner server
# Usage: ./deploy-to-hetzner.sh <SERVER_IP> [SSH_USER]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="${1}"
SSH_USER="${2:-root}"
APP_DIR="/opt/cyber-defense"
BACKUP_DIR="/opt/cyber-defense/backups"

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         492 ENERGY DEFENSE - HETZNER DEPLOYMENT             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Validate input
if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Error: Server IP address required${NC}"
    echo ""
    echo "Usage: $0 <SERVER_IP> [SSH_USER]"
    echo ""
    echo "Example:"
    echo "  $0 65.21.123.45"
    echo "  $0 65.21.123.45 cyber"
    exit 1
fi

echo -e "${YELLOW}Deployment Configuration:${NC}"
echo "  Target Server: $SERVER_IP"
echo "  SSH User: $SSH_USER"
echo "  Install Directory: $APP_DIR"
echo ""

# Test SSH connection
echo -e "${YELLOW}[1/10] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no $SSH_USER@$SERVER_IP exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check server IP is correct: $SERVER_IP"
    echo "  2. Ensure SSH key is added to the server"
    echo "  3. Verify server is running"
    echo "  4. Try: ssh $SSH_USER@$SERVER_IP"
    exit 1
fi

# Check if already deployed
echo ""
echo -e "${YELLOW}[2/10] Checking existing installation...${NC}"
if ssh $SSH_USER@$SERVER_IP "[ -d $APP_DIR ]" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Existing installation found${NC}"
    read -p "Do you want to update (u) or reinstall (r)? [u/r]: " choice
    case $choice in
        r|R)
            echo "Backing up and removing old installation..."
            ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose down -v || true"
            ssh $SSH_USER@$SERVER_IP "mv $APP_DIR ${APP_DIR}.backup.$(date +%Y%m%d_%H%M%S) || true"
            echo -e "${GREEN}✓ Old installation backed up${NC}"
            ;;
        u|U)
            echo "Updating existing installation..."
            UPDATE_MODE=true
            ;;
        *)
            echo "Cancelled."
            exit 0
            ;;
    esac
else
    echo -e "${GREEN}✓ No existing installation${NC}"
fi

# Install prerequisites
echo ""
echo -e "${YELLOW}[3/10] Installing prerequisites on server...${NC}"
ssh $SSH_USER@$SERVER_IP 'bash -s' << 'ENDSSH'
set -e

# Update system
echo "Updating package list..."
apt-get update -qq

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt-get install -y -qq ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Install Docker Compose standalone if plugin not available
if ! docker compose version &> /dev/null; then
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        echo "✓ Docker Compose installed"
    fi
fi

# Install other utilities
echo "Installing utilities..."
apt-get install -y -qq jq curl wget nano htop

# Configure firewall
if ! command -v ufw &> /dev/null; then
    echo "Installing UFW firewall..."
    apt-get install -y -qq ufw
fi

echo "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 8000/tcp comment 'Agent API'
ufw allow 3000/tcp comment 'Dashboard'
ufw --force enable

echo "✓ Prerequisites installed"
ENDSSH

echo -e "${GREEN}✓ Server configured${NC}"

# Create directories
echo ""
echo -e "${YELLOW}[4/10] Creating application directories...${NC}"
ssh $SSH_USER@$SERVER_IP "mkdir -p $APP_DIR/{agent,backend,dashboard,data,backups,logs}"
echo -e "${GREEN}✓ Directories created${NC}"

# Upload application files
echo ""
echo -e "${YELLOW}[5/10] Uploading application files...${NC}"

# Determine source directory (parent of hetzner-deploy)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Upload files
echo "Uploading docker-compose.yml..."
scp -q "$SOURCE_DIR/docker-compose.yml" $SSH_USER@$SERVER_IP:$APP_DIR/

echo "Uploading agent files..."
scp -q -r "$SOURCE_DIR/agent"/* $SSH_USER@$SERVER_IP:$APP_DIR/agent/

echo "Uploading backend files..."
scp -q -r "$SOURCE_DIR/backend"/* $SSH_USER@$SERVER_IP:$APP_DIR/backend/

echo "Uploading dashboard files..."
scp -q -r "$SOURCE_DIR/dashboard"/* $SSH_USER@$SERVER_IP:$APP_DIR/dashboard/

echo "Uploading environment file..."
scp -q "$SOURCE_DIR/.env.example" $SSH_USER@$SERVER_IP:$APP_DIR/.env

echo "Uploading helper scripts..."
scp -q "$SOURCE_DIR/hetzner-deploy/status.sh" $SSH_USER@$SERVER_IP:$APP_DIR/
scp -q "$SOURCE_DIR/hetzner-deploy/backup.sh" $SSH_USER@$SERVER_IP:$APP_DIR/
scp -q "$SOURCE_DIR/hetzner-deploy/restore.sh" $SSH_USER@$SERVER_IP:$APP_DIR/

ssh $SSH_USER@$SERVER_IP "chmod +x $APP_DIR/*.sh"

echo -e "${GREEN}✓ Files uploaded${NC}"

# Configure for production
echo ""
echo -e "${YELLOW}[6/10] Configuring for production...${NC}"
ssh $SSH_USER@$SERVER_IP "bash -s" << ENDSSH
cd $APP_DIR

# Set production defaults
cat > .env << 'EOF'
# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=cyber_defense_2024
POSTGRES_DB=cyber_events
DATABASE_URL=postgresql://postgres:cyber_defense_2024@db:5432/cyber_events

# Agent Configuration
AGENT_URL=http://agent:8000/evaluate-event
OLLAMA_URL=http://ollama:11434/api/generate
OLLAMA_MODEL=qwen2.5:1.5b
USE_LLM=false

# Backend Configuration
SCHEDULE_INTERVAL=30
EOF

# Update docker-compose for production
sed -i 's/USE_LLM=true/USE_LLM=false/' docker-compose.yml
sed -i 's/qwen2.5:0.5b/qwen2.5:1.5b/' docker-compose.yml

echo "✓ Configuration complete"
ENDSSH

echo -e "${GREEN}✓ Production configuration applied${NC}"

# Build and start services
echo ""
echo -e "${YELLOW}[7/10] Building and starting services...${NC}"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose down -v 2>/dev/null || true"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose build --quiet"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose up -d"

echo -e "${GREEN}✓ Services started${NC}"

# Wait for services to be ready
echo ""
echo -e "${YELLOW}[8/10] Waiting for services to initialize...${NC}"
echo "This may take 2-3 minutes..."

# Wait for database
echo -n "Waiting for database..."
for i in {1..30}; do
    if ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker-compose exec -T db pg_isready -U postgres" &>/dev/null; then
        echo " Ready!"
        break
    fi
    sleep 2
    echo -n "."
done

# Wait for agent
echo -n "Waiting for agent..."
for i in {1..60}; do
    if ssh $SSH_USER@$SERVER_IP "curl -sf http://localhost:8000/health" &>/dev/null; then
        echo " Ready!"
        break
    fi
    sleep 2
    echo -n "."
done

echo -e "${GREEN}✓ Services initialized${NC}"

# Pull AI model (optional, in background if LLM mode is disabled)
echo ""
echo -e "${YELLOW}[9/10] Configuring AI model...${NC}"
echo "Note: Model download happens in background (1-2 minutes)"
ssh $SSH_USER@$SERVER_IP "cd $APP_DIR && docker exec -d ollama-qwen ollama pull qwen2.5:1.5b" || true
echo -e "${GREEN}✓ Model download initiated${NC}"

# Run health checks
echo ""
echo -e "${YELLOW}[10/10] Running health checks...${NC}"
ssh $SSH_USER@$SERVER_IP "$APP_DIR/status.sh"

# Final summary
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              ✓ DEPLOYMENT COMPLETE!                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}Access Information:${NC}"
echo ""
echo "  🌐 Agent API:     http://$SERVER_IP:8000"
echo "  📖 API Docs:      http://$SERVER_IP:8000/docs"
echo "  📊 Dashboard:     http://$SERVER_IP:3000 (start with: docker-compose up -d dashboard)"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo ""
echo "  # Check status"
echo "  ssh $SSH_USER@$SERVER_IP '$APP_DIR/status.sh'"
echo ""
echo "  # View logs"
echo "  ssh $SSH_USER@$SERVER_IP 'cd $APP_DIR && docker-compose logs -f'"
echo ""
echo "  # Test the agent"
echo "  curl http://$SERVER_IP:8000/health"
echo ""
echo "  # Enable LLM mode"
echo "  ssh $SSH_USER@$SERVER_IP"
echo "  cd $APP_DIR"
echo "  nano docker-compose.yml  # Change USE_LLM=true"
echo "  docker-compose restart agent"
echo ""
echo -e "${BLUE}Management:${NC}"
echo ""
echo "  Backup:   ssh $SSH_USER@$SERVER_IP '$APP_DIR/backup.sh'"
echo "  Restart:  ssh $SSH_USER@$SERVER_IP 'cd $APP_DIR && docker-compose restart'"
echo "  Stop:     ssh $SSH_USER@$SERVER_IP 'cd $APP_DIR && docker-compose down'"
echo "  Update:   ./deploy-to-hetzner.sh $SERVER_IP"
echo ""
echo -e "${GREEN}Deployment successful! 🚀${NC}"
echo ""

# Save deployment info
cat > deployment-info.txt << EOF
Deployment Information
======================
Date: $(date)
Server IP: $SERVER_IP
SSH User: $SSH_USER
Install Directory: $APP_DIR

Access URLs:
- Agent API: http://$SERVER_IP:8000
- API Docs: http://$SERVER_IP:8000/docs
- Dashboard: http://$SERVER_IP:3000

Quick Access:
ssh $SSH_USER@$SERVER_IP

Status Check:
ssh $SSH_USER@$SERVER_IP '$APP_DIR/status.sh'
EOF

echo -e "${YELLOW}Deployment info saved to: deployment-info.txt${NC}"
