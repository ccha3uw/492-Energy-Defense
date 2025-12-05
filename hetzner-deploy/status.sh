#!/bin/bash
# Status check script for deployed application

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         492 Energy Defense - System Status                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Docker
echo -e "${YELLOW}[1/6] Docker Status${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker installed${NC}"
    docker --version
else
    echo -e "${RED}✗ Docker not found${NC}"
    exit 1
fi
echo ""

# Check containers
echo -e "${YELLOW}[2/6] Container Status${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|cyber|ollama"
echo ""

# Check services health
echo -e "${YELLOW}[3/6] Service Health Checks${NC}"

# Database
echo -n "Database: "
if docker exec cyber-events-db pg_isready -U postgres &>/dev/null; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${RED}✗ Unhealthy${NC}"
fi

# Ollama
echo -n "Ollama: "
if curl -sf http://localhost:11434/api/tags &>/dev/null; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${RED}✗ Unhealthy${NC}"
fi

# Agent
echo -n "Agent: "
if curl -sf http://localhost:8000/health &>/dev/null; then
    echo -e "${GREEN}✓ Healthy${NC}"
    AGENT_INFO=$(curl -s http://localhost:8000/health)
    MODE=$(echo "$AGENT_INFO" | jq -r '.mode' 2>/dev/null || echo "unknown")
    MODEL=$(echo "$AGENT_INFO" | jq -r '.model' 2>/dev/null || echo "unknown")
    echo "  Mode: $MODE"
    echo "  Model: $MODEL"
else
    echo -e "${RED}✗ Unhealthy${NC}"
fi

# Backend
echo -n "Backend: "
if docker ps | grep -q cyber-backend; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
fi

echo ""

# Check models
echo -e "${YELLOW}[4/6] AI Models${NC}"
MODELS=$(docker exec ollama-qwen ollama list 2>/dev/null || echo "")
if [ -n "$MODELS" ]; then
    echo "$MODELS"
else
    echo -e "${YELLOW}⚠ No models loaded yet${NC}"
    echo "Run: docker exec ollama-qwen ollama pull qwen2.5:1.5b"
fi
echo ""

# Check resource usage
echo -e "${YELLOW}[5/6] Resource Usage${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6
echo ""

# Check database stats
echo -e "${YELLOW}[6/6] Database Statistics${NC}"
EVENT_COUNT=$(docker exec cyber-events-db psql -U postgres -d cyber_events -t -c "SELECT COUNT(*) FROM event_analyses" 2>/dev/null | xargs || echo "0")
echo "Total Events Analyzed: $EVENT_COUNT"

CRITICAL_COUNT=$(docker exec cyber-events-db psql -U postgres -d cyber_events -t -c "SELECT COUNT(*) FROM event_analyses WHERE severity='critical'" 2>/dev/null | xargs || echo "0")
echo "Critical Events: $CRITICAL_COUNT"

echo ""

# Overall status
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
if docker ps | grep -q cyber-agent && curl -sf http://localhost:8000/health &>/dev/null; then
    echo -e "${GREEN}✓ System is operational${NC}"
else
    echo -e "${RED}✗ System has issues${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  View logs: docker-compose logs"
    echo "  Restart:   docker-compose restart"
    echo "  Rebuild:   docker-compose down && docker-compose up -d"
fi
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
