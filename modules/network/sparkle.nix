# Sparkle proxy application with TUN mode enabled
{
  flake.modules.nixos."network/sparkle" =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.sparkle ];

      security.wrappers.sparkle = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_bind_service,cap_net_raw,cap_net_admin=+ep";
        source = "${lib.getExe pkgs.sparkle}";
      };
    };
}
