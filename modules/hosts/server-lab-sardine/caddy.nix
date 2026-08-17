# Caddy: single entry point for all web services on the LAN.
#   :80  - http://router.lan (index) + per-service *.lan virtual hosts
#
# Everything is plain HTTP on purpose: these are private LAN/tailnet
# hostnames served by dnsmasq, so there is no public ACME certificate to
# obtain. Cockpit is still TLS on its own backend port and is proxied with
# verification skipped.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/caddy" =
    { ... }:
    {
      services.caddy = {
        enable = true;
        openFirewall = false;

        # Never try to obtain public certs for the .lan hostnames.
        globalConfig = ''
          auto_https off
        '';

        virtualHosts = {
          "http://gitea.lan" = {
            # Gitea's canonical URL is http://server-lab-sardine.tailscale/gitea
            # (usable from both LAN and tailnet); keep the old .lan alias.
            extraConfig = "redir http://server-lab-sardine.tailscale/gitea 301";
          };
          # Garage web endpoint; *.web.lan maps to website buckets.
          "http://garage.lan, http://*.web.lan" = {
            extraConfig = "reverse_proxy 127.0.0.1:3902";
          };
          # Garage S3 API; *.s3.lan enables virtual-host style bucket URLs.
          "http://s3.lan, http://*.s3.lan" = {
            extraConfig = "reverse_proxy 127.0.0.1:3900";
          };
          "http://stats.lan" = {
            extraConfig = "reverse_proxy 127.0.0.1:19999";
          };
          "http://cockpit.lan" = {
            extraConfig = ''
              reverse_proxy https://127.0.0.1:9090 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            '';
          };
          # Tailnet entry point: single hostname, one path per service.
          # Clients resolve server-lab-sardine.tailscale via /etc/hosts
          # (modules/network/tailnet.nix); the IP form also matches.
          "http://server-lab-sardine.tailscale, http://100.70.253.124" = {
            extraConfig = ''
              # Gitea routes live at the root of :3000; ROOT_URL's /gitea path
              # only affects generated links, so strip the prefix here.
              handle /gitea {
                redir /gitea/ 301
              }
              handle_path /gitea/* {
                reverse_proxy 127.0.0.1:3000
              }
              handle_path /s3/* {
                reverse_proxy 127.0.0.1:3900
              }
              handle /s3 {
                redir /s3/ 301
              }
              handle /cockpit {
                redir /cockpit/login 301
              }
              handle /cockpit* {
                reverse_proxy https://127.0.0.1:9090 {
                  transport http {
                    tls_insecure_skip_verify
                  }
                }
              }
              handle {
                reverse_proxy 127.0.0.1:19999
              }
            '';
          };
          "http://router.lan, http://192.168.11.1" = {
            extraConfig = ''
              respond `<html><body style="font-family:sans-serif"><h1>server-lab-sardine</h1><ul><li><a href="http://server-lab-sardine.tailscale/gitea">Gitea</a></li><li><a href="http://server-lab-sardine.tailscale/s3">Garage (S3)</a></li><li><a href="http://server-lab-sardine.tailscale/">Netdata</a></li><li><a href="http://server-lab-sardine.tailscale/cockpit">Cockpit</a></li></ul></body></html>` 200
            '';
          };
        };
      };

      # All *.lan names resolve to the router's LAN address.
      services.dnsmasq.settings.address = [
        "/router.lan/192.168.11.1"
        "/gitea.lan/192.168.11.1"
        "/garage.lan/192.168.11.1"
        "/web.lan/192.168.11.1"
        "/s3.lan/192.168.11.1"
        "/stats.lan/192.168.11.1"
        "/cockpit.lan/192.168.11.1"
        # Canonical tailnet hostname; LAN clients resolve it to the router so
        # the same URLs work from LAN and tailnet.
        "/server-lab-sardine.tailscale/192.168.11.1"
      ];

      # Caddy port 80 is the only new entry point; keep it off the WAN.
      networking.firewall.interfaces.lan0.allowedTCPPorts = [ 80 ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 ];
    };
}
