{
  flake.modules.nixos."network/tailscale" =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [ pkgs.tailscale ];
      services.tailscale = {
        enable = true;
        interfaceName = "tailscale0";
        openFirewall = true;
        # Default role: accept advertised subnet routes so this host can reach
        # remote subnets (e.g. the lab networks advertised by desktop-lab-peace).
        # extraSetFlags runs `tailscale set` on every activation, unlike
        # extraUpFlags which only applies at first login. Hosts that advertise
        # routes override both of these (useRoutingFeatures = "server" + their
        # own extraSetFlags); the mkDefault lets that override win cleanly.
        useRoutingFeatures = lib.mkDefault "client";
        extraSetFlags = lib.mkDefault [ "--accept-routes" ];
      };
    };
  flake.modules.darwin."network/tailscale" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.tailscale ];
      # macOS auto-accepts advertised subnet routes (no --accept-routes flag
      # needed, unlike Linux), so just enabling the daemon is enough.
      services.tailscale.enable = true;
    };
}
