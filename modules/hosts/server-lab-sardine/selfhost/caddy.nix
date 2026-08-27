# Caddy: single entry point for all web services.
#   :80 - the canonical hostname (server-lab-sardine.tailscale) with one path
#         per service; router.lan keeps the LAN landing index.
#
# Everything is plain HTTP on purpose: this is a private LAN/tailnet hostname,
# so there is no public ACME certificate to obtain. Cockpit is still TLS on its
# own backend port and is proxied with verification skipped.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/caddy" =
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
          # Tailnet entry point: single hostname, one path per service.
          # Clients resolve server-lab-sardine.tailscale via /etc/hosts (modules/network/tailnet.nix).
          # No per-service *.lan aliases, no raw-IP vhost.
          "http://server-lab-sardine.tailscale" = {
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
              # Garage admin REST API (bound to loopback; exposes management
              # only over the tailnet through Caddy).
              handle_path /s3admin/* {
                reverse_proxy 127.0.0.1:3903
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

      # LAN-only aliases resolve to the router's LAN address. Services are all
      # reached via the canonical hostname below; router.lan is just the index.
      services.dnsmasq.settings.address = [
        "/router.lan/192.168.11.1"
        # Canonical tailnet hostname; LAN clients resolve it to the router so
        # the same URLs work from LAN and tailnet.
        "/server-lab-sardine.tailscale/192.168.11.1"
      ];

      # Caddy port 80 is the only new entry point; keep it off the WAN.
      networking.firewall.interfaces.lan0.allowedTCPPorts = [ 80 ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 ];
    };
}
