{
  flake.modules.nixos."network/tailscale" =
    { pkgs, lib, config, ... }:
    {
      environment.systemPackages = [ pkgs.tailscale ];
      age.secrets.tailscale-authkey = {
        file = ../../secrets/tailscale-authkey.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      services.tailscale = {
        enable = true;
        interfaceName = "tailscale0";
        openFirewall = true;
        # Auto-auth at first login via an agenix secret. tailscaled-autoconnect
        # only runs `tailscale up --auth-key` while the backend is in
        # NeedsLogin state, so this is idempotent on later boots. Darwin's
        # nix-darwin module has no authKey option, so macOS still logs in via
        # the GUI app.
        authKeyFile = config.age.secrets.tailscale-authkey.path;
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
