# Product Hunt Launch: NetBird Monitoring Stack

## Tagline
Self-hosted monitoring with NetBird VPN. One docker-compose.

## Description

Replace Datadog at <10% the cost. Self-hosted Prometheus + Grafana + Loki + Alertmanager in one docker-compose. Deploys in 10 minutes, accessible via NetBird WireGuard mesh — no public ports, no reverse proxy. 7 containers with pinned versions, pre-configured alerting (CPU, memory, disk, container down), and a verification script. Costs $5-10/month VPS instead of $135+/month. For indie hackers and small teams.

Links: https://github.com/end8cl01g/netbird-monitoring-stack

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
