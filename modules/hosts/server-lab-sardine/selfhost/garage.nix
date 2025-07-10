# Garage v2: lightweight S3-compatible object storage.
#   S3 API:    :3900
#   Web host:  :3902
#   Admin API: :3903 (tailnet only)
_: {
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

          # Only the LAN/tailnet firewall openings expose these service ports.
          rpc_bind_addr = "127.0.0.1:3901";
          rpc_public_addr = "127.0.0.1:3901";
          rpc_secret = "2f3105f65923a12c39a942502049ce778f44a0e469a1cfe19ec31e0e4f8b2847";

          s3_api = {
            s3_region = "us-east-1";
            api_bind_addr = "0.0.0.0:3900";
            root_domain = ".s3.lan";
          };

          s3_web = {
            bind_addr = "0.0.0.0:3902";
            root_domain = ".web.lan";
          };

          admin = {
            api_bind_addr = "0.0.0.0:3903";
            admin_token = "4deed2a5ba0024e1f2f73201afbde73d6b5036440d874b33b7bc51591358f0b6";
          };
        };
      };

      networking.firewall.interfaces.lan0.allowedTCPPorts = [
        3900
        3902
        3903
      ];
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        3900
        3902
        3903
      ];
    };
}
