#!/usr/bin/env bash
# F.R.I.D.A.Y heartbeat — macOS system metrics every 2min
HUB="http://168.231.103.220:9200/backup/api"
TOKEN="3f3f527ddcacf8ba36a5f0f17602e8b55a2c737ac50e81ab"
NODE="friday-local"

# CPU: sum all process %cpu / core count
CPU=$(ps -A -o %cpu 2>/dev/null | awk '{s+=$1} END {
  cores=1; cmd="sysctl -n hw.logicalcpu"; cmd | getline cores; close(cmd);
  v = s/cores; if (v>100) v=100; printf "%.1f", v
}')
CPU=${CPU:-0}

# RAM: vm_stat for accurate Mac memory
PAGE_SIZE=$(vm_stat 2>/dev/null | awk '/page size/ {print $8}'); PAGE_SIZE=${PAGE_SIZE:-4096}
WIRED=$(vm_stat 2>/dev/null | awk '/Pages wired/ {gsub(/\./,""); print $4}'); WIRED=${WIRED:-0}
ACTIVE=$(vm_stat 2>/dev/null | awk '/Pages active/ {gsub(/\./,""); print $3}'); ACTIVE=${ACTIVE:-0}
COMPRESSED=$(vm_stat 2>/dev/null | awk '/Pages occupied by compressor/ {gsub(/\./,""); print $5}'); COMPRESSED=${COMPRESSED:-0}
TOTAL_RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 8589934592)
TOTAL_PAGES=$((TOTAL_RAM_BYTES / PAGE_SIZE))
USED_PAGES=$((WIRED + ACTIVE + COMPRESSED))
RAM_USED_GB=$(echo "scale=2; $USED_PAGES * $PAGE_SIZE / 1073741824" | bc)
RAM_TOTAL_GB=$(echo "scale=2; $TOTAL_RAM_BYTES / 1073741824" | bc)
RAM_PCT=$(echo "scale=1; $USED_PAGES * 100 / $TOTAL_PAGES" | bc 2>/dev/null || echo "0")

# Disk: root partition (GB)
DISK_INFO=$(df -k / 2>/dev/null | awk 'NR==2 {print $2, $3}')
DISK_TOTAL_KB=$(echo $DISK_INFO | awk '{print $1}')
DISK_USED_KB=$(echo $DISK_INFO | awk '{print $2}')
DISK_TOTAL_GB=$(echo "scale=1; ${DISK_TOTAL_KB:-0} / 1048576" | bc)
DISK_USED_GB=$(echo "scale=1; ${DISK_USED_KB:-0} / 1048576" | bc)
DISK_PCT=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}'); DISK_PCT=${DISK_PCT:-0}

PAYLOAD="{\"node_id\":\"${NODE}\",\"label\":\"F.R.I.D.A.Y (Mac)\",\"priority\":80,\"capabilities\":[\"code\",\"plan\",\"review\"],\"cpu\":${CPU},\"ram_pct\":${RAM_PCT},\"ram_used_gb\":${RAM_USED_GB},\"ram_total_gb\":${RAM_TOTAL_GB},\"disk_pct\":${DISK_PCT},\"disk_used_gb\":${DISK_USED_GB},\"disk_total_gb\":${DISK_TOTAL_GB}}"

curl -sf -X POST "${HUB}/qam/nodes/heartbeat" \
  -H "Content-Type: application/json" -H "X-Bridge-Token: ${TOKEN}" \
  -d "$PAYLOAD" >/dev/null 2>&1

curl -sf -X POST "${HUB}/qam/metrics" \
  -H "Content-Type: application/json" -H "X-Bridge-Token: ${TOKEN}" \
  -d "$PAYLOAD" >/dev/null 2>&1
