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
        extraSetFlags = lib.mkDefault [
          "--accept-routes"
          # Designate the host's primary user as the Tailscale operator so
          # they can run `tailscale` without sudo. Hosts that override
          # extraSetFlags (e.g. desktop-lab-peace, which advertises routes)
          # must re-add this flag, since the override replaces the whole list.
          "--operator=${config.host.user.name}"
        ];
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

  # Tailscale system tray (Linux only). Runs `tailscale systray` as a user
  # service so the tray icon appears in the desktop session. macOS uses the
  # standalone Tailscale menu bar app, so this is homeNixOS-only. Replaces the
  # previously hand-managed ~/.config/systemd/user/tailscale-systray.service.
  flake.modules.homeNixOS."network/tailscale" =
    { pkgs, lib, ... }:
    {
      systemd.user.services.tailscale-systray = {
        Unit = {
          Description = "Tailscale System Tray";
          Documentation = [ "https://tailscale.com/kb/1597/linux-systray" ];
          Requires = [ "dbus.service" ];
          After = [ "dbus.service" ];
          PartOf = [ "default.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.tailscale} systray";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
