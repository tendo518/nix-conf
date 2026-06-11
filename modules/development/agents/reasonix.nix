{
  flake.modules.homeManager."development/agents/reasonix" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets) deepseek-api-key;

      reasonixWrapped = pkgs.writeShellScriptBin "reasonix" ''
        if [ -r "${deepseek-api-key.path}" ]; then
          export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';
    in
    {
      home.packages = [ reasonixWrapped ];

      xdg.configFile."reasonix/config.toml".text = ''
        default_model = "deepseek-flash"

        [[providers]]
        name        = "deepseek-flash"
        kind        = "openai"
        base_url    = "https://api.deepseek.com"
        model       = "deepseek-v4-flash"
        api_key_env = "DEEPSEEK_API_KEY"

        [[providers]]
        name        = "deepseek-pro"
        kind        = "openai"
        base_url    = "https://api.deepseek.com"
        model       = "deepseek-v4-pro"
        api_key_env = "DEEPSEEK_API_KEY"

        [agent]
        subagent_model = "deepseek-pro"
      '';

      age.secrets = {
        deepseek-api-key.file = ../../../secrets/deepseek-api-key.age;
      };
    };
}
