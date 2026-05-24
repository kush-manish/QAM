#!/usr/bin/env bash
# F.R.I.D.A.Y heartbeat — macOS system metrics every 2min
HUB="http://168.231.103.220:9200/backup/api"
TOKEN="3f3f527ddcacf8ba36a5f0f17602e8b55a2c737ac50e81ab"
NODE="friday-local"

# CPU: sum all process %cpu, cap at 100 (reflects actual Mac usage not container)
CPU=$(ps -A -o %cpu 2>/dev/null | awk '{s+=$1} END {
  cores=1; cmd="sysctl -n hw.logicalcpu"; cmd | getline cores; close(cmd);
  v = s/cores;
  if (v>100) v=100;
  printf "%.1f", v
}')
CPU=${CPU:-0}

# RAM: use vm_stat for accurate Mac memory pressure
PAGE_SIZE=$(vm_stat 2>/dev/null | awk '/page size/ {print $8}')
PAGE_SIZE=${PAGE_SIZE:-4096}
WIRED=$(vm_stat 2>/dev/null | awk '/Pages wired/ {gsub(/\./,""); print $4}')
ACTIVE=$(vm_stat 2>/dev/null | awk '/Pages active/ {gsub(/\./,""); print $3}')
COMPRESSED=$(vm_stat 2>/dev/null | awk '/Pages occupied by compressor/ {gsub(/\./,""); print $5}')
WIRED=${WIRED:-0}; ACTIVE=${ACTIVE:-0}; COMPRESSED=${COMPRESSED:-0}
TOTAL_RAM=$(sysctl -n hw.memsize 2>/dev/null || echo 8589934592)
TOTAL_PAGES=$((TOTAL_RAM / PAGE_SIZE))
USED_PAGES=$((WIRED + ACTIVE + COMPRESSED))
RAM_PCT=$(echo "scale=1; $USED_PAGES * 100 / $TOTAL_PAGES" | bc 2>/dev/null || echo "0")

# Disk: root partition
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
DISK_PCT=${DISK_PCT:-0}

# Heartbeat
curl -sf -X POST "${HUB}/qam/nodes/heartbeat" \
  -H "Content-Type: application/json" \
  -H "X-Bridge-Token: ${TOKEN}" \
  -d "{\"node_id\":\"${NODE}\",\"label\":\"F.R.I.D.A.Y (Mac)\",\"priority\":80,\"capabilities\":[\"code\",\"plan\",\"review\"],\"cpu\":${CPU},\"ram_pct\":${RAM_PCT},\"disk_pct\":${DISK_PCT}}" \
  >/dev/null 2>&1

# Metrics
curl -sf -X POST "${HUB}/qam/metrics" \
  -H "Content-Type: application/json" \
  -H "X-Bridge-Token: ${TOKEN}" \
  -d "{\"node_id\":\"${NODE}\",\"cpu\":${CPU},\"ram_pct\":${RAM_PCT},\"disk_pct\":${DISK_PCT}}" \
  >/dev/null 2>&1
