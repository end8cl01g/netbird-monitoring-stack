# NetBird Monitoring Stack

> **Self-hosted Prometheus + Grafana + Loki + Alertmanager.**  
> One `docker-compose up`, 7 containers, Zero Trust VPN access via NetBird.  
> Replaces Datadog at **$5-10/month VPS cost** instead of $15/host/month.

[![GitHub](https://img.shields.io/badge/github-source-blue?logo=github)](https://github.com/end8cl01g/netbird-monitoring-stack)
[![Status](https://img.shields.io/badge/status-production%20ready-green)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

## Demo

```
$ ./verify-closed-loop.sh

============================================
  NetBird Monitoring Stack — Verification
============================================

  PASS [2/8] Prometheus API reachable
  Active UP targets: 5

  PASS [3/8] Grafana API healthy
  PASS [4/8] Loki ready
  PASS [5/8] Promtail collecting logs (129 metrics)
  PASS [6/8] Alertmanager healthy
  PASS [7/8] node_exporter metrics flowing
  PASS [8/8] NetBird route active

  Results: 8/8 passed
```

## Architecture

```
Remote Peer ──► NetBird Mesh ──► Routing Peer (100.126.99.53)
                                       │
                              monitoring-net (172.19.0.0/16)
                              │       │       │       │
                          prometheus  grafana  loki   alertmanager
                            :9090      :3000   :3100    :9093
                              │         │        │
                          node_exporter  ─  cadvisor  ─  promtail
                           (host)         (docker)      (logs)
```

**Key difference from other monitoring stacks**: all services are accessible **only via NetBird WireGuard tunnel**. No firewall ports to open, no reverse proxy to configure, no TLS certificates to manage. If you're connected to the NetBird mesh, you have access.

## Quick Start

```bash
git clone https://github.com/end8cl01g/netbird-monitoring-stack.git
cd netbird-monitoring-stack

# Start all 7 containers
docker compose up -d

# Wait 15s, then verify
./verify-closed-loop.sh
```

Access Grafana at `http://localhost:3000` (admin/admin).

### Optional: NetBird Remote Access

```bash
export NETBIRD_TOKEN="nbp_xxx"
./configure-monitoring.sh
```

This creates a NetBird Network + Resource for `172.19.0.0/16` and assigns your routing peer. After propagation, any connected NetBird peer can access Grafana at `http://172.19.0.3:3000`.

## Components

| Service | IP | Port | Role |
|---------|-----|------|------|
| prometheus | 172.19.0.2 | 9090 | Metrics + alerting rules |
| grafana | 172.19.0.3 | 3000 | Dashboards (pre-loaded datasources) |
| loki | 172.19.0.4 | 3100 | Log aggregation |
| promtail | 172.19.0.5 | 9080 | Docker log auto-discovery |
| alertmanager | 172.19.0.6 | 9093 | Alert routing + dedup |
| node_exporter | 172.19.0.7 | 9100 | Host metrics (CPU, RAM, disk) |
| cadvisor | 172.19.0.8 | 8080 | Container metrics |

All services pinned to specific versions — no accidental breaking upgrades.

## Built-in Alerts

| Alert | Condition | Severity |
|-------|-----------|----------|
| HostHighCPU | CPU > 80% for 5m | warning |
| HostOutOfMemory | Available RAM < 10% | warning |
| HostDiskFull | Root disk < 10% free | critical |
| ContainerDown | Container not seen > 60s | critical |
| PrometheusTargetMissing | Any scrape target down | critical |

## Security

- All services bind to `127.0.0.1` only — no public exposure
- Grafana admin password via `GRAFANA_PASSWORD` env var
- All access through NetBird WireGuard tunnel (Zero Trust)
- Prometheus alerting rules fire on anomalies, not just downtime

## Cost Comparison

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| Datadog | $15/host + $12/host (APM) | 5 hosts = $135/mo |
| Grafana Cloud | $19 + usage | 10k series cap on free |
| **This stack** | **$5-10 VPS** | Unlimited hosts, metrics, logs |

## Why NetBird?

[NetBird](https://netbird.io) is an open-source WireGuard-based mesh VPN. Unlike Tailscale (proprietary coordination server) or Headscale (self-hosted but no routing peers), NetBird supports **Network Routing** — making a single peer act as a gateway for an entire subnet. This is what enables remote access to `172.19.0.0/16` without exposing any ports.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | 7 services + monitoring-net (172.19.0.0/16) |
| `configure-monitoring.sh` | NetBird API setup + deploy + Grafana dashboards |
| `verify-closed-loop.sh` | 8-item automated verification |
| `AGENTS.md` | Architecture guide for AI coding agents |
| `config/prometheus/prometheus.yml` | Scrape configs for all targets |
| `config/rules/alerts.yml` | 5 alerting rules |
| `config/grafana/datasources/` | Pre-provisioned Prometheus + Loki datasources |
| `config/loki/loki.yml` | Log storage config (168h retention) |
| `config/promtail/promtail.yml` | Docker log auto-discovery via socket |
| `config/alertmanager/alertmanager.yml` | Webhook routing with dedup |

## License

MIT
