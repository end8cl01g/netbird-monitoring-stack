# NetBird Monitoring Stack — Agent Guide

## 專案概述
Self-hosted Prometheus + Grafana + Loki + Alertmanager 監控棧，透過 NetBird 安全暴露給遠端團隊，省去 Datadog $15/host/month 費用。

## 架構

```
Remote Peer ──► NetBird Mesh ──► 100.126.99.53 (Routing Peer)
                                       │
                              monitoring-net (172.19.0.0/16)
                              │       │       │       │       │
                          prometheus  grafana  loki    alert   promtail
                            :9090      :3000   :3100   :9093    :9080
                                              │
                                          node_exporter:9100  (host)
                                          cadvisor:8080       (containers)
```

## 環境

| 項目 | 值 |
|------|-----|
| OS | Ubuntu 24.04.4 LTS |
| NetBird | v0.72.2（原生 daemon） |
| NetBird IP | 100.126.99.53/16 |
| Peer ID | d8j9mgbl0ubs73f23h2g |
| Docker | Engine 29.5.3 + Compose v5.1.4 |
| Monitoring subnet | 172.19.0.0/16 (monitoring-net) |
| 既有 Docker subnet | 172.18.0.0/16 (app-net) — 由 docker-gateway 專案管理 |

## 關鍵 API

### NetBird Management (`https://api.netbird.io/api`)
- `POST /api/networks` — 建立 Network
- `POST /api/networks/{id}/resources` — 加入子網資源
- `POST /api/networks/{id}/routers` — 指派 Routing Peer

### Grafana (`http://grafana:3000`, 初始 admin/admin)
- `POST /api/datasources` — 新增 Prometheus / Loki 資料源
- `POST /api/dashboards/import` — 匯入內建儀表板

### Prometheus (`http://prometheus:9090`)
- `/api/v1/targets` — 檢查所有 scrape target 狀態

## 角色閉環

### DevOps 職責
- 部署 docker-compose 監控棧
- 確保 `monitoring-net` 在 routing peer 可觸及網段
- 管理 Prometheus rules / Grafana dashboards

### NetSec/SRE 職責
- NetBird Networks API 配置、Zero Trust policy
- Grafana 密碼輪換、alert notification 通道設定
- `verify-closed-loop.sh` 自動驗證

### 閉環觸發流程

```
需求 → [架構規劃師] AGENTS.md → [工程師] docker-compose + configs
      → [驗證] verify-closed-loop.sh → [交付] 遠端 peer 可存取 Grafana
      → [迭代] 回饋修正架構
```

## 組件版本

| 組件 | Image | 用途 |
|------|-------|------|
| Prometheus | prom/prometheus:v2.55 | 指標收集 + 告警規則 |
| Grafana | grafana/grafana:11.3 | 視覺化儀表板 |
| Loki | grafana/loki:3.2 | 日誌聚合 |
| Promtail | grafana/promtail:3.2 | Docker 日誌收集 |
| Alertmanager | prom/alertmanager:v0.28 | 告警路由 |
| Node Exporter | prom/node-exporter:v1.8 | 主機指標 |
| cAdvisor | gcr.io/cadvisor/cadvisor:v0.49 | 容器指標 |

## 驗證命令

```bash
docker compose ps                    # 所有服務 running
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'  # 4+ targets UP
curl -s http://localhost:3000/api/health              # Grafana OK
curl -s http://localhost:3100/ready                   # Loki ready
curl -s http://localhost:9093/-/healthy               # Alertmanager OK
netbird status | grep Networks                         # 172.19.0.0/16 已推送
```

## 安全原則
1. 所有服務不綁 host port 0.0.0.0，只透過 NetBird 存取
2. Grafana admin 密碼啟動後立即更改
3. 監控資料不暴露於公開網路
4. Alertmanager 通知通道使用 webhook + 環境變數
