#!/usr/bin/env bash
# Prints "<rx bytes> <tx bytes> <ipv4 address> <gateway>" for one interface,
# with "-" for an address it doesn't have.
#
# Usage: net-stats.sh <interface>

iface=${1:-}
stats=/sys/class/net/$iface/statistics
[[ -n $iface && -d $stats ]] || exit 1

rx=$(<"$stats/rx_bytes")
tx=$(<"$stats/tx_bytes")
address=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{ split($4, a, "/"); print a[1]; exit }')
gateway=$(ip route show default dev "$iface" 2>/dev/null | awk '{ print $3; exit }')

printf '%s %s %s %s\n' "$rx" "$tx" "${address:--}" "${gateway:--}"
