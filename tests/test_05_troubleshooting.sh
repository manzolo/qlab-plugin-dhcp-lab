#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 5 — Troubleshooting${RESET}"; echo ""

# 5.1 tcpdump is available
assert "tcpdump available on server" ssh_server "which tcpdump"

# 5.2 Log checking
logs=$(ssh_server "sudo journalctl -u isc-dhcp-server --no-pager -n 20 2>/dev/null" || echo "")
assert_contains "DHCP logs accessible" "$logs" "dhcpd|isc-dhcp"

# 5.3 Interface check
iface_conf=$(ssh_server "cat /etc/default/isc-dhcp-server 2>/dev/null")
assert_contains "DHCP interface configured" "$iface_conf" "INTERFACESv4"

# 5.4 Network connectivity
ping_result=$(ssh_server "ping -c 1 -W 3 192.168.100.1 2>/dev/null" || echo "")
assert_contains "Server can reach own IP" "$ping_result" "1 received|1 packets received"

report_results "Exercise 5"
