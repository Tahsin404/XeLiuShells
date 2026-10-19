#!/usr/bin/env bash
# ~/.config/quickshell/scripts/hardware.sh

get_gpu_usage() {
  local raw=""

  # 1. NVIDIA GPUs (via nvidia-smi)
  if command -v nvidia-smi >/dev/null 2>&1; then
    raw=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1 | tr -d ' ')
    if [[ "$raw" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      awk -v r="$raw" 'BEGIN { val = r / 100.0; if (val > 1.0) val = 1.0; printf "%.2f", val }'
      return
    fi
  fi

  # 2. AMD & Newer Intel GPUs (Scan all DRM cards for gpu_busy_percent, pick highest load)
  local best_busy=-1
  for busy_file in /sys/class/drm/card[0-9]*/device/gpu_busy_percent /sys/class/drm/card[0-9]*/gt/gt0/gpu_busy_percent; do
    if [ -r "$busy_file" ]; then
      local val
      val=$(cat "$busy_file" 2>/dev/null | tr -d ' ')
      if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -gt "$best_busy" ]; then
        best_busy=$val
      fi
    fi
  done

  if [ "$best_busy" -ge 0 ]; then
    awk -v r="$best_busy" 'BEGIN { val = r / 100.0; if (val > 1.0) val = 1.0; printf "%.2f", val }'
    return
  fi

  # 3. Intel GPUs (i915 / xe frequency-ratio fallback via sysfs — zero root permissions needed)
  for card_dir in /sys/class/drm/card[0-9]*; do
    local act_file=""
    local max_file=""

    if [ -r "$card_dir/gt_act_freq_mhz" ] && [ -r "$card_dir/gt_max_freq_mhz" ]; then
      act_file="$card_dir/gt_act_freq_mhz"
      max_file="$card_dir/gt_max_freq_mhz"
    elif [ -r "$card_dir/gt/gt0/rps_act_freq_mhz" ] && [ -r "$card_dir/gt/gt0/rps_max_freq_mhz" ]; then
      act_file="$card_dir/gt/gt0/rps_act_freq_mhz"
      max_file="$card_dir/gt/gt0/rps_max_freq_mhz"
    elif [ -r "$card_dir/device/tile0/gt0/freq0/act_freq" ] && [ -r "$card_dir/device/tile0/gt0/freq0/max_freq" ]; then
      act_file="$card_dir/device/tile0/gt0/freq0/act_freq"
      max_file="$card_dir/device/tile0/gt0/freq0/max_freq"
    fi

    if [ -n "$act_file" ] && [ -n "$max_file" ]; then
      local act max
      act=$(cat "$act_file" 2>/dev/null | tr -d ' ')
      max=$(cat "$max_file" 2>/dev/null | tr -d ' ')
      if [[ "$act" =~ ^[0-9]+$ ]] && [[ "$max" =~ ^[0-9]+$ ]] && [ "$max" -gt 0 ]; then
        awk -v a="$act" -v m="$max" 'BEGIN { val = a / m; if (val > 1.0) val = 1.0; printf "%.2f", val }'
        return
      fi
    fi
  done

  # 4. Fallback if no supported GPU sensor is found
  printf "0.00"
}

while true; do
  # 1. CPU Usage
  cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
  cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN { printf "%.2f", (100 - idle) / 100 }')

  # 2. RAM Usage
  ram_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2}')

  # 3. Dynamic Multi-Vendor GPU Usage (NVIDIA / AMD / Intel)
  gpu_usage=$(get_gpu_usage)

  echo "$cpu_usage $ram_usage $gpu_usage"

  # Pauses before calculating the next batch
  sleep 2.5
done
