#!/bin/bash
# Main deployment script for Hetzner server
# Usage: ./deploy.sh <SERVER_IP> [OPTIONS]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
SSH_USER="root"
DEPLOY_PATH="/opt/cyber-defense"
USE_LLM="false"
MODEL="qwen2.5:1.5b"
UPDATE_MODE="false"
VERBOSE="false"
DOMAIN=""

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║        492-ENERGY-DEFENSE HETZNER DEPLOYMENT                   ║"
    echo "║        Easy One-Command Deployment to Hetzner Cloud            ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Usage
usage() {
    echo "Usage: $0 <SERVER_IP> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --user USER          SSH user (default: root)"
    echo "  --llm                Enable LLM mode"
    echo "  --rule-based         Use rule-based mode (default, recommended)"
    echo "  --model MODEL        Qwen model to use (default: qwen2.5:1.5b)"
    echo "  --domain DOMAIN      Setup with domain name"
    echo "  --update             Update existing deployment"
    echo "  --verbose            Verbose output"
    echo "  -h, --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 65.21.123.45"
    echo "  $0 65.21.123.45 --llm --model qwen2.5:3b"
    echo "  $0 65.21.123.45 --domain cyberdefense.example.com"
    echo "  $0 65.21.123.45 --update"
    exit 1
}

# Parse arguments
SERVER_IP=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            SSH_USER="$2"
            shift 2
            ;;
        --llm)
            USE_LLM="true"
            shift
            ;;
        --rule-based)
            USE_LLM="false"
            shift
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --update)
            UPDATE_MODE="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP="$1"
            else
                echo -e "${RED}Unknown option: $1${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Check if SERVER_IP is provided
if [ -z "$SERVER_IP" ]; then
    print_banner
    echo -e "${RED}Error: Server IP address required${NC}"
    echo ""
    usage
fi

print_banner

echo -e "${GREEN}Deployment Configuration:${NC}"
echo "  Server IP:        $SERVER_IP"
echo "  SSH User:         $SSH_USER"
echo "  Deploy Path:      $DEPLOY_PATH"
echo "  LLM Mode:         $USE_LLM"
echo "  Model:            $MODEL"
echo "  Update Mode:      $UPDATE_MODE"
echo "  Domain:           ${DOMAIN:-Not configured}"
echo ""

# Confirm
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""

# Step 1: Test SSH connection
echo -e "${YELLOW}[1/8] Testing SSH connection...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes ${SSH_USER}@${SERVER_IP} exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to server${NC}"
    echo "Please ensure:"
    echo "  1. Server IP is correct"
    echo "  2. SSH key is properly configured"
    echo "  3. Server is running"
    exit 1
fi
echo ""

# Step 2: Prepare server (if not update mode)
if [ "$UPDATE_MODE" = "false" ]; then
    echo -e "${YELLOW}[2/8] Preparing server...${NC}"
    
    # Copy server setup script
    scp hetzner-deploy/server-setup.sh ${SSH_USER}@${SERVER_IP}:/tmp/
    
    # Run setup
    ssh ${SSH_USER}@${SERVER_IP} "bash /tmp/server-setup.sh"
    
    echo -e "${GREEN}✓ Server prepared${NC}"
else
    echo -e "${YELLOW}[2/8] Skipping server preparation (update mode)${NC}"
fi
echo ""

# Step 3: Create deployment directory
echo -e "${YELLOW}[3/8] Creating deployment directory...${NC}"
ssh ${SSH_USER}@${SERVER_IP} "mkdir -p ${DEPLOY_PATH}"
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

# Step 4: Copy application files
echo -e "${YELLOW}[4/8] Copying application files...${NC}"

# Go to project root
cd "$(dirname "$0")/.."

# Copy files using rsync
rsync -avz --progress \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'node_modules' \
    --exclude '.env' \
    --exclude 'hetzner-deploy/.env.local' \
    ./ ${SSH_USER}@${SERVER_IP}:${DEPLOY_PATH}/

echo -e "${GREEN}✓ Files copied${NC}"
echo ""

# Step 5: Configure environment
echo -e "${YELLOW}[5/8] Configuring environment...${NC}"

