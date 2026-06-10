# NetBird Monitoring Stack — Self-Hosted Observability

## 問題
Datadog $15/host/month，5台主機一年 $900+，還不算 logs / APM。
自架 Prometheus + Grafana + Loki，一台 $5-10/month VPS 搞定。

## 目標結果

```
Remote Peer ──► NetBird Mesh ──► 100.126.99.53 (Routing Peer)
                                       │
                              monitoring-net (172.19.0.0/16)
                              │       │       │       │       │
                          prometheus  grafana  loki    alert   promtail
                            :9090      :3000   :3100   :9093    :9080
                                              │
                                          node_exporter  cadvisor
                                           (host metrics) (container metrics)
```

閉環：遠端團隊透過 NetBird 存取完整監控棧，無需公開 endpoint。

---

## 角色閉環

### 架構規劃師
```
需求分析 → 技術選型 → AGENTS.md → todo.md 任務分解 → 交付工程師
```

### 程式執行工程師
```
AGENTS.md → docker-compose → configs → compose up → verify 腳本
```

### 收斂點：verify-closed-loop.sh 8 項全 PASS

---

## 順向執行步驟

### Phase 1: 專案初始化
```bash
git clone <this-repo> netbird-monitoring-stack
cd netbird-monitoring-stack
```

### Phase 2: NetBird 網路設定
```bash
export NETBIRD_TOKEN="nbp_xxx"
./configure-monitoring.sh
```
腳本會：
- 建立 NetBird Network `monitoring-stack`
- 加入 Resource `172.19.0.0/16`
- 指派 Routing Peer + masquerade

### Phase 3: Docker 部署
```bash
docker compose up -d
# 等待 15 秒初始化
```

### Phase 4: 驗證
```bash
./verify-closed-loop.sh
# 預期 8/8 PASS
```

### Phase 5: 遠端存取
從任何 NetBird 連線的 peer：
```bash
curl http://172.19.0.3:3000   # Grafana
curl http://172.19.0.2:9090   # Prometheus
```

---

## 組件對照

| Service | Container IP | Port | 功能 |
|---------|-------------|------|------|
| prometheus | 172.19.0.2 | 9090 | 指標收集 + 告警 |
| grafana | 172.19.0.3 | 3000 | 儀表板 |
| loki | 172.19.0.4 | 3100 | 日誌聚合 |
| promtail | 172.19.0.5 | 9080 | Docker 日誌收集 |
| alertmanager | 172.19.0.6 | 9093 | 告警路由 |
| node_exporter | 172.19.0.7 | 9100 | 主機指標 |
| cadvisor | 172.19.0.8 | 8080 | 容器指標 |

## 安全原則
1. 全部容器只綁 `monitoring-net`，不開 host port
2. Grafana 管理員密碼透過 `GRAFANA_PASSWORD` env 設定
3. 全部流量經 NetBird WireGuard tunnel
4. Prometheus alerting rules 內建告警

## 下一步
- [ ] Grafana 加入 LDAP/OAuth SSO
- [ ] 設定 Alertmanager Slack/Telegram 通知
- [ ] 加入 Thanos 長期儲存（S3 冷資料）
- [ ] 部署到 Kubernetes via kube-prometheus-stack
