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
    let
      # One subdomain per service, resolved from the shared tailnet host table
      # (networking.hosts / darwin /etc/hosts). The root hostname is a plain
      # navigation index.
      base = "server-lab-sardine.tailscale";
    in
    {
      services.caddy = {
        enable = true;
        openFirewall = false;

        # Never try to obtain public certs for the .lan hostnames.
        globalConfig = ''
          auto_https off
        '';

        virtualHosts = {
          "http://${base}" = {
            extraConfig = ''
              respond `<html><body style="font-family:sans-serif"><h1>server-lab-sardine</h1><ul><li><a href="http://gitea.${base}">Gitea</a></li><li><a href="http://s3.${base}">Garage (S3)</a></li><li><a href="http://netdata.${base}">Netdata</a></li><li><a href="http://cockpit.${base}">Cockpit</a></li></ul></body></html>` 200
            '';
          };
          "http://gitea.${base}" = {
            extraConfig = "reverse_proxy 127.0.0.1:3000";
          };
          "http://s3.${base}" = {
            extraConfig = "reverse_proxy 127.0.0.1:3900";
          };
          "http://s3admin.${base}" = {
            extraConfig = "reverse_proxy 127.0.0.1:3903";
          };
          "http://cockpit.${base}" = {
            extraConfig = ''
              reverse_proxy https://127.0.0.1:9090 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            '';
          };
          "http://netdata.${base}" = {
            extraConfig = "reverse_proxy 127.0.0.1:19999";
          };
          "http://router.lan, http://192.168.11.1" = {
            extraConfig = ''
              respond `<html><body style="font-family:sans-serif"><h1>server-lab-sardine</h1><ul><li><a href="http://gitea.${base}">Gitea</a></li><li><a href="http://s3.${base}">Garage (S3)</a></li><li><a href="http://netdata.${base}">Netdata</a></li><li><a href="http://cockpit.${base}">Cockpit</a></li></ul></body></html>` 200
            '';
          };
        };
      };

      # LAN-only aliases resolve to the router's LAN address. The single
      # address=/server-lab-sardine.tailscale wildcard covers every subdomain
      # (gitea/s3/netdata/...), so LAN clients resolve the same URLs as tailnet.
      services.dnsmasq.settings.address = [
        "/router.lan/192.168.11.1"
        "/server-lab-sardine.tailscale/192.168.11.1"
      ];

      # Caddy port 80 is the only new entry point; keep it off the WAN.
      networking.firewall.interfaces.lan0.allowedTCPPorts = [ 80 ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 80 ];
    };
}
