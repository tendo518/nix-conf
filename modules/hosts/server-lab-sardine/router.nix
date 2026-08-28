# Soft-router configuration recovered from the running layout:
#   WAN: wan0 (enp1s0, currently the wired port on 192.168.16.x, DHCP client)
#   LAN: lan0 (enp2s0, static 192.168.11.1/24, dnsmasq DHCP + DNS)
# Interface names are pinned to the onboard NIC MACs so WAN/LAN never swap.
# Networking is managed by systemd-networkd.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/router" =
    { lib, ... }:
    {
      networking.useNetworkd = true;
      networking.dhcpcd.enable = false;
      networking.useDHCP = false;

      systemd.network.links = {
        "10-wan0" = {
          matchConfig.MACAddress = "7c:83:34:b9:3f:aa";
          linkConfig.Name = "wan0";
        };
        "20-lan0" = {
          matchConfig.MACAddress = "7c:83:34:b9:3f:ab";
          linkConfig.Name = "lan0";
        };
      };

      systemd.network.networks = {
        "10-wan0" = {
          matchConfig.Name = "wan0";
          networkConfig = {
            DHCP = "yes";
            IPv6AcceptRA = "yes";
            IPv6PrivacyExtensions = "kernel";
          };
          dhcpV4Config = {
            RouteMetric = 100;
            # dhcpcd used the MAC as client ID, so the upstream DHCP server
            # kept handing out 192.168.16.154. systemd-networkd defaults to
            # DUID, which made the server appear as a new client on .155.
            ClientIdentifier = "mac";
          };
        };
        "20-lan0" = {
          matchConfig.Name = "lan0";
          address = [ "192.168.11.1/24" ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
            LinkLocalAddressing = "ipv6";
          };
        };
      };

      # Forward LAN traffic to the WAN, NAT it, and apply basic router
      # performance tuning (BBR + cake + a couple of TCP tweaks).
      boot.kernelModules = [ "tcp_bbr" ];
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.core.default_qdisc" = "cake";
        "net.core.netdev_max_backlog" = 4096;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_fastopen" = 3;
      };
      networking.nat = {
        enable = true;
        externalInterface = "wan0";
        internalInterfaces = [ "lan0" ];
      };

      # Advertise the LAN and lab subnets through Tailscale and act as the
      # single subnet router. The lab subnets (172.18.36.0/23, 172.18.34.0/23,
      # 10.16.0.0/17) were previously advertised by desktop-lab-peace; the
      # server sits directly on 10.16.0.0/17 and reaches 172.18.x via the
      # default gateway, so routing is consolidated here.
      host.tailscale.upFlags = [
        "--advertise-routes=192.168.11.0/24,172.18.36.0/23,172.18.34.0/23,10.16.0.0/17"
        "--accept-dns"
      ];
      services.tailscale.useRoutingFeatures = "server";

      # LAN clients reach the router for DNS and DHCP.
      networking.firewall.interfaces.lan0 = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [
          53
          67
        ];
      };

      # DNS + DHCP server for the 192.168.11.0/24 LAN.
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = "lan0";
          # Serve DNS on the LAN and on the tailnet IP, so this dnsmasq can
          # act as a Tailscale "restricted nameserver" for the tailnet.
          # systemd-resolved owns 127.0.0.53, so avoid the wildcard :53 bind.
          bind-dynamic = true;
          listen-address = "192.168.11.1,100.81.243.74";
          dhcp-range = "192.168.11.100,192.168.11.199,255.255.255.0,12h";
          dhcp-option = [
            "option:router,192.168.11.1"
            "option:dns-server,192.168.11.1"
          ];
          domain-needed = true;
          bogus-priv = true;
          # Fallbacks if the WAN DHCP-provided upstream is unavailable.
          server = [
            "223.5.5.5"
            "119.29.29.29"
          ];
        };
      };
    };
}
