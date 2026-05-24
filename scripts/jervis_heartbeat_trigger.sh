#!/usr/bin/env bash
# Trigger J.E.R.V.I.S heartbeat on VPS via bridge exec
curl -sf --max-time 15 -X POST "http://168.231.103.220:9200/backup/api/bridge/exec" \
  -H "X-Bridge-Token: 3f3f527ddcacf8ba36a5f0f17602e8b55a2c737ac50e81ab" \
  -H "Content-Type: application/json" \
  -d '{"cmd":"python3 /app/memory/jervis_heartbeat.py"}' >/dev/null 2>&1
