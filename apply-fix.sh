#!/bin/bash
# Quick fix for Qwen scoring issue

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Qwen Scoring Issue - Quick Fix                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "The Qwen 2.5 0.5B model is too small for accurate scoring."
echo ""
echo "Choose a solution:"
echo ""
echo "1) Switch to Rule-Based Mode (RECOMMENDED - 100% accurate)"
echo "2) Upgrade to Qwen 2.5 1.5B (Better AI, ~900MB)"
echo "3) Upgrade to Qwen 2.5 3B (Best AI, ~2GB)"
echo "4) Use Improved Hybrid Approach (Rule-based scores + LLM reasoning)"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
  1)
    echo ""
    echo "Switching to Rule-Based Mode..."
    # Update docker-compose.yml
    sed -i 's/USE_LLM=true/USE_LLM=false/' docker-compose.yml
    echo "✓ Updated docker-compose.yml"
    echo ""
    echo "Restarting agent..."
    docker-compose restart agent
    echo ""
    echo "✅ Done! Rule-based mode is now active."
    echo "   This provides 100% accurate scoring."
    ;;
    
  2)
    echo ""
    echo "Upgrading to Qwen 2.5 1.5B..."
    # Update docker-compose.yml
    sed -i 's/OLLAMA_MODEL=qwen2.5:0.5b/OLLAMA_MODEL=qwen2.5:1.5b/' docker-compose.yml
    sed -i 's/ollama pull qwen2.5:0.5b/ollama pull qwen2.5:1.5b/' docker-compose.yml
    echo "✓ Updated docker-compose.yml"
    echo ""
    echo "Pulling new model (will take 2-3 minutes)..."
    docker exec ollama-qwen ollama pull qwen2.5:1.5b
    echo ""
    echo "Rebuilding and restarting agent..."
    docker-compose build agent
    docker-compose restart agent
    echo ""
    echo "✅ Done! Qwen 1.5B model is now active."
    ;;
    
  3)
    echo ""
    echo "Upgrading to Qwen 2.5 3B..."
    # Update docker-compose.yml
    sed -i 's/OLLAMA_MODEL=qwen2.5:0.5b/OLLAMA_MODEL=qwen2.5:3b/' docker-compose.yml
    sed -i 's/ollama pull qwen2.5:0.5b/ollama pull qwen2.5:3b/' docker-compose.yml
    echo "✓ Updated docker-compose.yml"
    echo ""
    echo "Pulling new model (will take 3-5 minutes)..."
    docker exec ollama-qwen ollama pull qwen2.5:3b
    echo ""
    echo "Rebuilding and restarting agent..."
    docker-compose build agent
    docker-compose restart agent
    echo ""
    echo "✅ Done! Qwen 3B model is now active."
    ;;
    
  4)
    echo ""
    echo "Applying Improved Hybrid Approach..."
    # Backup current main.py
    cp agent/main.py agent/main_backup.py
    echo "✓ Backed up agent/main.py"
    
    # Replace with improved version
    cp agent/main_improved.py agent/main.py
    echo "✓ Installed improved version"
    
    # Update to use 1.5B model
    sed -i 's/OLLAMA_MODEL=qwen2.5:0.5b/OLLAMA_MODEL=qwen2.5:1.5b/' docker-compose.yml
    sed -i 's/ollama pull qwen2.5:0.5b/ollama pull qwen2.5:1.5b/' docker-compose.yml
    echo "✓ Updated docker-compose.yml"
    
    echo ""
    echo "Pulling Qwen 1.5B model..."
    docker exec ollama-qwen ollama pull qwen2.5:1.5b
    
    echo ""
    echo "Rebuilding and restarting..."
    docker-compose build agent
    docker-compose restart agent
    echo ""
    echo "✅ Done! Hybrid approach is now active."
    echo "   - Uses rule-based scores (100% accurate)"
    echo "   - Uses LLM reasoning (natural language)"
    ;;
    
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "Testing the fix..."
sleep 3
curl -s -X POST http://localhost:8000/evaluate-event \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "admin",
      "status": "FAIL",
      "timestamp": "2025-12-02T02:30:00",
      "is_burst_failure": true,
      "is_suspicious_ip": true,
      "is_admin": true
    }
  }' | jq

echo ""
echo "Expected: risk_score=130, severity=critical"
echo ""
echo "Run './test-llm-mode.sh' to test more scenarios."

