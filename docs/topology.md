# Network & Service Topology

Living reference for how the machines, the tailnet, subnet routing, and the
server's services interconnect. Keep this in sync when the config changes.
Single sources of truth are referenced inline: **`modules/network/tailscale.nix`**
(subnet-router defaults and dynamic host completion),
**`modules/hosts/server-lab-sardine/*`** (server services).

---

## 1. Machines & Tailnet

Mesh overlay via **Tailscale MagicDNS**. Fish completes live peer DNS names from
`tailscale status --json`; selected `<host>.tailscale` names resolve through
MagicDNS without a static host/IP table.

| host | OS | ssh user |
|------|----|----------|
| `desktop-home-saki` | NixOS | tendo |
| `desktop-lab-peace` | NixOS | pengwy |
| `laptop-solar-chiyoko` | NixOS | tendo |
| `laptop-solar-modoka` | **Darwin** | tendo |
| `server-lab-sardine` | NixOS | tendo |

---

## 2. Server as LAN Router (physical / link layer)

`server-lab-sardine` is an AZW N100 acting as the lab router **and** service host.
Networking is `systemd-networkd`; interfaces pinned to onboard MACs
(`modules/hosts/server-lab-sardine/router.nix`).

```
  upstream / lab network
        │
 wan0  enp1s0  10.16.26.24/17   (DHCP; src 10.16.0.0/17, the lab main net)
        │  NAT (+ BBR/cake/ip_forward=1)
 lan0  enp2s0  192.168.11.1/24  (static; dnsmasq DNS:53 + DHCP:67)
```

- WAN = `wan0`, DHCP from lab, NAT exit for `lan0`.
- LAN = `lan0`, static `192.168.11.1/24`, dnsmasq provides DNS+DHCP.

> **Stale comment**: `router.nix` header still says WAN is `192.168.16.x`; the
> running system is actually `10.16.26.24/17`. Edit the comment if you touch that
> file.

---

## 3. Tailnet Subnet Routing

Single subnet router: **`server-lab-sardine`** advertises all lab routes
(`router.nix`); every other host accepts routes (default in `tailscale.nix` is
`--accept-routes` + `useRoutingFeatures = "client"`).

Advertised routes (**server**, after config lands):

| subnet | meaning |
|--------|---------|
| `192.168.11.0/24` | server's own LAN (`lan0`) |
| `10.16.0.0/17` | lab main net (server's `wan0` and desktop-lab-peace's `eno1` both live here) |
| `172.18.36.0/23` | lab subnet (NAS `172.18.36.178/179/180`) |
| `172.18.34.0/23` | lab subnet |

**Route approval** is required per-subnet in the Tailscale admin console (or ACL
`autoApprovers`). `10.16.0.0/17` + the two `172.18/23` need approval on the
server's node.

### desktop-lab-peace — prevent direct traffic from going via Tailscale

`desktop-lab-peace` sits directly on `10.16.0.0/17` (`eno1`). Since the server
advertises the same subnets, the host would otherwise hairpin its own LAN / NAS
traffic through Tailscale (Tailscale policy rules live at priority 5200–5500).
A one-shot unit (`hosts/desktop-lab-peace/default.nix`) installs higher-priority
`ip rule`s that go back to the **main** table, so direct paths win:

```
ip rule add to 10.16.0.0/17  priority 2500 lookup main   # own LAN (eno1) direct
ip rule add to 172.18.36.0/23 priority 2500 lookup main  # NAS → default gw direct
ip rule add to 172.18.34.0/23 priority 2500 lookup main  # lab → default gw direct
```

`desktop-lab-peace` does **not** advertise routes itself (changed from its former
subnet-router role) — it is a plain `--accept-routes` client now.

---

## 4. Server Services — loopback + Caddy entry point

Security model: only **Caddy (:80)** is exposed; every backend binds
`127.0.0.1` and is reverse-proxied by Caddy
(`server-lab-sardine/selfhost/{caddy,garage,gitea,cockpit,monitoring}.nix`).
(File sync was removed from the deploy; see `docs/sync-solution.md` for the
Syncthing vs S3+rclone comparison before re-adding.)

```
 client (LAN / tailnet)
   http://server-lab-sardine.tailscale …│… http://router.lan (index, LAN only)
     ┌─────────────────────────────────────┐
     │  Caddy :80  env, no TLS            │  <-- only HTTP entry
     │   /gitea   → 127.0.0.1:3000  Gitea │
     │   /s3      → 127.0.0.1:3900  S3    │
     │   /s3admin → 127.0.0.1:3903  admin │
     │   /cockpit → 127.0.0.1:9090  Cockpit │
     │   /        → 127.0.0.1:19999 Netdata│
     └─────────────────────────────────────┘
 ```

| service | listen | access |
|---------|--------|--------|
| Caddy | 0.0.0.0:80 | `server-lab-sardine.tailscale` / `router.lan` |
| Gitea | 127.0.0.1:3000 | `/gitea` |
| Garage S3 / admin / rpc | 127.0.0.1:3900 / 3903 / 3901 | `/s3`, `/s3admin` |
| Garage web (websites) | 127.0.0.1:3902 | **unreachable** (route removed) |
| Cockpit (libvirt/KVM) | 127.0.0.1:9090 | `/cockpit` |
| Netdata / vnstat / smartd | 127.0.0.1:19999 | `/` |
| dnsmasq | lan0 :53/:67 | LAN |

Caddy vhosts: only the canonical `server-lab-sardine.tailscale`(+IP) with
per-path routing, and `router.lan` as the LAN index. (All per-service `*.lan`
aliases were removed.)

### Firewall exposure (after consolidation)

- `tailscale0`: TCP **80**
- `lan0`:       TCP **80, 53** · UDP **53, 67**

Not exposed anywhere: `8384 9090 19999 3900 3901 3902 3903` (8384 no longer
relevant; Syncthing removed).

---

## 5. File sync

Syncthing was **removed from the deploy** pending a decision between it and
object-storage+rclone. See **`docs/sync-solution.md`** for the comparison and
the Nix config sketch for whichever approach is chosen next.

---

## 6. Open / pending items

- [ ] Approval in Tailscale admin for server's `10.16.0.0/17` and both `172.18/23`
      advertised routes; revoke desktop-lab-peace's old advertised routes.
- [ ] Pick a file-sync approach (see `docs/sync-solution.md`) and configure it;
      Syncthing and S3+rclone are currently both unconfigured.
- [ ] Tailnet node cleanup: delete offline dead node `server-lab-sardine`
      (`100.70.253.124`), rename live node `server-lab-sardine-1` → `server-lab-sardine`.
- [ ] (Decide) Garage web hosting (`*.web.lan`) was dropped with the `.lan`
      removal; add a `/web` path route only if static-site hosting is used.
- [ ] Deploy pending config to `server-lab-sardine` and `desktop-lab-peace`
      (both `x86_64-linux`; need `nixos-rebuild switch` / `nh os switch`).
