{
  flake.modules.homeManager."agents/hermes" =
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
        ;

      models = {
        kimi-k2-6 = "kimi-k2.6";
        glm-5-1 = "glm-5.1";
        minimax-m3 = "minimax-m3";
        ds-v4pro = "deepseek-v4-pro";
        ds-v4flash = "deepseek-v4-flash";
      };

      hermesWrapped = pkgs.writeShellScriptBin "hermes-agent" ''
        if [ -r "${volcengine-codingplan-api-key.path}" ]; then
          export VOLCENGINE_API_KEY="$(cat "${volcengine-codingplan-api-key.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.hermes-agent} "$@"
      '';

      mkHermesWrapper =
        name: model:
        pkgs.writeShellScriptBin "ha-vol-${name}" ''
          exec ${lib.getExe hermesWrapped} --model "${model}" "$@"
        '';

      hermesWrappers = lib.mapAttrsToList mkHermesWrapper models;

    in
    {
      home.packages = [ hermesWrapped ] ++ hermesWrappers;

      # Hermes Gateway systemd user service
      systemd.user.services.hermes-gateway = {
        Unit = {
          Description = "Hermes Agent Gateway";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe hermesWrapped} gateway";
          Restart = "on-failure";
          RestartSec = "10";
          EnvironmentFile = "%h/.hermes/.env";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      home.file."./.hermes/config.yaml".force = true;
      home.file."./.hermes/config.yaml".text = ''
        model:
          default: "deepseek-v4-flash"
          provider: custom
          base_url: "https://ark.cn-beijing.volces.com/api/coding/v3"
          api_key: "''${VOLCENGINE_API_KEY}"
      '';

      home.activation.setupHermesEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.hermes"
        envFile="$HOME/.hermes/.env"
        : > "$envFile"
        if [ -r "${volcengine-codingplan-api-key.path}" ]; then
          echo "VOLCENGINE_API_KEY=$(cat "${volcengine-codingplan-api-key.path}")" >> "$envFile"
        fi
        if [ -r "${telegram-hermes-bot-key.path}" ]; then
          echo "TELEGRAM_BOT_TOKEN=$(cat "${telegram-hermes-bot-key.path}")" >> "$envFile"
        fi
        echo "TELEGRAM_ALLOWED_USERS=1325155536" >> "$envFile"
        chmod 600 "$envFile"
      '';

      age.secrets = {
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
        telegram-hermes-bot-key.file = ../../secrets/telegram-hermes-bot-key.age;
      };
    };
}
