#!/bin/bash

while true; do
  # 1. CPU Usage
  cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
  cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN { printf "%.2f", (100 - idle) / 100 }')

  # 2. RAM Usage
  ram_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2}')

  # 3. GPU Usage
  if [ -f /sys/class/drm/card0/device/gpu_busy_percent ]; then
    gpu_raw=$(cat /sys/class/drm/card0/device/gpu_busy_percent)
    gpu_usage=$(awk -v raw="$gpu_raw" 'BEGIN { printf "%.2f", raw / 100 }')
  else
    gpu_usage=0.00
  fi

  echo "$cpu_usage $ram_usage $gpu_usage"

  # Pauses before calculating the next batch
  sleep 2.5
done
