#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 1 — DHCP Anatomy${RESET}"; echo ""

# 1.1 DHCP server service is running
status=$(ssh_server "systemctl is-active isc-dhcp-server 2>/dev/null" || echo "unknown")
assert_contains "isc-dhcp-server is active" "$status" "active"

# 1.2 Server has static IP
server_ip=$(ssh_server "ip addr show 2>/dev/null")
assert_contains "Server has 192.168.100.1" "$server_ip" "192.168.100.1"

# 1.3 DHCP config exists
assert "dhcpd.conf exists" ssh_server "test -f /etc/dhcp/dhcpd.conf"

# 1.4 Config has correct subnet
config=$(ssh_server "cat /etc/dhcp/dhcpd.conf 2>/dev/null")
assert_contains "Subnet 192.168.100.0 configured" "$config" "192.168.100.0"
assert_contains "Range configured" "$config" "range"

# 1.5 DHCP port listening
ports=$(ssh_server "ss -ulnp 2>/dev/null")
assert_contains "Port 67 listening" "$ports" ":67"

report_results "Exercise 1"
