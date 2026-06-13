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

      home.file."./.hermes/config.yaml".force = true;
      home.file."./.hermes/config.yaml".text = ''
        model:
          default: "deepseek-v4-flash"
          provider: custom
          base_url: "https://ark.cn-beijing.volces.com/api/coding/v3"
          api_key: "''${VOLCENGINE_API_KEY}"
      '';

      age.secrets = {
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
