{
  flake.modules.home."agents/reasonix" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_providers.nix { inherit config lib; };
      selected = providers.selectProviders "reasonix";
      deepseek = selected.deepseek;
      agentConfig = deepseek.agents.reasonix;
      defaultModel = deepseek.models.${agentConfig.defaultModel};
      reasonixHome = "${config.xdg.configHome}/reasonix";

      reasonixWrapped = pkgs.writeShellScriptBin "reasonix" ''
        export REASONIX_HOME="${reasonixHome}"
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';

      reasonixConfig = ''
        config_version = 5
        default_model = "${agentConfig.providerName}"
        language      = "zh"

        [ui]
        theme = "auto"
        show_reasoning = true

        [notifications]
        enabled          = true
        turn_done        = true
        approval_request = true
        ask_request      = true

        [telemetry]
        cli_metrics = "off"

        [desktop]
        telemetry = false
        metrics = false

        [agent]
        temperature = 0.0
        auto_plan   = "off"
        soft_compact_ratio  = 0.5
        compact_ratio       = 0.8
        compact_force_ratio = 0.9

        [[providers]]
        name        = "${agentConfig.providerName}"
        kind        = "openai"
        base_url    = "${deepseek.endpoints.openai}"
        models      = [${
          lib.concatMapStringsSep ", " (model: ''"${model.id}"'') (lib.attrValues deepseek.models)
        }]
        default     = "${deepseek.models.${agentConfig.defaultModel}.id}"
        api_key_env = "${agentConfig.apiKeyEnv}"
        balance_url = "${deepseek.endpoints.balance}"
        effort      = "${defaultModel.thinking.default}"
        context_window = ${toString defaultModel.contextWindow}
        ${lib.optionalString (
          defaultModel ? maxOutputTokens
        ) "max_output_tokens = ${toString defaultModel.maxOutputTokens}"}

        [tools]
        enabled = []
        bash_timeout_seconds = 120

        [serve]
        auth_mode = "none"
        behind_proxy = false

        [permissions]
        mode = "ask"

        [sandbox]
        workspace_root = ""
        allow_write    = ["/tmp"]
        bash    = "enforce"
        network = true
      '';
    in
    {
      home.packages = [
        pkgs.llm-agents.codegraph
        reasonixWrapped
      ];

      xdg.configFile."reasonix/config.toml".force = true;
      xdg.configFile."reasonix/config.toml".text = reasonixConfig;

      home.activation.setupReasonixEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${reasonixHome}"
        if [ ! -e "${reasonixHome}/.env" ] && [ -r "${deepseek.secret.path}" ]; then
          umask 077
          printf 'DEEPSEEK_API_KEY=%s\n' "$(cat "${deepseek.secret.path}")" > "${reasonixHome}/.env"
        fi
      '';

      age.secrets = providers.ageSecrets selected;
    };
}
