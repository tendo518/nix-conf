{
  flake.modules.home."agents/codex" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ../_providers.nix { inherit config lib; };
      selected = providers.selectProviders "codex";
      baseline = builtins.fromJSON (builtins.readFile ./_model-baseline.json);

      mkCatalogModel =
        provider: model:
        let
          thinking =
            model.thinking or {
              efforts = [ ];
              default = null;
            };
        in
        baseline
        // {
          slug = model.id;
          display_name = model.displayName;
          description = model.description or "${model.displayName} via ${provider.name}";
          default_reasoning_level = thinking.default;
          supported_reasoning_levels = map (effort: {
            inherit effort;
            description = effort;
          }) thinking.efforts;
          input_modalities = model.input or [ "text" ];
          supports_image_detail_original =
            model.supportsImageDetailOriginal or baseline.supports_image_detail_original;
          context_window = model.contextWindow or null;
          max_context_window = model.contextWindow or null;
          priority = model.priority or baseline.priority;
        };

      catalogConfigs = lib.mapAttrs (
        _name: provider:
        pkgs.writeText "${provider.agents.codex.profile}-models.json" (
          builtins.toJSON {
            models = lib.mapAttrsToList (_model: model: mkCatalogModel provider model) provider.models;
          }
        )
      ) selected;

      providerBlocks = lib.concatStrings (
        lib.mapAttrsToList (
          _name: provider:
          let
            agentConfig = provider.agents.codex;
          in
          ''

            [model_providers.${agentConfig.providerName}]
            name = "${agentConfig.providerName}"
            base_url = "${provider.endpoints.responses}"
            wire_api = "responses"
            stream_idle_timeout_ms = 600000
            request_max_retries = 6
          ''
          + lib.optionalString (provider ? secret) ''

            [model_providers.${agentConfig.providerName}.auth]
            command = "${pkgs.writeShellScript "read-${provider.secret.name}" ''
              [ -r "${provider.secret.path}" ] || exit 1
              value="$(<"${provider.secret.path}")"
              printf '%s' "$value"
            ''}"
          ''
          + lib.optionalString (provider ? apiKey) ''
            experimental_bearer_token = "${provider.apiKey}"
          ''
        ) selected
      );

      codexConfig = pkgs.writeText "codex-config.toml" ''
        model = "gpt-5.6-terra"
        model_provider = "openai"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"
        ${providerBlocks}

        [tui]
        status_line = ["model-with-reasoning", "project-name", "run-state", "context-used", "weekly-limit"]
        status_line_use_colors = true

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
      '';

      profileConfigs = lib.mapAttrs (
        _name: provider:
        let
          agentConfig = provider.agents.codex;
          defaultModel = provider.models.${agentConfig.defaultModel};
        in
        pkgs.writeText "${agentConfig.profile}.config.toml" ''
          model = "${defaultModel.id}"
          model_provider = "${agentConfig.providerName}"
          model_catalog_json = "${catalogConfigs.${_name}}"
          ${lib.optionalString (agentConfig.reasoningSummaries or false) ''
            model_supports_reasoning_summaries = true
            model_reasoning_effort = "${defaultModel.thinking.default}"
          ''}
        ''
      ) selected;

      mkCodexWrapper =
        _name: provider:
        let
          profile = provider.agents.codex.profile;
        in
        pkgs.writeShellScriptBin profile ''
          export CODEX_HOME="${config.xdg.configHome}/codex"
          exec ${lib.getExe pkgs.llm-agents.codex} --profile ${profile} "$@"
        '';

      codex = pkgs.writeShellScriptBin "codex" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';

      profileInstallLines = lib.concatStrings (
        lib.mapAttrsToList (
          name: provider:
          let
            profile = provider.agents.codex.profile;
          in
          ''
            install -m 0644 ${profileConfigs.${name}} "$cfgDir/${profile}.config.toml"
          ''
        ) selected
      );
    in
    {
      home.packages = [
        codex
      ]
      ++ lib.mapAttrsToList mkCodexWrapper selected;

      home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfgDir="${config.xdg.configHome}/codex"
        mkdir -p "$cfgDir"
        if [ -e "$HOME/.codex" ] && [ ! -L "$HOME/.codex" ]; then
          mv "$HOME/.codex" "$HOME/.codex.bak.$(date +%s)"
        fi
        ln -sfn "$cfgDir" "$HOME/.codex"
        rm -f "$cfgDir/config.toml" "$cfgDir/codex-go.config.toml" "$cfgDir"/codex-*.config.toml
        install -m 0644 ${codexConfig} "$cfgDir/config.toml"
        ${profileInstallLines}
      '';

      age.secrets = providers.ageSecrets selected;
    };
}
