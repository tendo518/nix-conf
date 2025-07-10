# Gitea: self-hosted Git service.
#   HTTP:      :3000 (lan0 + tailscale0 only)
#   Database:  SQLite at /var/lib/gitea/data/gitea.db
#
# Registration is disabled on purpose. The admin account is created after the
# first deployment with `gitea admin user create` using the agenix-secret
# tendo-password, so no public signup is ever exposed on the LAN.
_: {
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/gitea" =
    { pkgs, ... }:
    {
      services.gitea = {
        enable = true;

        settings = {
          server = {
            # Gitea needs one canonical absolute URL; use the LAN address,
            # which is also reachable through the advertised Tailscale route.
            DOMAIN = "192.168.11.1";
            ROOT_URL = "http://192.168.11.1:3000/";
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = 3000;
            # HTTP clone only for now; SSH cloning can be enabled later.
            DISABLE_SSH = true;
          };
          service.DISABLE_REGISTRATION = true;
        };
      };

      # Keep the admin CLI available for provisioning and maintenance.
      environment.systemPackages = [ pkgs.gitea ];

      networking.firewall.interfaces.lan0.allowedTCPPorts = [ 3000 ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3000 ];
    };
}
