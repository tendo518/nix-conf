# Shared Mihomo deployment.
_: {
  flake.modules.nixos."network/mihomo" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      desktop = config.services.displayManager.sessionPackages != [ ];
      configDir = "/etc/mihomo";
      configPath = "${configDir}/config.yaml";
      stateDir = "/var/lib/mihomo";
      mihomo = lib.getExe pkgs.mihomo;
      configTemplate = pkgs.writeText "mihomo-config-template.yaml" (
        builtins.readFile ./mihomo-config.yaml
      );
      ctlSettings = pkgs.writeText "mihomo-ctl-settings.json" (
        builtins.toJSON {
          config_path = configPath;
          state_dir = stateDir;
          template_path = toString configTemplate;
          controller_url = "http://127.0.0.1:9090";
          proxy_group = "PROXY";
          default_provider = "subscription";
          service_unit = "mihomo.service";
          routing_unit = "mihomo-routing.service";
          service_user = "mihomo";
          service_group = "mihomo";
          routing_table = 2023;
          tun_device = "mihomo";
          routing_state_file = "/run/mihomo-routing/rules";
          legacy_rule_patterns = [
            "iif mihomo"
            "lookup 2022"
            "198\\.18\\.0\\.0/30"
          ];
          legacy_route_tables = [ 2022 ];
          legacy_tun_devices = [ "Mihomo" ];
          preceding_rule_pattern = "fwmark 0x80000|lookup 52";
          commands = {
            ip = lib.getExe' pkgs.iproute2 "ip";
            ss = lib.getExe' pkgs.iproute2 "ss";
            systemctl = lib.getExe' pkgs.systemd "systemctl";
            journalctl = lib.getExe' pkgs.systemd "journalctl";
            systemd-creds = lib.getExe' pkgs.systemd "systemd-creds";
            inherit mihomo;
            sudo = "/run/wrappers/bin/sudo";
            pkexec = "/run/wrappers/bin/pkexec";
          };
        }
      );
      mihomoCtlBase =
        pkgs.writers.writePython3Bin "mihomo-ctl"
          {
            libraries =
              with pkgs.python3Packages;
              [
                rich
                typer
              ]
              ++ lib.optional desktop pyqt6;
            # The generated settings path may exceed 79 chars.
            flakeIgnore = [
              "E501"
              "W503"
            ];
          }
          (
            builtins.replaceStrings
              [ "DEFAULT_SETTINGS_PATH = None" ]
              [ "DEFAULT_SETTINGS_PATH = ${builtins.toJSON (toString ctlSettings)}" ]
              (builtins.readFile ./mihomo-ctl.py)
          );
      mihomoCtl =
        pkgs.runCommand "mihomo-ctl-with-fish-completion"
          {
            nativeBuildInputs = lib.optional desktop pkgs.qt6.wrapQtAppsHook;
            buildInputs = lib.optionals desktop [
              pkgs.qt6.qtbase
              pkgs.qt6.qtwayland
            ];
            dontWrapQtApps = true;
          }
          ''
            mkdir -p "$out/bin" "$out/share/fish/vendor_completions.d"
            ln -s ${mihomoCtlBase}/bin/mihomo-ctl "$out/bin/mihomo-ctl"
            _MIHOMO_CTL_COMPLETE=source_fish "$out/bin/mihomo-ctl" \
              > "$out/share/fish/vendor_completions.d/mihomo-ctl.fish"
            ${lib.optionalString desktop ''
              wrapQtApp "$out/bin/mihomo-ctl"
            ''}
          '';
    in
    {
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
      environment.systemPackages = [
        pkgs.mihomo
        mihomoCtl
      ];

      # XDG autostart runs only inside a graphical login session, including
      # Plasma and niri's systemd XDG autostart target.
      environment.etc."xdg/autostart/mihomo-tray.desktop" = lib.mkIf desktop {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Mihomo Tray
          Exec=${mihomoCtl}/bin/mihomo-ctl tray
          Icon=network-workgroup
          Terminal=false
        '';
      };

      security.polkit = lib.mkIf desktop {
        enable = true;
        enablePkexecWrapper = true;
      };

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
