# dhcp-lab — DHCP Configuration Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots two virtual machines for practicing DHCP server configuration and understanding dynamic IP addressing.

## Architecture

```
    Internal LAN (192.168.100.0/24)
┌─────────────────────────────────────┐
│                                     │
│  ┌─────────────────┐  ┌─────────────────┐
│  │ dhcp-lab-server  │  │ dhcp-lab-client │
│  │ SSH: 2238        │  │ SSH: 2239       │
│  │ 192.168.100.1    │──►  IP via DHCP    │
│  │ isc-dhcp-server  │  │  (.100-.200)    │
│  └─────────────────┘  └─────────────────┘
│                                     │
└─────────────────────────────────────┘
```

## Objectives

- Understand the DHCP DORA process (Discover, Offer, Request, Ack)
- Configure isc-dhcp-server with subnets and address pools
- Set DHCP options (gateway, DNS, lease time, domain name)
- Configure static/reserved IP assignments by MAC address
- Monitor DHCP traffic with tcpdump
- Practice releasing and renewing leases

## How It Works

1. **Cloud image**: Downloads a minimal Ubuntu 22.04 cloud image (~250MB)
2. **Cloud-init**: Creates `user-data` for both VMs with DHCP packages
3. **ISO generation**: Packs cloud-init files into ISOs (cidata)
4. **Overlay disks**: Creates COW disks for each VM (original stays untouched)
5. **QEMU boot**: Starts both VMs with SSH access and a shared internal LAN

## Credentials

Both VMs use the same credentials:
- **Username:** `labuser`
- **Password:** `labpass`

## Network

| VM              | SSH (host) | Internal LAN IP     |
|-----------------|------------|---------------------|
| dhcp-lab-server | port 2238  | 192.168.100.1 (static) |
| dhcp-lab-client | port 2239  | assigned via DHCP   |

The VMs are connected by a direct internal LAN (`192.168.100.0/24`) via QEMU socket networking. The server assigns addresses from the pool `192.168.100.100` - `192.168.100.200`.

## Usage

```bash
# Install the plugin
qlab install dhcp-lab

# Run the lab (starts both VMs)
qlab run dhcp-lab

# Wait ~90s for boot and package installation, then:

# Connect to the server VM
qlab shell dhcp-lab-server

# Connect to the client VM
qlab shell dhcp-lab-client

# Stop both VMs
qlab stop dhcp-lab

# Stop a single VM
qlab stop dhcp-lab-server
qlab stop dhcp-lab-client
```

## Exercises

> **New to DHCP?** See the [Step-by-Step Guide](GUIDE.md) for complete walkthroughs with full config examples.

| # | Exercise | What you'll do |
|---|----------|----------------|
| 1 | **Verify DHCP setup** | Check the server is running, verify the client got an IP, test connectivity |
| 2 | **Observe DORA** | Use tcpdump to capture the 4-step DHCP handshake in real time |
| 3 | **Modify DHCP options** | Change lease times, DNS servers, and domain name |
| 4 | **Static reservation** | Reserve a fixed IP for the client's MAC address |
| 5 | **Multiple pools** | Create separate pools with allow/deny rules |

## Managing VMs

```bash
# View boot logs
qlab log dhcp-lab-server
qlab log dhcp-lab-client

# Check running VMs
qlab status
```

## Resetting

To start fresh, stop and re-run:

```bash
qlab stop dhcp-lab
qlab run dhcp-lab
```

Or reset the entire workspace:

```bash
qlab reset
```
