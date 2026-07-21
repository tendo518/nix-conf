{
  flake.modules.nixos."network/tailscale" =
    { pkgs, lib, config, ... }:
    {
      age.secrets.tailscale-authkey = {
        file = ../../secrets/tailscale-authkey.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      environment.systemPackages = [
        pkgs.tailscale
        # Manually authenticate to Tailscale with the agenix auth key (replaces
        # the removed auth-key autoconnect, which stalled boot behind the GFW).
        # The key is root-owned, so the script re-execs under sudo to read it
        # and run `tailscale login` as root - this works unconditionally,
        # regardless of --operator. Run when the control plane is reachable.
        (pkgs.writeShellScriptBin "tailscale-auth" ''
          if [ "$(id -u)" -ne 0 ]; then exec sudo -- "$0" "$@"; fi
          exec ${lib.getExe pkgs.tailscale} login --auth-key "$(cat ${config.age.secrets.tailscale-authkey.path})" "$@"
        '')
      ];
      services.tailscale = {
        enable = true;
        interfaceName = "tailscale0";
        openFirewall = true;
        # Default role: accept advertised subnet routes so this host can reach
        # remote subnets (e.g. the lab networks advertised by desktop-lab-peace).
        # extraSetFlags runs `tailscale set` on every activation so prefs
        # persist. Hosts that advertise routes override both of these
        # (useRoutingFeatures = "server" + their own extraSetFlags); the
        # mkDefault lets that override win cleanly.
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
    { pkgs, lib, config, ... }:
    {
      age.secrets.tailscale-authkey = {
        file = ../../secrets/tailscale-authkey.age;
      };
      environment.systemPackages = [
        pkgs.tailscale
        # Manually authenticate to Tailscale with the agenix auth key, mirroring
        # the Linux tailscale-auth script. The nix-darwin tailscale module has
        # no authKey option, so login is manual. The script re-execs under sudo
        # (macOS tailscale needs root); run when the control plane is reachable.
        # macOS auto-accepts advertised subnet routes, so no --accept-routes flag.
        (pkgs.writeShellScriptBin "tailscale-auth" ''
          if [ "$(id -u)" -ne 0 ]; then exec sudo -- "$0" "$@"; fi
          exec ${lib.getExe pkgs.tailscale} login --auth-key "$(cat ${config.age.secrets.tailscale-authkey.path})" "$@"
        '')
      ];
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
