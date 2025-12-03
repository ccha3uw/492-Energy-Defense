# How to Load Qwen Model into Docker Container

## Automatic Method (Recommended)

The Qwen model is automatically downloaded when you start the system using the `ollama-init` service.

### Steps:

1. **Start all services:**
```bash
docker-compose up -d
```

2. **Monitor the model download:**
```bash
docker logs -f ollama-init
```

You should see:
```
Waiting for Ollama to be ready...
Pulling Qwen model...
pulling manifest
pulling [model layers...]
verifying sha256 digest
writing manifest
removing any unused layers
success
Qwen model ready!
```

3. **Verify the model is loaded:**
```bash
# Check available models in Ollama
docker exec ollama-qwen ollama list
```

Expected output should include:
```
NAME              ID              SIZE      MODIFIED
qwen2.5:0.5b      abc123def456    400 MB    X minutes ago
```

---

## Manual Method (If Automatic Fails)

If the automatic download doesn't work, you can manually pull the model:

### Option 1: Pull from running container

```bash
# Make sure Ollama container is running
docker-compose up -d ollama

# Wait 10 seconds for Ollama to initialize
sleep 10

# Pull the model manually
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

### Option 2: Interactive pull

```bash
# Enter the container
docker exec -it ollama-qwen bash

# Inside the container, pull the model
ollama pull qwen2.5:0.5b

# Verify it's there
ollama list

# Exit the container
exit
```

---

## Verification Steps

### 1. Check if model exists
```bash
docker exec ollama-qwen ollama list
```

### 2. Test the model works
```bash
docker exec ollama-qwen ollama run qwen2.5:0.5b "Hello, test message"
```

### 3. Check from the agent
```bash
# Agent health check (shows which model it's using)
curl http://localhost:8000/health | jq
```

Should return:
```json
{
  "status": "healthy",
  "service": "492-Energy-Defense Cyber Event Triage Agent",
  "mode": "LLM",
  "ollama_url": "http://ollama:11434/api/generate",
  "model": "qwen2.5:0.5b"
}
```

### 4. Test event analysis
```bash
curl -X POST http://localhost:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "test",
      "src_ip": "192.168.1.100",
      "status": "SUCCESS",
      "timestamp": "2025-12-02T10:00:00",
      "is_admin": false,
      "is_burst_failure": false,
      "is_suspicious_ip": false
    }
  }' | jq
```

---

## Troubleshooting

### Problem: Model not found

**Check container is running:**
```bash
docker ps | grep ollama-qwen
```

**Check Ollama logs:**
```bash
docker logs ollama-qwen
```

**Restart and retry:**
```bash
docker-compose restart ollama
sleep 10
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

### Problem: Pull fails with network error

**Use alternative registry (if available):**
```bash
# Default pulls from Ollama's registry
docker exec ollama-qwen ollama pull qwen2.5:0.5b

# If that fails, try without tag specification and let it use latest
docker exec ollama-qwen ollama pull qwen2.5
```

### Problem: Container restarts constantly

**Check memory:**
```bash
docker stats ollama-qwen --no-stream
```

**Check if container has enough resources:**
- Qwen 0.5B needs at least 2GB RAM
- Check `docker-compose.yml` has appropriate memory limits

### Problem: Model downloaded but agent can't access it

**Verify network connectivity:**
```bash
# From inside agent container
docker exec cyber-agent curl http://ollama:11434/api/tags
```

**Check model name matches:**
```bash
# Check what agent is looking for
docker exec cyber-agent env | grep OLLAMA_MODEL

# Check what's available
docker exec ollama-qwen ollama list
```

---

## Model Location in Container

The model is stored inside the Ollama container at:
```
/root/.ollama/models/
```

This location is persisted using Docker volumes (`ollama_data`), so you won't need to re-download the model if you restart containers.

### Check volume
```bash
# List volumes
docker volume ls | grep ollama

# Inspect volume
docker volume inspect workspace_ollama_data
```

---

## Complete Reset (If All Else Fails)

If you need to start fresh:

```bash
# Stop everything
docker-compose down

# Remove the Ollama volume (this deletes the model)
docker volume rm workspace_ollama_data

# Start fresh (will re-download model)
docker-compose up -d

# Watch it download
docker logs -f ollama-init
```

---

## Quick Check Script

Create a quick verification script:

```bash
#!/bin/bash
echo "Checking Qwen model status..."
echo ""

echo "1. Ollama container status:"
docker ps | grep ollama-qwen
echo ""

echo "2. Models in Ollama:"
docker exec ollama-qwen ollama list
echo ""

echo "3. Agent health:"
curl -s http://localhost:8000/health | jq .model
echo ""

echo "4. Ollama API accessible from agent:"
docker exec cyber-agent curl -s http://ollama:11434/api/tags | head -20
echo ""

echo "✅ All checks complete!"
```

Save as `check-qwen-model.sh` and run:
```bash
chmod +x check-qwen-model.sh
./check-qwen-model.sh
```

---

## Summary

**Easiest way:**
```bash
docker-compose up -d
docker logs -f ollama-init  # Wait for "Qwen model ready!"
docker exec ollama-qwen ollama list  # Verify it's there
```

**If that fails:**
```bash
docker exec ollama-qwen ollama pull qwen2.5:0.5b
```

**Model should be ~400MB and take 1-2 minutes to download.**
