# Garage v2: lightweight S3-compatible object storage.
#   S3 API:    :3900
#   Web host:  :3902
#   Admin API: :3903 (tailnet only)
{ ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/selfhost/garage" =
    { pkgs, ... }:
    {
      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        settings = {
          metadata_dir = "/var/lib/garage/meta";
          data_dir = "/var/lib/garage/data";
          replication_factor = 1;
          consistency_mode = "consistent";

          # All garage endpoints bind to loopback; they are only reachable
          # through the Caddy :80 entry point (S3/Web via *.s3.lan/*.web.lan,
          # admin via /s3admin). Nothing is exposed on the wire.
          rpc_bind_addr = "127.0.0.1:3901";
          rpc_public_addr = "127.0.0.1:3901";
          rpc_secret = "2f3105f65923a12c39a942502049ce778f44a0e469a1cfe19ec31e0e4f8b2847";

          s3_api = {
            s3_region = "us-east-1";
            api_bind_addr = "127.0.0.1:3900";
            root_domain = ".s3.lan";
          };

          s3_web = {
            bind_addr = "127.0.0.1:3902";
            root_domain = ".web.lan";
          };

          admin = {
            api_bind_addr = "127.0.0.1:3903";
            admin_token = "4deed2a5ba0024e1f2f73201afbde73d6b5036440d874b33b7bc51591358f0b6";
          };
        };
      };

      # No direct firewall openings: all garage ports are loopback-bound and
      # proxied by Caddy. (Root-domain virtual-host bucket URLs still work
      # because caddy forwards *.s3.lan / *.web.lan to 3900/3902.)
    };
}
