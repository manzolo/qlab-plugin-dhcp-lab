---
kicker: QLab · dhcp-lab
title: |
  Il DHCP, guardato
  da tutti e due i capi
subtitle: >
  Due VM su una LAN privata: una distribuisce indirizzi, l'altra ne chiede uno.
  Ogni blocco qui sotto è stato catturato a laboratorio acceso — compreso un
  DORA vero, registrato sul server e sul client nello stesso istante.
facts:
  - [Comando, "`qlab run dhcp-lab`"]
  - [VM, "`dhcp-lab-server` 192.168.100.1 · `dhcp-lab-client` via DHCP"]
  - [Credenziali, "`labuser` / `labpass`"]
  - [Esito, "`qlab test dhcp-lab` → tutti gli esercizi superati"]
---

## 1. Cosa c'è nel laboratorio

| VM | Ruolo |
|---|---|
| `dhcp-lab-server`<br>192.168.100.1 | Ubuntu 22.04 con **isc-dhcp-server**, legato alla sola LAN del lab. |
| `dhcp-lab-client`<br>indirizzo dal pool | La stessa immagine senza server, che chiede un indirizzo nel modo ordinario. |

Ogni VM ha due schede di rete: quella del laboratorio e la SLIRP che QLab
attacca a ogni macchina perché `qlab shell` funzioni. Quella seconda scheda conta
più di quanto sembri: è il motivo per cui al server va detto *quale* interfaccia
servire, ed è la prima cosa da guardare quando un server DHCP sembra non fare
niente.

{{evidence:server-iface}}

`INTERFACESv4="ens4"` non è decorativo. Senza, isc-dhcp-server o si rifiuta di
partire o, peggio, comincia a servire la rete sbagliata.

## 2. Il server è in piedi

{{evidence:server-status as=shell}}

La sua configurazione è abbastanza corta da leggersi per intero:

{{evidence:dhcpd-conf}}

Qui si dichiarano quattro cose: il **pool** (`range`), per quanto tempo un
indirizzo viene prestato (`default-lease-time` / `max-lease-time`), cosa dire al
client oltre al suo indirizzo (`option routers`, `option domain-name-servers`) e
`authoritative` — che significa «su questa rete il server DHCP sono io», quindi a
un client che chiede un indirizzo sbagliato si risponde con un DHCPNAK invece di
tacere.

## 3. DORA, registrato da entrambi i lati

I quattro pacchetti che tutti studiano, fatti accadere apposta: `tcpdump` gira
sul server mentre al client viene ordinato di rilasciare il lease e richiederlo.

{{evidence:dora}}

Le due metà vanno lette insieme, perché si contraddicono in modo istruttivo.

Il client nomina ogni passo: **DISCOVER**, **OFFER**, **REQUEST**, **ACK**. La
cattura sul server mostra solo `BOOTP/DHCP, Request` e `BOOTP/DHCP, Reply` — due
volte ciascuno. Non è tcpdump che fa il misterioso: il DHCP è un'estensione del
BOOTP, e a quel livello esistono solo richieste e risposte. Quale dei quattro sia
sta nell'**opzione 53** del DHCP, dentro il payload. Il flag `-v` di tcpdump la
stamperebbe.

Altri due dettagli da notare:

- I primi due pacchetti vanno a `255.255.255.255` partendo da `0.0.0.0`. Il
  client non ha ancora un indirizzo, quindi non può mandare un unicast normale né
  esserne destinatario. Tutto ciò che precede l'ACK è una conversazione in
  broadcast.
- L'`xid` lega i quattro pacchetti in un'unica transazione: è così che un client
  distingue il proprio scambio da quello di ogni altra macchina che urla sullo
  stesso dominio di broadcast. Guardando bene, la REQUEST sembra portarne uno
  diverso: è lo stesso numero con i byte invertiti. È una stranezza di come
  `dhclient` lo stampa, non una seconda transazione — si confrontino DISCOVER e
  ACK, che coincidono.

## 4. Il lease esiste su tutte e due le macchine

Il client ora tiene quello che gli è stato dato:

{{evidence:client-addr}}

E il server se l'è annotato. Un lease è un record con una scadenza, non
un'assegnazione:

{{evidence:leases}}

:::note Due lease, un solo client
Il file dei lease contiene più di una voce per questo MAC, e solo l'ultima è
`binding state active`. Ogni `dhclient -r` restituisce un indirizzo, e alla
DISCOVER successiva si può ricevere lo stesso oppure il primo libero: decide il
server, ed entrambi i comportamenti sono corretti. Un indirizzo è un prestito con
una scadenza, non una proprietà, e le voci scadute restano nel file come storia.
:::

Si noti `client-hostname "dhcp-lab-client"` nel record: il client ha mandato il
proprio nome nell'**opzione 12**, ed è così che un server DHCP può registrare i
nomi nel DNS senza che nessuno configuri niente a mano.

Il client ne tiene una copia propria, con le opzioni ricevute:

{{evidence:client-lease}}

## 5. Verifica

{{evidence:qlab-test grep="Exercise|All exercises|Exercises " as=shell}}

## 6. Cosa portarsi via

- Un server DHCP serve un'**interfaccia**, non una macchina. Su un host con due
  schede l'errore più comune in assoluto è servire quella sbagliata — o non
  partire affatto perché non si è detto quale.
- `tcpdump` mostra richieste e risposte BOOTP; i quattro nomi del DORA stanno
  nell'opzione 53 dentro il pacchetto. Il log del client è il posto più comodo
  per leggerli.
- Tutto lo scambio prima dell'ACK è traffico broadcast, perché il client non ha
  un indirizzo a cui essere raggiunto.
- Un lease è un prestito con scadenza. Rilasciarlo non lo riporta indietro, e il
  server è libero di dare un indirizzo diverso la volta dopo.
- `authoritative` cambia cosa succede quando un client chiede qualcosa di
  sbagliato: un rifiuto esplicito invece del silenzio.

`guide.md` del plugin porta avanti il discorso: tempi di lease, opzioni
personalizzate, prenotazioni statiche per MAC e due pool sulla stessa sottorete.
