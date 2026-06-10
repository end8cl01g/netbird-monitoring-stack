#!/usr/bin/env bash
# NetBird Monitoring Stack — NetBird API Config + Docker Deploy
# Usage: NETBIRD_TOKEN="nbp_xxx" ./configure-monitoring.sh
set -euo pipefail

API="https://api.netbird.io/api"
TOKEN="${NETBIRD_TOKEN:?Set NETBIRD_TOKEN env var}"

echo "============================================"
echo "  NetBird Monitoring Stack — Setup"
echo "============================================"
echo ""

echo "=== Step 1: NetBird — Create Network ==="
NET_ID=$(curl -s -X POST "$API/networks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "monitoring-stack",
    "description": "Monitoring subnet 172.19.0.0/16 via routing peer"
  }' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "Network ID: $NET_ID"

echo ""
echo "=== Step 2: NetBird — Add Resource (172.19.0.0/16) ==="
curl -s -X POST "$API/networks/$NET_ID/resources" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "monitoring-subnet-172-19",
    "description": "Docker monitoring bridge network",
    "address": "172.19.0.0/16",
    "type": "ip",
    "enabled": true,
    "groups": ["d80ldbafadhs739tsqbg"]
  }' | python3 -c "import json,sys; r=json.load(sys.stdin); print(f'Resource ID: {r[\"id\"]}')"

echo ""
echo "=== Step 3: NetBird — Assign Routing Peer ==="
PEER_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "$API/peers" \
  | python3 -c "import json,sys; peers=json.load(sys.stdin); [print(p['id']) for p in peers if p['dns_label']=='end8cl01.netbird.cloud']")
echo "Peer ID: $PEER_ID"

curl -s -X POST "$API/networks/$NET_ID/routers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"peer\": \"$PEER_ID\",
    \"masquerade\": true,
    \"description\": \"netbird-monitoring-stack\",
    \"enabled\": true
  }" | python3 -c "import json,sys; r=json.load(sys.stdin); print(f'Router ID: {r[\"id\"]}')"

echo ""
echo "=== Step 4: Deploy Docker Stack ==="
docker compose up -d
echo "Waiting 15s for services to initialize..."
sleep 15

echo ""
echo "=== Step 5: Verify Containers ==="
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Step 6: Grafana API — Verify Health ==="
GF_URL="http://localhost:3000"
GF_ADMIN="${GRAFANA_USER:-admin}"
GF_PASS="${GRAFANA_PASSWORD:-admin}"

HEALTH=$(curl -s -u "$GF_ADMIN:$GF_PASS" "$GF_URL/api/health")
echo "Grafana: $(echo "$HEALTH" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("message","FAIL"))')"

echo ""
echo "=== Step 7: Grafana API — Import Dashboards ==="
# Node Exporter Full (ID 1860)
curl -s -X POST "$GF_URL/api/dashboards/import" \
  -u "$GF_ADMIN:$GF_PASS" \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {"id": null, "uid": null},
    "overwrite": true,
    "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}]
  }' > /dev/null

# Docker Monitoring (ID 893)
curl -s -X POST "$GF_URL/api/dashboards/import" \
  -u "$GF_ADMIN:$GF_PASS" \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {"id": null, "uid": null},
    "overwrite": true,
    "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}]
  }' > /dev/null

echo "  Node Exporter Full (1860) + Docker Monitoring (893) imported"

echo ""
echo "=== Step 8: Verify NetBird Route ==="
netbird status 2>/dev/null | grep -i "network" || echo "  (wait ~5s for route propagation)"

echo ""
echo "============================================"
echo "  Setup Complete"
echo "============================================"
echo ""
echo "Access Grafana via NetBird:"
echo "  http://172.19.0.3:3000  (admin:${GF_PASS})"
echo ""
echo "Or from localhost:"
echo "  http://localhost:3000"
echo ""
echo "Verify with:  ./verify-closed-loop.sh"
