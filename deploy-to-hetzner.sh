#!/bin/bash
#
# 492-Energy-Defense - One-Click Hetzner Deployment Script
# Run this on your Hetzner server to install everything
#
# Usage: curl -fsSL https://raw.githubusercontent.com/your-repo/main/deploy-to-hetzner.sh | sudo bash
# Or: wget -qO- https://raw.githubusercontent.com/your-repo/main/deploy-to-hetzner.sh | sudo bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   492-ENERGY-DEFENSE CYBERSECURITY AGENT                 ║
║   Hetzner Deployment Script                              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Run with: sudo bash $0"
    exit 1
fi

# Get server info
echo -e "${YELLOW}Detecting server configuration...${NC}"
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
CPU_CORES=$(nproc)
DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}')

echo "  RAM: ${TOTAL_RAM}GB"
echo "  CPU Cores: ${CPU_CORES}"
echo "  Available Disk: ${DISK_SPACE}"
echo ""

# Check minimum requirements
if [ "$TOTAL_RAM" -lt 4 ]; then
    echo -e "${YELLOW}⚠ Warning: Less than 4GB RAM detected. System may run slowly.${NC}"
    echo "  Recommended: 8GB+ RAM for optimal performance"
    echo ""
fi

# Configuration
echo -e "${BLUE}[1/8] Configuration${NC}"
read -p "Enter deployment user (default: cyber): " DEPLOY_USER
DEPLOY_USER=${DEPLOY_USER:-cyber}
DEPLOY_DIR="/home/$DEPLOY_USER/cyber-agent"

read -p "Enable LLM mode? (y/N): " ENABLE_LLM
if [[ $ENABLE_LLM =~ ^[Yy]$ ]]; then
    USE_LLM="true"
    echo "  Which model?"
    echo "    1) Rule-based (No LLM, fastest, most accurate)"
    echo "    2) Qwen 1.5B (Good balance, ~900MB)"
    echo "    3) Qwen 3B (Best AI, ~2GB)"
    read -p "  Choice (1-3): " MODEL_CHOICE
    
    case $MODEL_CHOICE in
        2) OLLAMA_MODEL="qwen2.5:1.5b" ;;
        3) OLLAMA_MODEL="qwen2.5:3b" ;;
        *) USE_LLM="false"; OLLAMA_MODEL="qwen2.5:0.5b" ;;
    esac
else
    USE_LLM="false"
    OLLAMA_MODEL="qwen2.5:0.5b"
fi

echo ""
echo "Configuration:"
echo "  User: $DEPLOY_USER"
echo "  Install Dir: $DEPLOY_DIR"
echo "  LLM Mode: $USE_LLM"
echo "  Model: $OLLAMA_MODEL"
echo ""
read -p "Continue with this configuration? (Y/n): " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

# Update system
echo -e "${BLUE}[2/8] Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

# Install dependencies
echo -e "${BLUE}[3/8] Installing dependencies...${NC}"
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    jq \
    ufw \
    fail2ban

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Install Docker
echo -e "${BLUE}[4/8] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start Docker
    systemctl enable docker
    systemctl start docker
    
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

# Create deployment user
echo -e "${BLUE}[5/8] Setting up user account...${NC}"
if ! id "$DEPLOY_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$DEPLOY_USER"
    echo -e "${GREEN}✓ User '$DEPLOY_USER' created${NC}"
else
    echo -e "${GREEN}✓ User '$DEPLOY_USER' already exists${NC}"
fi

# Add user to docker group
usermod -aG docker "$DEPLOY_USER"
echo -e "${GREEN}✓ User added to docker group${NC}"
echo ""

# Download/clone application
echo -e "${BLUE}[6/8] Downloading application...${NC}"

# Create directory
mkdir -p "$DEPLOY_DIR"

