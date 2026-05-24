#!/usr/bin/env bash
# F.R.I.D.A.Y heartbeat — macOS metrics every 2min
HUB="http://168.231.103.220:9200/backup/api"
TOKEN="3f3f527ddcacf8ba36a5f0f17602e8b55a2c737ac50e81ab"
NODE="friday-local"

CPU_IDLE=$(top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ {gsub(/%/,""); for(i=1;i<=NF;i++) if($i=="idle,") print $(i-1)}')
CPU=$(echo "100 - ${CPU_IDLE:-0}" | bc 2>/dev/null || echo "0")

PAGE_SIZE=$(vm_stat 2>/dev/null | awk '/page size/ {print $8}')
PAGE_SIZE=${PAGE_SIZE:-4096}
WIRED=$(vm_stat 2>/dev/null | awk '/Pages wired/ {gsub(/\./,""); print $4}')
ACTIVE=$(vm_stat 2>/dev/null | awk '/Pages active/ {gsub(/\./,""); print $3}')
WIRED=${WIRED:-0}; ACTIVE=${ACTIVE:-0}
TOTAL_RAM=$(sysctl -n hw.memsize 2>/dev/null || echo 8589934592)
TOTAL_PAGES=$((TOTAL_RAM / PAGE_SIZE))
USED_PAGES=$((WIRED + ACTIVE))
RAM_PCT=$(echo "scale=1; $USED_PAGES * 100 / $TOTAL_PAGES" | bc 2>/dev/null || echo "0")

DISK_PCT=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
DISK_PCT=${DISK_PCT:-0}

curl -sf -X POST "${HUB}/qam/nodes/heartbeat" \
  -H "Content-Type: application/json" \
  -H "X-Bridge-Token: ${TOKEN}" \
  -d "{\"node_id\":\"${NODE}\",\"label\":\"F.R.I.D.A.Y (Mac)\",\"priority\":80,\"capabilities\":[\"code\",\"plan\",\"review\"],\"cpu\":${CPU},\"ram_pct\":${RAM_PCT},\"disk_pct\":${DISK_PCT}}" \
  >/dev/null 2>&1

curl -sf -X POST "${HUB}/qam/metrics" \
  -H "Content-Type: application/json" \
  -H "X-Bridge-Token: ${TOKEN}" \
  -d "{\"node_id\":\"${NODE}\",\"cpu\":${CPU},\"ram_pct\":${RAM_PCT},\"disk_pct\":${DISK_PCT}}" \
  >/dev/null 2>&1
