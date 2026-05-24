# QuantAgentManager (QAM)

Distributed multi-agent coordination system for QUANTFLASH.

## Architecture

```
┌─────────────────────────────────────────────┐
│              QAM HUB (VPS)                  │
│   Bridge API — always online, priority 100  │
│   Stores: nodes.json, queue.json            │
│   Election: highest priority = master       │
└────────────┬──────────────────┬─────────────┘
             │                  │
    ┌────────▼───────┐  ┌───────▼────────┐
    │  F.R.I.D.A.Y   │  │  J.E.R.V.I.S  │
    │  (local mac)   │  │  (VPS worker)  │
    │  priority: 80  │  │  priority: 100 │
    │  orchestrator  │  │  worker/master │
    └────────────────┘  └────────────────┘
             + node3, node4 (future)
```

## Key Rules — Credit Saving

| Task type | Route to | LLM cost |
|-----------|----------|----------|
| exec / deploy / docker / git shell | J.E.R.V.I.S (VPS cron) | ❌ zero |
| code / plan / review / UI reasoning | F.R.I.D.A.Y (local) | ✅ only when needed |

## Election

- Hub exposes `GET /api/qam/elect`
- Master = online node with highest `priority`
- VPS (J.E.R.V.I.S) is always online → permanent fallback master
- F.R.I.D.A.Y sends heartbeat every 2 min → becomes master when online (priority 80 < 100, so VPS wins by default — change priority to 90+ to promote local)

## API Endpoints (via Bridge)

All endpoints require `X-Bridge-Token` header.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/qam/status` | Full health: nodes, master, queue stats |
| GET | `/api/qam/elect` | Force election, get current master |
| GET | `/api/qam/nodes` | List all nodes |
| POST | `/api/qam/nodes/heartbeat` | Node announces online |
| POST | `/api/qam/nodes/:id/offline` | Node graceful offline → re-election |
| GET | `/api/qam/queue` | List tasks (filter: ?node=&status=) |
| POST | `/api/qam/queue` | Push task (auto-assigns by capability) |
| POST | `/api/qam/queue/:id/claim` | Worker claims task (prevents double-run) |
| POST | `/api/qam/queue/:id/result` | Worker posts result |
| DELETE | `/api/qam/queue/:id` | Remove task |
| GET | `/api/qam/credits` | View credit usage |
| POST | `/api/qam/credits/log` | Log token usage |

## Nodes

### Adding a new node (node3 / node4)

POST heartbeat with:
```json
{
  "id": "node3",
  "name": "My Node",
  "role": "worker",
  "capabilities": ["exec", "git"],
  "priority": 50,
  "url": "http://<node-ip>/api"
}
```

Then deploy `worker/qam_worker.py` on that machine and add a cron:
```
* * * * * python3 /path/to/qam_worker.py
```

## Files

```
QAM/
├── hub/
│   └── mesh_routes.py       # Flask routes appended to QUANTFLASH bridge
├── worker/
│   └── qam_worker.py        # Worker script (deploy on each node)
├── data/
│   ├── nodes.json.example
│   └── queue.json.example
└── README.md
```
