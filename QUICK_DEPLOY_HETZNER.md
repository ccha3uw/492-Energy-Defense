# Quick Deploy to Hetzner - 3 Simple Steps

Perfect for root + password authentication.

---

## Step 1: Create Package (Local Machine)

```bash
./create-deployment-package.sh
```

Creates: `cyber-defense-20251202-XXXXXX.tar.gz`

---

## Step 2: Create Hetzner Server

1. Go to: https://console.hetzner.cloud/
2. Create server:
   - **Image**: Ubuntu 22.04
   - **Type**: CPX21 or CPX31
   - **Location**: Any
3. Save **root password** and **IP address**

---

## Step 3: Deploy

### Automatic (Recommended)

```bash
./DEPLOY_HETZNER_SIMPLE.sh
```

Enter IP and password when prompted. That's it!

### Manual (If you prefer)

```bash
# Upload package
scp cyber-defense-*.tar.gz root@YOUR_IP:/root/

# SSH to server
ssh root@YOUR_IP

# Deploy
apt update && apt install -y docker.io docker-compose curl jq
cd /root && tar -xzf cyber-defense-*.tar.gz
docker-compose up -d
```

---

## Access

After deployment (wait 2 minutes):

- **Dashboard**: http://YOUR_IP:3000
- **Agent API**: http://YOUR_IP:8000
- **Health**: http://YOUR_IP:8000/health

---

## Test

```bash
curl http://YOUR_IP:8000/health
```

Should return:
```json
{
  "status": "healthy",
  "service": "492-Energy-Defense Cyber Event Triage Agent"
}
```

---

## Management

### View Logs
```bash
ssh root@YOUR_IP
docker-compose logs -f
```

### Restart
```bash
ssh root@YOUR_IP
docker-compose restart
```

### Stop
```bash
ssh root@YOUR_IP
docker-compose down
```

---

## Files Created

- ✅ `create-deployment-package.sh` - Creates tar.gz
- ✅ `DEPLOY_HETZNER_SIMPLE.sh` - Automated deployment
- ✅ `HETZNER_SIMPLE_DEPLOY.md` - Detailed guide
- ✅ `QUICK_DEPLOY_HETZNER.md` - This file

---

## Cost

- **CPX21** (4GB RAM): ~€10/month - minimum
- **CPX31** (8GB RAM): ~€20/month - recommended

---

## That's It!

Three commands to deploy:
1. `./create-deployment-package.sh`
2. Create server on Hetzner
3. `./DEPLOY_HETZNER_SIMPLE.sh`

Done! 🚀
