#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 4 — DHCP Configuration${RESET}"; echo ""

# 4.1 Check global options
config=$(ssh_server "cat /etc/dhcp/dhcpd.conf 2>/dev/null")
assert_contains "Domain name configured" "$config" "domain-name"
assert_contains "DNS servers configured" "$config" "domain-name-servers"
assert_contains "Default lease time set" "$config" "default-lease-time"
assert_contains "Max lease time set" "$config" "max-lease-time"

# 4.2 Subnet settings
assert_contains "Subnet mask configured" "$config" "netmask"
assert_contains "Router option set" "$config" "routers"

# 4.3 Authoritative
assert_contains "Server is authoritative" "$config" "authoritative"

report_results "Exercise 4"
