# Ultra-Fast Hetzner Deployment (One-Command)

## 🚀 Fastest Method

### On Your Local Machine:

```bash
# 1. Create and upload package in one command
./create-deployment-package.sh && scp cyber-defense-deploy.tar.gz root@YOUR_IP:/root/
```

### On Hetzner Server (SSH as root):

```bash
# 2. One-liner to install everything
cd /root && tar -xzf cyber-defense-deploy.tar.gz && cd cyber-defense && curl -fsSL https://get.docker.com | sh && apt-get install -y docker-compose jq && docker-compose up -d && echo "✅ Installation complete! System starting..." && echo "Run: docker logs -f ollama-init to watch model download"
```

### Then wait for model (1-2 minutes):

```bash
docker logs -f ollama-init
# Wait for "Qwen model ready!"
```

**Done! System is running.**

---

## Access

```bash
# Test from server
curl http://localhost:8000/health

# Test from your computer
curl http://YOUR_SERVER_IP:8000/health

# Dashboard (browser)
http://YOUR_SERVER_IP:3000
```

---

## Setup Firewall (Recommended)

```bash
apt-get install -y ufw && ufw allow 22/tcp && ufw allow 8000/tcp && ufw allow 3000/tcp && ufw --force enable && ufw status
```

---

## Complete Copy-Paste Commands

### Local Machine:
```bash
./create-deployment-package.sh
scp cyber-defense-deploy.tar.gz root@YOUR_IP:/root/
ssh root@YOUR_IP
```

### On Server (after SSH):
```bash
cd /root && \
tar -xzf cyber-defense-deploy.tar.gz && \
cd cyber-defense && \
curl -fsSL https://get.docker.com | sh && \
apt-get update && \
apt-get install -y docker-compose jq ufw && \
docker-compose up -d && \
echo "⏳ Waiting for services to start..." && \
sleep 10 && \
echo "✅ Services started!" && \
echo "" && \
echo "Next: Watch model download with: docker logs -f ollama-init" && \
echo "Then access: http://$(curl -s ifconfig.me):3000"
```

---

## Check Everything Works

```bash
# All-in-one status check
docker ps && echo "" && curl -s http://localhost:8000/health | jq && echo "" && docker exec ollama-qwen ollama list
```

---

## Apply Security (After Testing)

```bash
# Setup firewall
ufw allow 22/tcp && \
ufw allow 8000/tcp && \
ufw allow 3000/tcp && \
ufw --force enable && \
echo "✅ Firewall enabled"
```

---

## Quick Management

```bash
# Stop
docker-compose down

# Start
docker-compose up -d

# Logs
docker-compose logs -f

# Status
docker-compose ps

# Restart
docker-compose restart
```

That's it! 🎉
