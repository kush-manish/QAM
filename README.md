# QAM — QuantAgentManager

Distributed multi-agent orchestration for F.R.I.D.A.Y (Mac) + J.E.R.V.I.S (VPS).

## Architecture
- **Hub**: VPS Flask (`web_ui.py`) — single source of truth
- **F.R.I.D.A.Y**: macOS agent (code, plan, review)
- **J.E.R.V.I.S**: VPS worker (exec, deploy, docker, git)
- **QUANTFLASH PM**: Board at http://168.231.103.220:9200/admin/pm/

## Features
- ✅ Agent heartbeat (every 2min) — online/offline detection
- ✅ Master election — highest-priority online node
- ✅ Task queue — F.R.I.D.A.Y dispatches, J.E.R.V.I.S executes
- ✅ System metrics — CPU/RAM/Disk per agent (ring buffer 24h)
- ✅ Monitoring tab — Chart.js graphs in QUANTFLASH
- ✅ Copilot usage tracking — tokens per minute, 7-day history
- ✅ Agent message bus — broadcast pool + DMs

## Scripts
- `scripts/friday_heartbeat.sh` — macOS heartbeat (cron every 2min)
- `scripts/jervis_heartbeat.sh` — Linux VPS heartbeat (cron every 2min)

## API Endpoints (VPS)
- `GET/POST /backup/api/qam/metrics` — system resource ring buffer
- `GET/POST /backup/api/qam/copilot` — copilot usage log
- `GET/POST /backup/api/qam/messages` — broadcast message pool
- `POST /backup/api/qam/messages/dm/<node>` — direct message
- `GET /backup/api/qam/status` — cluster status
- `POST /backup/api/qam/nodes/heartbeat` — agent heartbeat
