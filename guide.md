# DHCP Lab — Step-by-Step Guide

This guide walks you through understanding and configuring DHCP from scratch using the two lab VMs.

## Prerequisites

Start the lab and wait for both VMs to finish booting (~90 seconds):

```bash
qlab run dhcp-lab
```

Open **two terminals** and connect to each VM:

```bash
# Terminal 1 — Server
qlab shell dhcp-lab-server

# Terminal 2 — Client
qlab shell dhcp-lab-client
```

On each VM, make sure cloud-init has finished:

```bash
cloud-init status --wait
```

## Network Topology

Each VM has **two network interfaces**:

- **eth0** (SLIRP): for SSH access from the host (`qlab shell`)
- **Internal LAN**: a direct virtual link between the VMs (`192.168.100.0/24`)

```
        Host Machine
       ┌────────────┐
       │  SSH :auto  │──────► dhcp-lab-server
       │  SSH :auto  │──────► dhcp-lab-client
       └────────────┘

   Internal LAN (192.168.100.0/24)
  ┌──────────────────────────────────┐
  │                                  │
  │  ┌─────────────┐   ┌─────────────┐
  │  │ dhcp-server │   │ dhcp-client │
  │  │ 192.168.    │   │ IP assigned │
  │  │   100.1     │──►│ via DHCP    │
  │  │ (static)    │   │ (.100-.200) │
  │  └─────────────┘   └─────────────┘
  └──────────────────────────────────┘
```

The server has a static IP (`192.168.100.1`) and runs `isc-dhcp-server`. The client uses netplan with `dhcp4: true` to request an address automatically.

---

## Exercise 1: Verify the DHCP Setup

### 1.1 Check the server is running

On **dhcp-lab-server**:

```bash
# Check isc-dhcp-server status
sudo systemctl status isc-dhcp-server

# View the configuration
cat /etc/dhcp/dhcpd.conf
```

You should see the service active and the subnet `192.168.100.0/24` configured with a pool from `.100` to `.200`.

### 1.2 Check the client received an IP

On **dhcp-lab-client**:

```bash
# Show all network interfaces
ip addr show

# Look for the internal LAN interface — it should have a 192.168.100.x address
ip addr show | grep "192.168.100"
```

If the client hasn't received an IP yet, trigger a DHCP request manually:

```bash
# Find the internal interface name
IFACE=$(ip -o link | grep "52:54:00:00:03:02" | awk -F': ' '{print $2}')
echo "Internal interface: $IFACE"

# Request a DHCP lease
sudo dhclient -v "$IFACE"
```

### 1.3 Test connectivity

From the **client**, ping the server:

```bash
ping 192.168.100.1
```

From the **server**, check active leases:

```bash
cat /var/lib/dhcp/dhcpd.leases
```

---

## Exercise 2: Observe the DHCP DORA Process

The DHCP handshake consists of four messages: **D**iscover, **O**ffer, **R**equest, **A**ck (DORA).

### 2.1 Start a packet capture on the server

On **dhcp-lab-server**:

```bash
sudo tcpdump -i any -n -v port 67 or port 68
```

### 2.2 Release and renew the client's lease

On **dhcp-lab-client**, find the interface name and release/request:

```bash
# Find the internal interface
IFACE=$(ip -o link | grep "52:54:00:00:03:02" | awk -F': ' '{print $2}')

# Release the current lease
sudo dhclient -r "$IFACE"

# Wait a moment, then request a new lease
sudo dhclient -v "$IFACE"
```

### 2.3 Analyze the capture

In the tcpdump output on the server, you should see four packets:

1. **DHCP Discover** — client broadcasts `255.255.255.255` looking for a server
2. **DHCP Offer** — server offers an IP address (e.g. `192.168.100.100`)
3. **DHCP Request** — client requests the offered address
4. **DHCP Ack** — server confirms the assignment

```
DHCP-Discover → 0.0.0.0.68 > 255.255.255.255.67
DHCP-Offer    → 192.168.100.1.67 > 192.168.100.100.68
DHCP-Request  → 0.0.0.0.68 > 255.255.255.255.67
DHCP-Ack      → 192.168.100.1.67 > 192.168.100.100.68
```