# Copy files from current directory if we're already in the repo
if [ -f "./docker-compose.yml" ]; then
    echo "  Copying files from current directory..."
    cp -r ./* "$DEPLOY_DIR/"
    echo -e "${GREEN}✓ Files copied${NC}"
else
    # Try to clone from git if available
    echo "  Attempting to clone from repository..."
    if [ -n "$GIT_REPO" ]; then
        git clone "$GIT_REPO" "$DEPLOY_DIR"
        echo -e "${GREEN}✓ Repository cloned${NC}"
    else
        echo -e "${YELLOW}⚠ No repository specified. Please copy files manually to $DEPLOY_DIR${NC}"
        echo "  Required files:"
        echo "    - docker-compose.yml"
        echo "    - agent/"
        echo "    - backend/"
        echo "    - dashboard/"
    fi
fi

# Set ownership
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_DIR"
echo ""

# Configure application
echo -e "${BLUE}[7/8] Configuring application...${NC}"

# Update docker-compose.yml with chosen settings
cd "$DEPLOY_DIR"

if [ -f "docker-compose.yml" ]; then
    # Update LLM settings
    sed -i "s/USE_LLM=.*/USE_LLM=$USE_LLM/" docker-compose.yml
    sed -i "s/OLLAMA_MODEL=.*/OLLAMA_MODEL=$OLLAMA_MODEL/" docker-compose.yml
    
    # If not using LLM, comment out ollama services
    if [ "$USE_LLM" = "false" ]; then
        echo "  Disabling Ollama services (not needed for rule-based mode)..."
        # Use docker-compose-simple.yml if available
        if [ -f "docker-compose-simple.yml" ]; then
            cp docker-compose-simple.yml docker-compose.yml
        fi
    fi
    
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    echo -e "${RED}✗ docker-compose.yml not found${NC}"
    echo "  Please copy your application files to: $DEPLOY_DIR"
    exit 1
fi
echo ""

# Configure firewall
echo -e "${BLUE}[8/8] Configuring firewall...${NC}"

# Enable UFW if not already enabled
if ! ufw status | grep -q "Status: active"; then
    # Allow SSH first (important!)
    ufw allow 22/tcp comment 'SSH'
    
    # Enable UFW
    ufw --force enable
fi

# Allow application ports
ufw allow 3000/tcp comment 'Cyber Dashboard'
ufw allow 8000/tcp comment 'Agent API'

# Configure fail2ban for SSH protection
if [ -f "/etc/fail2ban/jail.conf" ]; then
    systemctl enable fail2ban
    systemctl start fail2ban
    echo -e "${GREEN}✓ Fail2ban enabled${NC}"
fi

echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

# Start application
echo -e "${BLUE}Starting application...${NC}"
echo ""

cd "$DEPLOY_DIR"

# Pull images and start services as deployment user
su - "$DEPLOY_USER" -c "cd $DEPLOY_DIR && docker compose pull"
su - "$DEPLOY_USER" -c "cd $DEPLOY_DIR && docker compose up -d"

echo ""
echo -e "${YELLOW}Waiting for services to start...${NC}"

# Wait for database
sleep 10

# Check if ollama needs to pull model
if [ "$USE_LLM" = "true" ]; then
    echo -e "${YELLOW}Pulling AI model (this may take 2-5 minutes)...${NC}"
    su - "$DEPLOY_USER" -c "cd $DEPLOY_DIR && docker logs -f ollama-init" &
    LOGS_PID=$!
    
    # Wait for model to be ready
    for i in {1..300}; do
        if docker logs ollama-init 2>&1 | grep -q "model ready"; then
            kill $LOGS_PID 2>/dev/null || true
            break
        fi
        sleep 1
    done
    echo ""
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Final status check
echo ""
echo -e "${BLUE}Checking service status...${NC}"
sleep 5

SERVICES_OK=true

# Check agent
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Agent API: Running${NC}"
else
    echo -e "${RED}✗ Agent API: Not responding${NC}"
    SERVICES_OK=false
fi

# Check dashboard
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Dashboard: Running${NC}"
else
    echo -e "${RED}✗ Dashboard: Not responding${NC}"
    SERVICES_OK=false
fi

