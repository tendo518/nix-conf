# Caddy: public :80 entry point for the Homepage dashboard.
#
# Homepage itself listens on loopback:8082; Caddy binds the privileged port
# and proxies all hosts to it. No DNS or hostname-based routing is used.
_: {
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/caddy" = _: {
    services.caddy = {
      enable = true;
      openFirewall = false;

      virtualHosts.":80" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8082
        '';
      };
    };
  };
}
