# dhcp-lab — DHCP Server & Client Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Walkthrough](https://img.shields.io/badge/walkthrough-EN%20%26%20IT-informational)](docs/walkthrough-en.pdf)

A two-VM [QLab](https://github.com/manzolo/qlab) lab on a private LAN — an `isc-dhcp-server`
and a client that leases from it — for watching the DORA handshake happen and shaping it:
lease times, options, static reservations and multiple pools.

## Quick start

```bash
qlab install dhcp-lab
qlab run dhcp-lab             # boots 2 VMs (~90s)
qlab shell dhcp-lab-server    # isc-dhcp-server — labuser / labpass
qlab shell dhcp-lab-client    # leases its IP  — labuser / labpass
qlab test dhcp-lab            # run the automated checks
qlab stop dhcp-lab
```

## What's inside

| # | Exercise | What you do |
|---|----------|-------------|
| 1 | Verify the setup | server running, client leased, connectivity |
| 2 | Observe DORA | capture the 4-step handshake live with tcpdump |
| 3 | Modify options | lease times, DNS servers, domain name |
| 4 | Static reservation | pin a fixed IP to the client's MAC |
| 5 | Multiple pools | separate pools with allow/deny rules |

## Network

Private LAN `192.168.100.0/24`, isolated between the two VMs.

| VM | Address | Role |
|----|---------|------|
| `dhcp-lab-server` | `192.168.100.1` | `isc-dhcp-server` |
| `dhcp-lab-client` | via DHCP (`.100`–`.200`) | leases from the server |

SSH: `labuser` / `labpass`, dynamically forwarded — see `qlab ports`.

## Learn more

- 📖 **[Step-by-step guide](guide.md)** — every exercise with full commands and captures
- 📄 **Illustrated walkthrough** — a real run, captured live: **[English](docs/walkthrough-en.pdf)** · **[Italiano](docs/walkthrough-it.pdf)**
- 🧩 **[QLab](https://github.com/manzolo/qlab)** — the plugin runner: how install, overlays and cloud-init work