# Create .env file
ssh ${SSH_USER}@${SERVER_IP} "cat > ${DEPLOY_PATH}/.env << 'EOF'
# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@db:5432/cyber_events
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=cyber_events

# Agent Configuration
AGENT_URL=http://agent:8000/evaluate-event
OLLAMA_URL=http://ollama:11434/api/generate
OLLAMA_MODEL=${MODEL}
USE_LLM=${USE_LLM}

# Dashboard Configuration
DASHBOARD_PORT=3000
EOF
"

echo -e "${GREEN}✓ Environment configured${NC}"
echo ""

# Step 6: Pull and start services
echo -e "${YELLOW}[6/8] Starting Docker services...${NC}"

if [ "$UPDATE_MODE" = "true" ]; then
    ssh ${SSH_USER}@${SERVER_IP} "cd ${DEPLOY_PATH} && docker-compose down"
fi

ssh ${SSH_USER}@${SERVER_IP} "cd ${DEPLOY_PATH} && docker-compose build --no-cache"
ssh ${SSH_USER}@${SERVER_IP} "cd ${DEPLOY_PATH} && docker-compose up -d"

echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Step 7: Wait for services
echo -e "${YELLOW}[7/8] Waiting for services to be ready...${NC}"
echo "This may take 2-3 minutes..."

# Wait for database
echo -n "Waiting for database..."
for i in {1..30}; do
    if ssh ${SSH_USER}@${SERVER_IP} "cd ${DEPLOY_PATH} && docker-compose exec -T db pg_isready -U postgres" &>/dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for agent
echo -n "Waiting for agent..."
for i in {1..30}; do
    if ssh ${SSH_USER}@${SERVER_IP} "curl -f -s http://localhost:8000/health" &>/dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for dashboard
echo -n "Waiting for dashboard..."
for i in {1..30}; do
    if ssh ${SSH_USER}@${SERVER_IP} "curl -f -s http://localhost:3000/health" &>/dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""

# Step 8: Health check
echo -e "${YELLOW}[8/8] Running health checks...${NC}"

AGENT_STATUS=$(ssh ${SSH_USER}@${SERVER_IP} "curl -s http://localhost:8000/health | jq -r .status" 2>/dev/null || echo "unknown")
DASHBOARD_STATUS=$(ssh ${SSH_USER}@${SERVER_IP} "curl -s http://localhost:3000/health | jq -r .status" 2>/dev/null || echo "unknown")
DB_STATUS=$(ssh ${SSH_USER}@${SERVER_IP} "cd ${DEPLOY_PATH} && docker-compose exec -T db pg_isready -U postgres" &>/dev/null && echo "healthy" || echo "unhealthy")

echo "  Database:   $DB_STATUS"
echo "  Agent:      $AGENT_STATUS"
echo "  Dashboard:  $DASHBOARD_STATUS"
echo ""

# Success message
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║              🎉 DEPLOYMENT SUCCESSFUL! 🎉                      ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Access your application:${NC}"
echo ""
echo "  📊 Dashboard:     http://${SERVER_IP}:3000"
echo "  🤖 Agent API:     http://${SERVER_IP}:8000"
echo "  📚 API Docs:      http://${SERVER_IP}:8000/docs"
echo "  🔐 SSH Access:    ssh ${SSH_USER}@${SERVER_IP}"
echo ""

echo -e "${BLUE}Quick Commands:${NC}"
echo ""
echo "  # View logs"
echo "  ssh ${SSH_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH} && docker-compose logs -f'"
echo ""
echo "  # Check status"
echo "  ssh ${SSH_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH} && docker-compose ps'"
echo ""
echo "  # Restart services"
echo "  ssh ${SSH_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH} && docker-compose restart'"
echo ""
echo "  # Run health check"
echo "  ssh ${SSH_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH}/hetzner-deploy && ./health-check.sh'"
echo ""

if [ -n "$DOMAIN" ]; then
    echo -e "${YELLOW}Setup SSL/HTTPS:${NC}"
    echo "  ssh ${SSH_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH}/hetzner-deploy && ./setup-ssl.sh ${DOMAIN} your@email.com'"
    echo ""
fi

echo -e "${GREEN}Deployment complete! 🚀${NC}"
echo ""
