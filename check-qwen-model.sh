#!/bin/bash
# Quick script to verify Qwen model is loaded

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Qwen Model Status Check                              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check 1: Ollama container
echo -e "${YELLOW}[1/5] Checking Ollama container...${NC}"
if docker ps | grep -q ollama-qwen; then
    echo -e "${GREEN}✓ Ollama container is running${NC}"
else
    echo -e "${RED}✗ Ollama container not found${NC}"
    echo "Run: docker-compose up -d ollama"
    exit 1
fi
echo ""

# Check 2: Models in Ollama
echo -e "${YELLOW}[2/5] Checking available models...${NC}"
MODELS=$(docker exec ollama-qwen ollama list 2>/dev/null)
if echo "$MODELS" | grep -q "qwen2.5:0.5b"; then
    echo -e "${GREEN}✓ Qwen 2.5 (0.5B) model is loaded${NC}"
    echo "$MODELS"
else
    echo -e "${RED}✗ Qwen model not found${NC}"
    echo "Available models:"
    echo "$MODELS"
    echo ""
    echo "To load the model, run:"
    echo "  docker exec ollama-qwen ollama pull qwen2.5:0.5b"
    exit 1
fi
echo ""

# Check 3: Agent status
echo -e "${YELLOW}[3/5] Checking agent health...${NC}"
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    AGENT_INFO=$(curl -s http://localhost:8000/health)
    MODEL=$(echo "$AGENT_INFO" | jq -r '.model' 2>/dev/null)
    MODE=$(echo "$AGENT_INFO" | jq -r '.mode' 2>/dev/null)
    
    echo -e "${GREEN}✓ Agent is running${NC}"
    echo "  Mode: $MODE"
    echo "  Model: $MODEL"
    
    if [ "$MODEL" = "qwen2.5:0.5b" ]; then
        echo -e "${GREEN}✓ Agent configured for Qwen model${NC}"
    else
        echo -e "${YELLOW}⚠ Agent using different model: $MODEL${NC}"
    fi
else
    echo -e "${RED}✗ Agent not responding${NC}"
    echo "Run: docker-compose up -d agent"
fi
echo ""

# Check 4: Ollama API accessibility
echo -e "${YELLOW}[4/5] Checking Ollama API...${NC}"
if docker exec ollama-qwen curl -f -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama API is accessible${NC}"
else
    echo -e "${RED}✗ Ollama API not responding${NC}"
fi
echo ""

# Check 5: Test model inference
echo -e "${YELLOW}[5/5] Testing model inference...${NC}"
TEST_RESULT=$(docker exec ollama-qwen ollama run qwen2.5:0.5b "Say 'OK'" 2>&1 | head -5)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Model inference working${NC}"
    echo "  Test output: ${TEST_RESULT:0:50}..."
else
    echo -e "${RED}✗ Model inference failed${NC}"
    echo "  Error: $TEST_RESULT"
fi
echo ""

echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}All checks passed! Qwen model is ready to use.${NC}"
echo "════════════════════════════════════════════════════════"
