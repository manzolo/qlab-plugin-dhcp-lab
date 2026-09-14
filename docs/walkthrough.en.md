---
kicker: QLab · dhcp-lab
title: |
  DHCP, watched
  from both ends
subtitle: >
  Two VMs on a private LAN: one hands out addresses, the other asks for one.
  Every block below was captured while the lab was running — including a real
  DORA exchange, recorded on the server and on the client at the same instant.
facts:
  - [Command, "`qlab run dhcp-lab`"]
  - [VMs, "`dhcp-lab-server` 192.168.100.1 · `dhcp-lab-client` by DHCP"]
  - [Credentials, "`labuser` / `labpass`"]
  - [Outcome, "`qlab test dhcp-lab` → all exercises passed"]
---

## 1. What is in the lab

| VM | Role |
|---|---|
| `dhcp-lab-server`<br>192.168.100.1 | Ubuntu 22.04 running **isc-dhcp-server**, bound to the lab LAN only. |
| `dhcp-lab-client`<br>address from the pool | The same image with no server, asking for an address the ordinary way. |

Each VM has two network cards: the lab LAN, and the SLIRP one QLab attaches to
every VM so `qlab shell` works. That second card matters more than it looks — it
is why the server must be told *which* interface to serve, and it is the first
thing to check when a DHCP server appears to do nothing.

{{evidence:server-iface}}

`INTERFACESv4="ens4"` is not decoration. Without it isc-dhcp-server either
refuses to start or, worse, starts serving the wrong network.

## 2. The server is up

{{evidence:server-status as=shell}}

Its configuration is short enough to read in full:

{{evidence:dhcpd-conf}}

Four things are being declared here: the **pool** (`range`), how long an address
is lent for (`default-lease-time` / `max-lease-time`), what else to tell the
client besides its address (`option routers`, `option domain-name-servers`), and
`authoritative` — which says "on this network, I am the DHCP server", so the
server answers a client asking for a wrong address with a DHCPNAK instead of
staying silent.

## 3. DORA, recorded from both sides

The four packets everyone learns about, made to happen on purpose: `tcpdump`
runs on the server while the client is told to drop its lease and ask again.

{{evidence:dora}}

Read the two halves together, because they disagree in an instructive way.

The client names each step: **DISCOVER**, **OFFER**, **REQUEST**, **ACK**. The
capture on the server shows only `BOOTP/DHCP, Request` and `BOOTP/DHCP, Reply` —
twice each. That is not tcpdump being unhelpful: DHCP is an extension of BOOTP,
and at that level there are only requests and replies. Which of the four it is
lives in DHCP **option 53**, inside the payload. The `-v` flag on tcpdump would
print it.

Two more details worth noticing:

- The first two packets go to `255.255.255.255` from `0.0.0.0`. The client has no
  address yet, so it cannot send a normal unicast and cannot be answered by one.
  Everything before the ACK is a broadcast conversation.
- The `xid` ties the four packets into one transaction, which is how a client
  tells its own exchange apart from every other machine shouting on the same
  broadcast domain. Look closely and the REQUEST appears to carry a different
  one: it is the same number with its bytes reversed. That is a display quirk of
  `dhclient`, not a second transaction — compare the DISCOVER and the ACK, which
  agree.

## 4. The lease exists on both machines

The client now holds what it was given:

{{evidence:client-addr}}

And the server wrote it down. A lease is a record with an expiry, not an
assignment:

{{evidence:leases}}

:::note Two leases, one client
The lease file holds more than one entry for this MAC, and only the last is
`binding state active`. Every `dhclient -r` hands an address back and the next
DISCOVER may be answered with the same one or with the next free one — the
server decides, and both are correct. An address is a loan with a deadline, not
property, and the expired entries stay in the file as history.
:::

Note `client-hostname "dhcp-lab-client"` in the record: the client sent its name
in **option 12**, which is how a DHCP server can register names in DNS without
anyone configuring anything by hand.

The client keeps its own copy, with the options it was handed:

{{evidence:client-lease}}

## 5. Verification

{{evidence:qlab-test grep="Exercise|All exercises|Exercises " as=shell}}

## 6. What to take away

- A DHCP server serves an **interface**, not a machine. On a host with two cards
  the single most common failure is serving the wrong one — or being refused
  because you did not say which.
- `tcpdump` shows BOOTP requests and replies; the four DORA names live in option
  53 inside the packet. The client's own log is the easier place to read them.
- The whole exchange before the ACK is broadcast traffic, because the client has
  no address to be reached at.
- A lease is a loan with an expiry. Releasing one does not get it back, and the
  server is free to hand out a different address next time.
- `authoritative` changes what happens when a client asks for something wrong:
  a clear refusal instead of silence.

`guide.md` in the plugin takes this further — lease times, custom options, static
reservations by MAC, and two pools on one subnet.
