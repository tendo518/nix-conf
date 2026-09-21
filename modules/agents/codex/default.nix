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

      # Wording of the Codex CLI's own reasoning levels; a level the registry
      # declares beyond these falls back to the level name.
      reasoningLevelDescriptions = {
        low = "Fast responses with lighter reasoning";
        medium = "Balances speed and reasoning depth for everyday tasks";
        high = "Greater reasoning depth for complex problems";
        xhigh = "Extra high reasoning depth for complex problems";
        max = "Maximum reasoning depth for the hardest problems";
      };

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
            description = reasoningLevelDescriptions.${effort} or effort;
          }) thinking.efforts;
          input_modalities = model.input or [ "text" ];
          context_window = model.contextWindow or null;
          max_context_window = model.contextWindow or null;
        }
        # `codexCatalog` carries raw Codex catalog attributes: whatever the
        # registry writes there wins, so catalog fields need no per-field
        # plumbing here.
        // (model.codexCatalog or { });

      mkCodexWrapper =
        profile:
        pkgs.writeShellScriptBin profile ''
          export CODEX_HOME="${config.xdg.configHome}/codex"
          exec ${lib.getExe pkgs.llm-agents.codex} --profile ${profile} "$@"
        '';

      # Everything Codex needs per provider: the generated catalog, the profile
      # that points at it, and the wrapper that selects that profile.
      providerArtifacts = lib.mapAttrs (
        _name: provider:
        let
          agentConfig = provider.agents.codex;
          defaultModel = provider.models.${agentConfig.defaultModel};
          catalog = pkgs.writeText "${agentConfig.profile}-models.json" (
            builtins.toJSON {
              models = lib.mapAttrsToList (_model: model: mkCatalogModel provider model) provider.models;
            }
          );
        in
        {
          inherit catalog;
          profileConfig = pkgs.writeText "${agentConfig.profile}.config.toml" ''
            model = "${defaultModel.id}"
            model_provider = "${agentConfig.providerName}"
            model_catalog_json = "${catalog}"
            ${lib.optionalString (agentConfig.reasoningSummaries or false) ''
              model_reasoning_summary = "auto"
              model_reasoning_effort = "${defaultModel.thinking.default}"
            ''}
            ${lib.optionalString
              ((agentConfig.reasoningEffort or false) && !(agentConfig.reasoningSummaries or false))
              ''
                model_reasoning_effort = "${defaultModel.thinking.default}"
              ''
            }
            ${lib.optionalString (agentConfig.disableWebSearch or false) ''
              web_search = "disabled"
            ''}

            [features]
            # Experimental context management is only for the official OpenAI
            # provider; keep it disabled in third-party profiles.
            context_management.experimental_mode = false

            [tui]
            status_line = ["model-with-reasoning", "project-name", "run-state", "context-used"]
            status_line_use_colors = true
          '';
          wrapper = mkCodexWrapper agentConfig.profile;
        }
      ) selected;

      providerBlocks = lib.concatStrings (
        lib.mapAttrsToList (
          _name: provider:
          let
            agentConfig = provider.agents.codex;
            secretPath = config.age.secrets.${provider.secret}.path;
          in
          ''

            [model_providers.${agentConfig.providerName}]
            name = "${agentConfig.providerName}"
            base_url = "${provider.endpoints.responses}"
            wire_api = "responses"
            stream_idle_timeout_ms = 600000
            request_max_retries = 6
          ''
          + ''

            [model_providers.${agentConfig.providerName}.auth]
            command = "${pkgs.writeShellScript "read-${provider.secret}" ''
              [ -r "${secretPath}" ] || exit 1
              value="$(<"${secretPath}")"
              printf '%s' "$value"
            ''}"
          ''
        ) selected
      );

      codexConfig = pkgs.writeText "codex-config.toml" ''
        model = "gpt-5.6-terra"
        model_provider = "openai"
        approval_policy = "on-request"
        approvals_reviewer = "auto_review"
        sandbox_mode = "workspace-write"
        check_for_update_on_startup = false
        analytics.enabled = false
        ${providerBlocks}

        [features]
        context_management.experimental_mode = true

        [tui]
        status_line = ["model-with-reasoning", "project-name", "run-state", "context-used", "weekly-limit"]
        status_line_use_colors = true
        notifications = true

        [projects."${config.home.homeDirectory}"]
        trust_level = "trusted"
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
            install -m 0644 ${providerArtifacts.${name}.profileConfig} "$cfgDir/${profile}.config.toml"
          ''
        ) selected
      );
    in
    {
      home.packages = [
        codex
      ]
      ++ lib.mapAttrsToList (_name: provider: provider.wrapper) providerArtifacts;

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
