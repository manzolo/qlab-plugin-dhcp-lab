#!/usr/bin/env bash
# dhcp-lab install script

set -euo pipefail

echo ""
echo "  [dhcp-lab] Installing..."
echo ""
echo "  This plugin creates two VMs for practicing DHCP configuration:"
echo ""
echo "    1. dhcp-lab-server  — DHCP Server VM"
echo "       Runs isc-dhcp-server to assign IP addresses"
echo "       Practice DHCP pool configuration and options"
echo ""
echo "    2. dhcp-lab-client  — DHCP Client VM"
echo "       Requests an IP address from the server"
echo "       Observe the DHCP handshake (DORA) in real time"
echo ""
echo "  What you will learn:"
echo "    - How the DHCP DORA process works (Discover, Offer, Request, Ack)"
echo "    - How to configure isc-dhcp-server with subnets and pools"
echo "    - How to set DHCP options (gateway, DNS, lease time)"
echo "    - How to configure static/reserved IP assignments"
echo "    - How to monitor DHCP traffic with tcpdump"
echo ""

# Create lab working directory
mkdir -p lab

# Check for required tools
echo "  Checking dependencies..."
local_ok=true
for cmd in qemu-system-x86_64 qemu-img genisoimage curl; do
    if command -v "$cmd" &>/dev/null; then
        echo "    [OK] $cmd"
    else
        echo "    [!!] $cmd — not found (install before running)"
        local_ok=false
    fi
done

if [[ "$local_ok" == true ]]; then
    echo ""
    echo "  All dependencies are available."
else
    echo ""
    echo "  Some dependencies are missing. Install them with:"
    echo "    sudo apt install qemu-kvm qemu-utils genisoimage curl"
fi

echo ""
echo "  [dhcp-lab] Installation complete."
echo "  Run with: qlab run dhcp-lab"
