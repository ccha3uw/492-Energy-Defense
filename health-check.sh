#!/bin/bash
# Health check script for deployed application
# Usage: ./health-check.sh <SERVER_IP>

SERVER_IP="${1:-localhost}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Health Check - 492-Energy-Defense Cybersecurity Agent      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Dashboard
echo -n "Checking Dashboard (port 3000)... "
if curl -f -s "http://$SERVER_IP:3000/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Check API
echo -n "Checking Agent API (port 8000)... "
if curl -f -s "http://$SERVER_IP:8000/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    
    # Show API details
    echo ""
    echo "API Details:"
    curl -s "http://$SERVER_IP:8000/health" | jq -r '
        "  Status: \(.status)",
        "  Mode: \(.mode)",
        "  Model: \(.model // "N/A")"
    '
else
    echo -e "${RED}✗ FAILED${NC}"
fi
echo ""

# Check Database (if accessible)
echo -n "Checking Database (port 5432)... "
if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$SERVER_IP/5432" 2>/dev/null; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${YELLOW}⚠ Not accessible (may be firewalled)${NC}"
fi
echo ""

# Test event analysis
echo "Testing event analysis..."
RESPONSE=$(curl -s -X POST "http://$SERVER_IP:8000/evaluate-event" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "login",
    "data": {
      "username": "test",
      "status": "SUCCESS",
      "timestamp": "2025-12-02T10:00:00",
      "is_admin": false,
      "is_burst_failure": false,
      "is_suspicious_ip": false
    }
  }' 2>/dev/null)

if [ ! -z "$RESPONSE" ]; then
    echo -e "${GREEN}✓ Event analysis working${NC}"
    echo ""
    echo "Sample response:"
    echo "$RESPONSE" | jq '
        "  Risk Score: \(.risk_score)",
        "  Severity: \(.severity)",
        "  Reasoning: \(.reasoning)"
    '
else
    echo -e "${RED}✗ Event analysis failed${NC}"
fi
echo ""

echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Dashboard: http://$SERVER_IP:3000"
echo "API Docs:  http://$SERVER_IP:8000/docs"
echo ""
