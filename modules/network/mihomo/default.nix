# Shared Mihomo deployment.
{ ... }:
{
  flake.modules.nixos."network/mihomo" =
    { lib, pkgs, ... }:
    let
      configDir = "/etc/mihomo";
      configPath = "${configDir}/config.yaml";
      stateDir = "/var/lib/mihomo";
      mihomo = lib.getExe pkgs.mihomo;
      configTemplate = pkgs.writeText "mihomo-config-template.yaml" (builtins.readFile ./mihomo-config.yaml);
      mihomoCtl = pkgs.writers.writePython3Bin "mihomo-ctl" {
        libraries = [ pkgs.python3Packages.rich ];
        # The generated template path is a store path and may exceed 79 chars.
        flakeIgnore = [ "E501" "W503" ];
      } (
        builtins.replaceStrings
          [ "@MIHOMO_TEMPLATE_PATH@" ]
          [ (toString configTemplate) ]
          (builtins.readFile ./mihomo-ctl.py)
      );
    in
    {
      # Mihomo owns the only transparent-routing path on this host. Keep the
      # GUI applications available, but do not let them create competing TUNs.
      programs.clash-verge.tunMode = lib.mkForce false;
      programs.clash-verge.serviceMode = lib.mkForce false;
      programs.throne.tunMode.enable = lib.mkForce false;

      # Keep Tailscale routes, while leaving systemd-resolved/NetworkManager
      # in charge of DNS. Other hosts retain the shared module default.
      host.tailscale.upFlags = lib.mkForce [
        "--accept-routes"
        "--accept-dns=false"
      ];

      # Mihomo hands transparent TCP/UDP off through the local TUN interface.
      # The NixOS firewall must accept those packets back into INPUT, otherwise
      # the internal listener never completes the handshake (silent DROP).
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -i mihomo -j nixos-fw-accept
        ip6tables -A nixos-fw -i mihomo -j nixos-fw-accept
      '';

      users.groups.mihomo = { };
      users.users.mihomo = {
        isSystemUser = true;
        group = "mihomo";
      };

      # Only one helper executable is exported. The mihomo package itself is
      # still exported as the daemon binary named `mihomo`.
      environment.systemPackages = [ pkgs.mihomo mihomoCtl ];

      systemd.services.mihomo = {
        description = "Mihomo proxy engine";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = configPath;
        serviceConfig = {
          Type = "simple";
          User = "mihomo";
          Group = "mihomo";
          WorkingDirectory = stateDir;
          StateDirectory = "mihomo";
          Environment = "SAFE_PATHS=${configDir}";
          ExecStartPre = "${mihomo} -t -d ${stateDir} -f ${configPath}";
          ExecStart = "${mihomo} -d ${stateDir} -f ${configPath}";
          Restart = "on-failure";
          RestartSec = 2;
          AmbientCapabilities = [ "CAP_NET_ADMIN" ];
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
          DeviceAllow = [ "/dev/net/tun rw" ];
        };
      };

      systemd.services.mihomo-routing = {
        description = "Mihomo IPv4 policy routing";
        requires = [ "mihomo.service" ];
        after = [ "mihomo.service" ];
        bindsTo = [ "mihomo.service" ];
        path = [
          pkgs.coreutils
          pkgs.iproute2
          pkgs.systemd
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${mihomoCtl}/bin/mihomo-ctl routing start";
          ExecStop = "${mihomoCtl}/bin/mihomo-ctl routing cleanup";
        };
      };

    };
}
