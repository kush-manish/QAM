#!/usr/bin/env bash
# J.E.R.V.I.S heartbeat — Linux metrics + status every 2min
HUB="http://localhost:9200/backup/api"
TOKEN="3f3f527ddcacf8ba36a5f0f17602e8b55a2c737ac50e81ab"
NODE="jervis-vps"

# CPU % (1s idle sample)
CPU_IDLE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $8}' | tr -d '%,')
[ -z "$CPU_IDLE" ] && CPU_IDLE=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print $15}')
CPU=$(echo "100 - ${CPU_IDLE:-0}" | bc 2>/dev/null || echo "0")

# RAM %
RAM=$(free 2>/dev/null | awk '/Mem/ {printf "%.1f", ($3/$2)*100}')
RAM=${RAM:-0}

# Disk %
DISK=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
DISK=${DISK:-0}

# POST heartbeat
curl -sf -X POST "${HUB}/qam/nodes/heartbeat" \
  -H "Content-Type: application/json" \
  -H "X-Bridge-Token: ${TOKEN}" \
  -d "{\"node_id\":\"${NODE}\",\"label\":\"J.E.R.V.I.S (VPS)\",\"priority\":100,\"capabilities\":[\"exec\",\"deploy\",\"docker\",\"git\"],\"cpu\":${CPU},\"ram\":${RAM},\"disk\":${DISK}}" \
  >/dev/null 2>&1

# POST metrics
curl -sf -X POST "${HUB}/qam/metrics" \
  -H "Content-Type: application/json" \
  -H "X-Bridge-Token: ${TOKEN}" \
  -d "{\"node\":\"${NODE}\",\"cpu\":${CPU},\"ram\":${RAM},\"disk\":${DISK}}" \
  >/dev/null 2>&1
