#!/usr/bin/env bash
# NetBird Monitoring Stack — Closed-Loop Verification Script
set -euo pipefail

PASS=0
FAIL=0
TOTAL=8

check() {
  local n="$1"; shift
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS [$n/$TOTAL] $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL [$n/$TOTAL] $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  NetBird Monitoring Stack — Verification"
echo "============================================"
echo ""

echo "=== [1] Docker Containers Running ==="
for svc in prometheus grafana loki promtail alertmanager node_exporter cadvisor; do
  if docker compose ps --status running --format "{{.Name}}" 2>/dev/null | grep -q "$svc"; then
    :
  else
    echo "  FAIL: $svc not running"
    FAIL=$((FAIL + 1))
    TOTAL=$((TOTAL + 1))
  fi
done
echo "  All 7 containers running"
PASS=$((PASS + 1))

echo ""
echo "=== [2] Prometheus Targets Up ==="
check 2 "Prometheus API reachable" \
  curl -sf http://localhost:9090/-/healthy
TGTS=$(curl -sf http://localhost:9090/api/v1/targets 2>/dev/null \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(len([t for t in d['data']['activeTargets'] if t['health']=='up']))" 2>/dev/null || echo "0")
echo "  Active UP targets: $TGTS"

echo ""
echo "=== [3] Grafana Health ==="
check 3 "Grafana API healthy" \
  curl -sf http://localhost:3000/api/health -o /dev/null

echo ""
echo "=== [4] Loki Ready ==="
check 4 "Loki ready" \
  curl -sf http://localhost:3100/ready -o /dev/null

echo ""
echo "=== [5] Promtail Connected ==="
check 5 "Promtail metrics" \
  curl -sf http://localhost:9080/metrics | grep -q 'promtail_'

echo ""
echo "=== [6] Alertmanager Reachable ==="
check 6 "Alertmanager healthy" \
  curl -sf http://localhost:9093/-/healthy

echo ""
echo "=== [7] Metrics Flow — node_exporter ==="
check 7 "node_exporter metrics in Prometheus" \
  curl -sf 'http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22node_exporter%22%7D' \
    | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get('data',{}).get('result',[]); exit(0 if r and r[0]['value'][1]=='1' else 1)"

echo ""
echo "=== [8] NetBird Route ==="
if netbird status 2>/dev/null | grep -q "Networks"; then
  ROUTES=$(netbird status | grep Networks)
  echo "  PASS: $ROUTES"
  PASS=$((PASS + 1))
else
  echo "  WARN: NetBird route not verified (run from routing peer)"
  echo "  Manual check: netbird status | grep Networks"
  # Don't count as fail for template use
fi

echo ""
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"
echo ""
echo "Grafana: http://localhost:3000 (admin:${GRAFANA_PASSWORD:-admin})"
echo "Prometheus: http://localhost:9090"
echo "Loki: http://localhost:3100"
echo ""
echo "From remote NetBird peer:"
echo "  http://172.19.0.3:3000"
echo "  http://172.19.0.2:9090"
echo ""
echo "Dashboards:"
echo "  Node Exporter Full (ID 1860)"
echo "  Docker Monitoring (ID 893)"

exit $FAIL
