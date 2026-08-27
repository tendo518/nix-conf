# Gitea: self-hosted Git service.
#   HTTP:      :3000 (lan0 + tailscale0 only)
#   Database:  SQLite at /var/lib/gitea/data/gitea.db
#
# Registration is disabled on purpose. The admin account is created after the
# first deployment with `gitea admin user create` using the agenix-secret
# tendo-password, so no public signup is ever exposed on the LAN.
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/gitea" =
    { pkgs, ... }:
    {
      services.gitea = {
        enable = true;

        settings = {
          server = {
            # Canonical URL reachable from both LAN and tailnet (see caddy.nix).
            DOMAIN = "server-lab-sardine.tailscale";
            # Served through Caddy on :80, so drop the :3000 suffix.
            ROOT_URL = "http://server-lab-sardine.tailscale/gitea/";
            # Loopback only; Caddy proxies /gitea -> 127.0.0.1:3000.
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
            # HTTP clone only for now; SSH cloning can be enabled later.
            DISABLE_SSH = true;
          };
          service.DISABLE_REGISTRATION = true;
        };
      };

      # Keep the admin CLI available for provisioning and maintenance.
      environment.systemPackages = [ pkgs.gitea ];

      # Access is via Caddy (http://gitea.lan); the direct :3000 port stays
      # reachable only from the host itself.
    };
}