# Check database
if docker exec cyber-events-db pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database: Running${NC}"
else
    echo -e "${RED}✗ Database: Not responding${NC}"
    SERVICES_OK=false
fi

echo ""

# Success banner
if [ "$SERVICES_OK" = true ]; then
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ✓ DEPLOYMENT SUCCESSFUL!                               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "Your 492-Energy-Defense system is now running!"
    echo ""
    echo "Access URLs:"
    echo "  Dashboard:    http://$SERVER_IP:3000"
    echo "  Agent API:    http://$SERVER_IP:8000"
    echo "  API Docs:     http://$SERVER_IP:8000/docs"
    echo ""
    echo "Local access (from server):"
    echo "  Dashboard:    http://localhost:3000"
    echo "  Agent API:    http://localhost:8000"
    echo ""
    echo "Useful Commands:"
    echo "  Switch to user:   sudo su - $DEPLOY_USER"
    echo "  View logs:        docker compose -f $DEPLOY_DIR/docker-compose.yml logs -f"
    echo "  Stop services:    docker compose -f $DEPLOY_DIR/docker-compose.yml down"
    echo "  Restart:          docker compose -f $DEPLOY_DIR/docker-compose.yml restart"
    echo "  Status:           docker compose -f $DEPLOY_DIR/docker-compose.yml ps"
    echo ""
    echo "Configuration:"
    echo "  Install dir:      $DEPLOY_DIR"
    echo "  LLM mode:         $USE_LLM"
    if [ "$USE_LLM" = "true" ]; then
        echo "  Model:            $OLLAMA_MODEL"
    fi
    echo ""
    echo "Security:"
    echo "  Firewall (UFW):   Active"
    echo "  Fail2ban:         Active"
    echo "  Allowed ports:    22 (SSH), 3000 (Dashboard), 8000 (API)"
    echo ""
    
else
    echo -e "${YELLOW}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ⚠ DEPLOYMENT COMPLETED WITH WARNINGS                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "Some services may not be running properly."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check logs:      docker compose -f $DEPLOY_DIR/docker-compose.yml logs"
    echo "  2. Check status:    docker compose -f $DEPLOY_DIR/docker-compose.yml ps"
    echo "  3. Restart all:     docker compose -f $DEPLOY_DIR/docker-compose.yml restart"
    echo "  4. View this guide: cat $DEPLOY_DIR/README.md"
    echo ""
fi

# Create helper script
cat > /usr/local/bin/cyber-agent << EOFSCRIPT
#!/bin/bash
# Helper script for cyber-agent management

case "\$1" in
    start)
        echo "Starting cyber-agent..."
        cd $DEPLOY_DIR && docker compose up -d
        ;;
    stop)
        echo "Stopping cyber-agent..."
        cd $DEPLOY_DIR && docker compose down
        ;;
    restart)
        echo "Restarting cyber-agent..."
        cd $DEPLOY_DIR && docker compose restart
        ;;
    logs)
        cd $DEPLOY_DIR && docker compose logs -f
        ;;
    status)
        cd $DEPLOY_DIR && docker compose ps
        ;;
    update)
        echo "Updating cyber-agent..."
        cd $DEPLOY_DIR && git pull && docker compose pull && docker compose up -d
        ;;
    *)
        echo "Cyber-Agent Management Script"
        echo ""
        echo "Usage: cyber-agent {start|stop|restart|logs|status|update}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all services"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  logs    - View live logs"
        echo "  status  - Show service status"
        echo "  update  - Update and restart"
        ;;
esac
EOFSCRIPT

chmod +x /usr/local/bin/cyber-agent
echo -e "${GREEN}✓ Helper command 'cyber-agent' installed${NC}"
echo ""

echo "Quick commands:"
echo "  cyber-agent status    - Check status"
echo "  cyber-agent logs      - View logs"
echo "  cyber-agent restart   - Restart services"
echo ""

echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open http://$SERVER_IP:3000 in your browser"
echo "  2. Wait for first event generation cycle (30 minutes)"
echo "  3. Monitor with: cyber-agent logs"
echo ""
