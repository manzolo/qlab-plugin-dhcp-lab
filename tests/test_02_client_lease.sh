#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 2 — Client Lease${RESET}"; echo ""

# 2.1 Client has an IP in the DHCP range
client_ip=$(ssh_client "ip addr show 2>/dev/null")
assert_contains "Client has IP in 192.168.100.x range" "$client_ip" "192.168.100\."

# 2.2 Client can ping server
ping_result=$(ssh_client "ping -c 1 -W 3 192.168.100.1 2>/dev/null" || echo "")
assert_contains "Client can ping server" "$ping_result" "1 received|1 packets received"

# 2.3 Lease file exists on client (systemd-networkd or dhclient)
lease_exists=$(ssh_client "ls /run/systemd/netif/leases/ /var/lib/dhcp/dhclient*.leases 2>/dev/null" || echo "")
assert_contains "Client lease file exists" "$lease_exists" "leases|dhclient"

report_results "Exercise 2"
