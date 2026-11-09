#!/bin/bash
# VanPi health check: every 20 s check that a program can start and the root filesystem is not
# read-only (via /proc/mounts – no writes to the SD card). After 4 consecutive failures (~80 s)
# reboot directly via the kernel (bash built-ins only, works even when the SD card no longer
# delivers binaries). No action in the first 10 minutes after boot (avoids a reboot loop with a
# truly dead card).
fehler=0
while true; do
  read -r up _ < /proc/uptime; up=${up%.*}
  ro=0
  while read -r _ mnt _ opts _; do
    [ "$mnt" = "/" ] && [[ ",$opts," == *",ro,"* ]] && ro=1
  done < /proc/mounts
  if /bin/true 2>/dev/null && [ "$ro" -eq 0 ]; then
    fehler=0
  else
    fehler=$((fehler+1))
    echo "vanpi-health: check failed ($fehler/4)" > /dev/kmsg 2>/dev/null
  fi
  if [ "$fehler" -ge 4 ] && [ "$up" -ge 600 ]; then
    echo "vanpi-health: system hung - rebooting" > /dev/kmsg 2>/dev/null
    echo s > /proc/sysrq-trigger; read -t 3 <> <(:)
    echo b > /proc/sysrq-trigger
  fi
  /bin/sleep 20 2>/dev/null || read -t 20 <> <(:)
done
