---
title: How I Ditched Datadog and Built a Self-Hosted Monitoring Stack on a $5 VPS
published: false
description: Prometheus + Grafana + Loki + Alertmanager in one docker-compose. Access everything via NetBird VPN. Zero public ports. 8 automated verification checks.
tags: monitoring, devops, docker, selfhosted, tutorial
---

## The Problem

Datadog charges **$15 per host per month** for infrastructure monitoring. Add APM ($12/host), logs ($0.10/million events), and a 5-server setup costs **$135+/month** — $1,620/year.

For indie hackers and small teams, that's a painful line item.

The open-source alternatives (Prometheus + Grafana + Loki) are free, but wiring them up takes hours. Most tutorials leave you with a fragile setup that breaks on the next `apt upgrade`.

## The Solution

A single `docker-compose.yml` that spins up **7 containers** with pinned versions, pre-configured alerting, and a **verification script** that tells you in 3 seconds whether everything works.

Oh — and it's accessible from anywhere via NetBird Zero Trust VPN. No firewall ports, no reverse proxy, no TLS certs.

## What's Inside

```
Remote Peer ──► NetBird Mesh ──► Routing Peer
                                       │
                              monitoring-net (172.19.0.0/16)
                              │       │       │       │
                          prometheus  grafana  loki   alertmanager
                            :9090      :3000   :3100    :9093
                              │         │        │
                          node_exporter  ─  cadvisor  ─  promtail
```

| Service | Purpose |
|---------|---------|
| Prometheus | Metrics collection + alerting rules |
| Grafana | Dashboards (pre-configured datasources) |
| Loki | Log aggregation (168h retention) |
| Promtail | Docker log auto-discovery |
| Alertmanager | Alert dedup + webhook routing |
| Node Exporter | Host CPU/RAM/disk metrics |
| cAdvisor | Per-container metrics |

## Why NetBird?

[NetBird](https://netbird.io) creates a WireGuard mesh between your machines. The key feature is **Network Routing** — one peer acts as a gateway for a whole subnet. So your monitoring stack lives on `172.19.0.0/16`, and any connected peer can reach Grafana at `http://172.19.0.3:3000` without exposing anything to the internet.

If you've used Tailscale or Headscale, the concept is the same. NetBird adds a management API that makes routing peer assignment automatable via script.

## Built-in Alerts

| Alert | Condition |
|-------|-----------|
| CPU spike > 80% | 5 minute duration |
| Available memory < 10% | Immediate |
| Root disk < 10% free | Critical |
| Container down > 60s | Auto-detect |
| Scrape target missing | Per-job |

## The Verification Loop

The `verify-closed-loop.sh` script checks 8 things:

```
  PASS [2/8] Prometheus API reachable (5 targets UP)
  PASS [3/8] Grafana API healthy
  PASS [4/8] Loki ready
  PASS [5/8] Promtail collecting logs (129 metrics)
  PASS [6/8] Alertmanager healthy
  PASS [7/8] node_exporter metrics flowing
  PASS [8/8] NetBird route active
```

Run it after deployment, after config changes, or as a cron job. If it passes, the stack works.

## Deployment

```bash
git clone https://github.com/end8cl01g/netbird-monitoring-stack.git
cd netbird-monitoring-stack
docker compose up -d
./verify-closed-loop.sh
```

That's it. Grafana is at `http://localhost:3000` (admin/admin). Change the password immediately.

For remote access (optional):
```bash
export NETBIRD_TOKEN="nbp_xxx"
./configure-monitoring.sh
```

## Cost Comparison

| Service | Monthly | 5 hosts/year |
|---------|---------|-------------|
| Datadog Infrastructure | $15/host | $900 |
| Datadog + APM | $27/host | $1,620 |
| Grafana Cloud Pro | $19 + usage | ~$400 |
| **This stack** | **$5-10 VPS** | **$60-120** |

Numbers don't include logs pricing, which multiplies the SaaS cost further.

## Repo

https://github.com/end8cl01g/netbird-monitoring-stack

Star it if you find it useful. Issues and PRs welcome.

---

*This is my first open-source monitoring product. Built with NetBird for secure access, Docker Compose for deployment, and a verify-closed-loop.sh for peace of mind.*
