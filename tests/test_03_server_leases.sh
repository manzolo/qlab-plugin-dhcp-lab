#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 3 — Server Leases${RESET}"; echo ""

# 3.1 Lease file exists on server
assert "Server lease file exists" ssh_server "test -f /var/lib/dhcp/dhcpd.leases"

# 3.2 Lease file has content
leases=$(ssh_server "cat /var/lib/dhcp/dhcpd.leases 2>/dev/null")
assert_contains "Lease file has entries" "$leases" "lease|starts|ends"

# 3.3 DHCP service status
assert "DHCP service running" ssh_server "sudo systemctl is-active isc-dhcp-server"

report_results "Exercise 3"
