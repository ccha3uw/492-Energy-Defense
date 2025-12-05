╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🚀 ONE-COMMAND HETZNER DEPLOYMENT                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

QUICK START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Create a Hetzner Cloud server:
   → https://console.hetzner.cloud/
   → Ubuntu 22.04 LTS
   → CPX21 or better (2+ vCPU, 4+ GB RAM)
   → Add your SSH key
   → Note the IP address

2. Run the deployment script:

   ./hetzner-deploy.sh YOUR_SERVER_IP

   Example:
   ./hetzner-deploy.sh 65.21.123.45

3. Wait 3-5 minutes for deployment to complete

4. Access your services:
   → Dashboard:  http://YOUR_SERVER_IP:3000
   → Agent API:  http://YOUR_SERVER_IP:8000
   → API Docs:   http://YOUR_SERVER_IP:8000/docs


WHAT GETS DEPLOYED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Docker & Docker Compose
✓ PostgreSQL database
✓ Ollama with Qwen 2.5 0.5B model
✓ AI Agent (FastAPI)
✓ Backend event generator
✓ Web dashboard
✓ All configuration files
✓ Management scripts


ESTIMATED COSTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CPX11 (2 vCPU, 4GB RAM):    ~€5/month   (rule-based mode)
CPX21 (3 vCPU, 8GB RAM):    ~€8/month   (LLM mode)
CPX31 (4 vCPU, 16GB RAM):   ~€15/month  (recommended)


REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Local Machine:
  • SSH client
  • SSH key configured for Hetzner server
  • Bash shell

Hetzner Server:
  • Ubuntu 22.04 or 24.04 LTS
  • Minimum 2 vCPU, 4GB RAM, 20GB disk
  • SSH access configured
  • Root or sudo access


AFTER DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configure Firewall:
  ssh root@YOUR_SERVER_IP
  ufw allow 22/tcp
  ufw allow 3000/tcp
  ufw allow 8000/tcp
  ufw enable

Test Your Deployment:
  curl http://YOUR_SERVER_IP:8000/health

View Logs:
  ssh root@YOUR_SERVER_IP
  cd /opt/cyber-defense
  docker-compose logs -f


MANAGEMENT COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

On the server (/opt/cyber-defense):

  docker-compose ps              # Check status
  docker-compose logs -f         # View logs
  docker-compose restart         # Restart all
  docker-compose down            # Stop all
  docker-compose up -d           # Start all
  
  ./check-qwen-model.sh          # Verify model
  ./test-llm-mode.sh             # Test agent
  ./apply-fix.sh                 # Fix scoring issues


TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SSH Connection Failed:
  • Verify IP address is correct
  • Check SSH key is configured
  • Test manually: ssh root@YOUR_SERVER_IP

Services Not Starting:
  docker-compose down
  docker-compose up -d
  docker-compose logs

Out of Memory:
  • Use rule-based mode (edit docker-compose.yml: USE_LLM=false)
  • Or upgrade server in Hetzner Console

Model Not Loading:
  docker exec ollama-qwen ollama pull qwen2.5:0.5b
  docker-compose restart agent


DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  HETZNER_DEPLOY_GUIDE.md    - Full deployment guide
  README.md                   - System documentation
  FIX_QWEN_SCORING_ISSUE.md   - Model accuracy fixes


SUPPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For issues:
  1. Check logs: docker-compose logs
  2. Check resources: docker stats
  3. See HETZNER_DEPLOY_GUIDE.md
  4. Full reset: docker-compose down -v && docker-compose up -d


═══════════════════════════════════════════════════════════════

Ready to deploy? Run:

  ./hetzner-deploy.sh YOUR_SERVER_IP

═══════════════════════════════════════════════════════════════
