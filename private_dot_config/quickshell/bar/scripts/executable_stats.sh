#!/usr/bin/env bash
# Prints one line for the system popup:
#   cpu_total cpu_idle mem_total mem_available disk_used disk_total cpu_temp load1 uptime
# CPU in jiffies since boot, memory in KiB, disk (/) in bytes, temperature in
# millidegrees (-1 when there's no sensor), uptime in seconds.

read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))

mem_total=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)
read -r disk_total disk_used < <(df -B1 --output=size,used / | tail -1)

temp=-1
for hwmon in /sys/class/hwmon/hwmon*; do
  case $(<"$hwmon/name") in
    coretemp | k10temp | zenpower | cpu_thermal) temp=$(<"$hwmon/temp1_input") && break ;;
  esac
done

read -r load1 _ </proc/loadavg
read -r uptime _ </proc/uptime

echo "$total $((idle + iowait)) $mem_total $mem_available $disk_used $disk_total $temp $load1 ${uptime%.*}"
