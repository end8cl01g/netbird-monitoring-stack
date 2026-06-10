# Product Hunt Launch: NetBird Monitoring Stack

## Tagline
Self-hosted Prometheus + Grafana + Loki stack. One docker-compose, 7 containers, Zero Trust VPN access.

## Description

**Replace Datadog at <10% of the cost.** A self-hosted Prometheus + Grafana + Loki + Alertmanager monitoring stack that deploys in 10 minutes and is accessible from anywhere via NetBird WireGuard mesh — no public ports, no reverse proxy, no TLS management.

**What makes this different:**
- 7 containers, pinned versions, one docker-compose up
- Pre-configured alerting (CPU >80%, memory <10%, disk <10%, container down, target missing)
- verify-closed-loop.sh — 8 automated checks that confirm everything works
- NetBird Network Routing — remote team access without exposing endpoints
- Costs $5-10/month VPS instead of $135+/month for Datadog

**Who it's for:**
Indie hackers, small dev teams, and anyone tired of SaaS observability pricing. If you can run docker-compose, you can have production-grade monitoring in 10 minutes.

**Stack:**
- Prometheus (metrics + alerting rules)
- Grafana (dashboards with pre-loaded datasources)
- Loki + Promtail (Docker log auto-discovery)
- Alertmanager (alert dedup + webhook)
- Node Exporter + cAdvisor (host + container metrics)

**Links:**
GitHub: https://github.com/end8cl01g/netbird-monitoring-stack

## First Comment
Built this because I was tired of paying Datadog $135/month for a 5-server setup. The open-source alternatives (Prometheus/Grafana/Loki) are excellent but wiring them up takes hours and the result is often fragile.

The key insight: combine them with NetBird for access control. No nginx reverse proxy, no Let's Encrypt, no opening firewall ports. Your mesh VPN handles everything.

Everything is pinned to specific versions. The verify script gives you confidence after every change. Fork it, customize it, make it yours.

## Topics
monitoring, devops, docker, self-hosted, prometheus, grafana, open-source, indie-hacking

## Images/GIFs
[Verification output]
[Architecture diagram]
[Grafana dashboard screenshot]
