# NetBird Monitoring Stack — Build Plan

## Phase 1: 專案腳手架 (30m)
- [x] 建立目錄結構
- [x] 撰寫 AGENTS.md（架構 + 角色閉環）
- [x] 撰寫 docker-compose.yml（7 組件 + monitoring-net 172.19.0.0/16）
- [x] 撰寫 config/prometheus/prometheus.yml
- [x] 撰寫 config/rules/alerts.yml
- [x] 撰寫 config/grafana/datasources/datasources.yml
- [x] 撰寫 config/loki/loki.yml
- [x] 撰寫 config/promtail/promtail.yml
- [x] 撰寫 config/alertmanager/alertmanager.yml

## Phase 2: NetBird Network 配置 (15m)
- [ ] 執行 configure-monitoring.sh（需 NETBIRD_TOKEN）
- [ ] 確認 172.19.0.0/16 已加入 NetBird Networks
- [ ] 確認 routing peer 已指派

## Phase 3: Docker 部署 (15m)
- [ ] docker compose up -d
- [ ] 確認 7 容器皆 running
- [ ] 確認 Prometheus targets UP ≥ 4

## Phase 4: Grafana 設定 (15m)
- [ ] 自動匯入 Node Exporter Full dashboard (1860)
- [ ] 自動匯入 Docker Monitoring dashboard (893)
- [ ] 確認 Loki datasource 正常

## Phase 5: 驗證 (10m)
- [ ] 執行 verify-closed-loop.sh — 預期 8/8 PASS
- [ ] 從遠端 peer 測試 Grafana 存取

## Phase 6: 產品化 (選用, 2h)
- [ ] 加入 Slack/Telegram webhook 通知
- [ ] 加入 Grafana Cloud 免費 tier 作為備援
- [ ] 撰寫 AGENTS.md 產品說明（含 pricing）
- [ ] 發布到 GitHub + Product Hunt