---

## Exercise 3: Modify DHCP Options

### 3.1 Change the lease time

On **dhcp-lab-server**, edit the configuration:

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Change the lease times:

```
default-lease-time 120;   # 2 minutes (was 600)
max-lease-time 300;       # 5 minutes (was 7200)
```

Restart the service:

```bash
sudo systemctl restart isc-dhcp-server
```

On the **client**, release and renew to get the new lease time:

```bash
IFACE=$(ip -o link | grep "52:54:00:00:03:02" | awk -F': ' '{print $2}')
sudo dhclient -r "$IFACE"
sudo dhclient -v "$IFACE"
```

Check the lease details:

```bash
cat /var/lib/dhcp/dhclient.leases
```

You should see the shorter lease time reflected.

### 3.2 Add custom DNS servers

On **dhcp-lab-server**, edit `/etc/dhcp/dhcpd.conf` and change:

```
option domain-name-servers 1.1.1.1, 1.0.0.1;
```

Restart and renew:

```bash
sudo systemctl restart isc-dhcp-server
```

On the **client**, verify:

```bash
IFACE=$(ip -o link | grep "52:54:00:00:03:02" | awk -F': ' '{print $2}')
sudo dhclient -r "$IFACE"
sudo dhclient -v "$IFACE"
cat /etc/resolv.conf
```

---

## Exercise 4: Static DHCP Reservation

Reserve a specific IP for the client's MAC address.

### 4.1 Configure the reservation

On **dhcp-lab-server**, edit `/etc/dhcp/dhcpd.conf` and add (or uncomment) the host block:

```
host client-reserved {
  hardware ethernet 52:54:00:00:03:02;
  fixed-address 192.168.100.50;
}
```

Restart:

```bash
sudo systemctl restart isc-dhcp-server
```

### 4.2 Verify

On the **client**, release and renew:

```bash
IFACE=$(ip -o link | grep "52:54:00:00:03:02" | awk -F': ' '{print $2}')
sudo dhclient -r "$IFACE"
sudo dhclient -v "$IFACE"
ip addr show "$IFACE"
```

The client should now always receive `192.168.100.50`.

### 4.3 Check on the server

```bash
cat /var/lib/dhcp/dhcpd.leases | grep -A 5 "192.168.100.50"
```

---

## Exercise 5: Multiple Pools and Deny/Allow

### 5.1 Create two pools

On **dhcp-lab-server**, replace the subnet block in `/etc/dhcp/dhcpd.conf`:

```
subnet 192.168.100.0 netmask 255.255.255.0 {
  pool {
    range 192.168.100.100 192.168.100.150;
    # Default pool for unknown clients
  }
  pool {
    range 192.168.100.200 192.168.100.210;
    allow known-clients;
    # Reserved pool: only clients with a "host" declaration get these IPs
  }
  option routers 192.168.100.1;
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.100.255;
}
```

Restart and test:

```bash
sudo systemctl restart isc-dhcp-server
```

---

## Troubleshooting

### isc-dhcp-server won't start

Check the logs:

```bash
sudo journalctl -u isc-dhcp-server -n 50 --no-pager
```

Common causes:
- Wrong interface name in `/etc/default/isc-dhcp-server`
- Syntax errors in `/etc/dhcp/dhcpd.conf`
- The listening interface doesn't have an IP in the declared subnet

Verify the interface:

```bash
# Show the configured interface
cat /etc/default/isc-dhcp-server

# List all interfaces
ip addr show
```

### Client doesn't get an IP

1. Verify the server is running: `sudo systemctl status isc-dhcp-server`
2. Check the internal LAN works: can the server see the interface? (`ip addr show`)
3. Run dhclient in verbose mode: `sudo dhclient -v <iface>`
4. Check tcpdump on both sides for DHCP packets

### Lease file is empty

The server hasn't assigned any addresses yet. Trigger a request from the client:

```bash
IFACE=$(ip -o link | grep "52:54:00:00:03:02" | awk -F': ' '{print $2}')
sudo dhclient -v "$IFACE"
```

### General: packages not installed

If commands like `dhcpd` or `dhclient` are not found, cloud-init may still be running:

```bash
cloud-init status --wait
```
