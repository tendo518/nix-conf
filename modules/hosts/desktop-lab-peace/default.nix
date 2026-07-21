# Desktop workstation at lab
# Host configuration and module registrations
{ ... }:
{
  # Host definition
  hosts.nixos.desktop-lab-peace = {
    modules = [
      "core"
      "system"
      "development"
      "agents"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-lab-peace"
      "hardware"
    ];
    excludeModules = [
      "apps/gaming"
      "desktop/niri"
      "hardware/lenovo-x13s"
    ];
    user = {
      name = "pengwy";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      # extraGroups = [ ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "26.05";
  };

  # Subnet router: advertise the lab networks to the tailnet. `useRoutingFeatures
  # = "server"` enables IP forwarding. host.tailscale.upFlags overrides the
  # default --accept-routes with --advertise-routes (--operator is added by the
  # tailscale-auth script). The advertised routes must be approved in the
  # Tailscale admin console (or via autoApprovers in the ACL) to take effect.
  # Do NOT add --accept-routes: a node that both advertises and accepts the same
  # route sends its own directly-connected subnet traffic through itself (the
  # HA subnet-router pitfall).
  flake.modules.nixos."hosts/desktop-lab-peace" =
    { ... }:
    {
      host.tailscale.upFlags = [
        "--advertise-routes=172.18.36.0/23,172.18.34.0/23,10.16.0.0/17"
      ];
      services.tailscale.useRoutingFeatures = "server";
    };

  # Hermes Telegram gateway — only on this host
  flake.modules.home."hosts/desktop-lab-peace" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets)
        volcengine-codingplan-api-key
        telegram-hermes-bot-key
        telegram-userid
        ;

      hermesGateway = pkgs.writeShellScriptBin "hermes-gateway" ''
        if [ -r "${volcengine-codingplan-api-key.path}" ]; then
          export VOLCENGINE_API_KEY="$(cat "${volcengine-codingplan-api-key.path}")"
        fi
        if [ -r "${telegram-hermes-bot-key.path}" ]; then
          export TELEGRAM_BOT_TOKEN="$(cat "${telegram-hermes-bot-key.path}")"
        fi
        if [ -r "${telegram-userid.path}" ]; then
          export TELEGRAM_ALLOWED_USERS="$(cat "${telegram-userid.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.hermes-agent} gateway
      '';
    in
    {
      home.packages = [ hermesGateway ];

      systemd.user.services.hermes-gateway = {
        Unit = {
          Description = "Hermes Agent Gateway";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe hermesGateway}";
          Restart = "on-failure";
          RestartSec = "10";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      age.secrets = {
        telegram-hermes-bot-key.file = ../../../secrets/telegram-hermes-bot-key.age;
        telegram-userid.file = ../../../secrets/telegram-userid.age;
      };
    };
}
