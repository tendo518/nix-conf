let
  # tailscale-auth: log in with the agenix auth key and apply host.tailscale.upFlags
  # + --operator to the profile (persists across reboots). Re-execs under sudo to
  # read the root-owned key.
  tailscaleAuth =
    {
      pkgs,
      lib,
      config,
      hostContext,
    }:
    pkgs.writeShellScriptBin "tailscale-auth" ''
      if [ "$(id -u)" -ne 0 ]; then exec sudo -- "$0" "$@"; fi
      exec ${lib.getExe pkgs.tailscale} up --auth-key "$(cat ${config.age.secrets.tailscale-authkey.path})" ${lib.escapeShellArgs config.host.tailscale.upFlags} --operator=${hostContext.user.name} "$@"
    '';

  # Shared by NixOS and Darwin: the upFlags option + the tailscale-auth command.
  # Replaces the NixOS module's extraSetFlags, which created a tailscaled-set
  # service that ran before login at boot (so the pref didn't persist). Default
  # accepts advertised subnet routes; desktop-lab-peace overrides to advertise.
  # --operator is added by the script itself, not per-host.
  common =
    {
      pkgs,
      lib,
      config,
      hostContext,
      ...
    }:
    {
      options.host.tailscale.upFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "--accept-routes" ];
        description = "Route flags passed to `tailscale up` by tailscale-auth (--operator is added automatically).";
      };
      config.environment.systemPackages = [
        pkgs.tailscale
        (tailscaleAuth {
          inherit
            pkgs
            lib
            config
            hostContext
            ;
        })
      ];
    };
in
{
  flake.modules.nixos."network/tailscale" =
    { lib, ... }:
    {
      imports = [ common ];
      config = {
        age.secrets.tailscale-authkey = {
          file = ../../secrets/tailscale-authkey.age;
          # root-owned: tailscale-auth re-execs under sudo to read it.
          owner = "root";
          group = "root";
          mode = "0400";
        };
        services.tailscale = {
          enable = true;
          interfaceName = "tailscale0";
          openFirewall = true;
          # Default role: accept advertised subnet routes so this host can reach
          # remote subnets (e.g. the lab networks advertised by desktop-lab-peace).
          # Hosts that advertise routes override host.tailscale.upFlags and set
          # useRoutingFeatures = "server"; the mkDefault lets that override win.
          useRoutingFeatures = lib.mkDefault "client";
        };
      };
    };
  flake.modules.darwin."network/tailscale" =
    { ... }:
    {
      imports = [ common ];
      config = {
        age.secrets.tailscale-authkey = {
          file = ../../secrets/tailscale-authkey.age;
        };
        # Route prefs are applied by tailscale-auth at auth time; just enabling
        # the daemon is enough here.
        services.tailscale.enable = true;
      };
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
