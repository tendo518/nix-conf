{
  flake.modules.home."agents/hermes" =
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

      hermesWrapped = pkgs.writeShellScriptBin "hermes-agent" ''
        if [ -r "${volcengine-codingplan-api-key.path}" ]; then
          export VOLCENGINE_API_KEY="$(cat "${volcengine-codingplan-api-key.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.hermes-agent} "$@"
      '';

    in
    {
      home.packages = [ hermesWrapped ];

      home.file."./.hermes/config.yaml".force = true;
      home.file."./.hermes/config.yaml".text = ''
        model:
          default: "deepseek-v4-flash"
          provider: custom
          base_url: "https://ark.cn-beijing.volces.com/api/coding/v3"
          api_key: "''${VOLCENGINE_API_KEY}"
        providers:
          custom:
            request_timeout_seconds: 600
      '';

      age.secrets = {
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
