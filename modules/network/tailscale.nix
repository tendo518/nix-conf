{
  flake.modules.nixos."network/tailscale" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.tailscale ];
      services.tailscale = {
        enable = true;
        interfaceName = "tailscale0";
        openFirewall = true;
        # useRoutingFeatures = "client";
        # extraUpFlags = "--accept-routes";
      };
    };
  flake.modules.darwin."network/tailscale" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.tailscale ];
      services.tailscale.enable = true;
    };
}
