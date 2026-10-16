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
      toml = pkgs.formats.toml { };
      defaultModel = "gpt-6-luna";

      # Keep agent instructions in step with the installed Codex. Export only
      # its prompt; OpenAI-specific tool modes and capabilities do not apply
      # to our third-party providers.
      instructions =
        pkgs.runCommand "codex-model-instructions"
          {
            nativeBuildInputs = [ pkgs.jq ];
          }
          ''
            export CODEX_HOME="$TMPDIR/codex"
            mkdir -p "$CODEX_HOME"
            ${lib.getExe pkgs.llm-agents.codex} debug models --bundled \
              | jq -er --arg model ${lib.escapeShellArg defaultModel} \
                '.models[] | select(.slug == $model) | .base_instructions | select(length > 0)' \
              > "$out"
          '';

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
        {
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
          shell_type = "shell_command";
          visibility = "list";
          supported_in_api = true;
          priority = model.codexPriority or 1;
          support_verbosity = true;
          default_verbosity = "low";
          apply_patch_tool_type = "freeform";
          web_search_tool_type = "text";
          truncation_policy = {
            mode = "tokens";
            limit = 10000;
          };
          experimental_supported_tools = [ ];
          supports_parallel_tool_calls = provider.codexSupportsParallelToolCalls or true;
          multi_agent_version = "v2";
          effective_context_window_percent = 95;
          comp_hash = "3000";
          reasoning_summary_format = "experimental";
          default_reasoning_summary = "none";
          supports_search_tool = model.codexSupportsSearchTool or true;
        }
        // lib.optionalAttrs (model ? codexSupportsOriginalImageDetail) {
          supports_image_detail_original = model.codexSupportsOriginalImageDetail;
        };

      mkCodexWrapper =
        profile:
        pkgs.writeShellScriptBin profile ''
          export CODEX_HOME="${config.xdg.configHome}/codex"
          # `--profile` (config profile v2) cannot run on the shared background
          # server, so Codex falls back to embedded mode and notes that at
          # startup. Opt out of the shared server so the note never appears.
          exec ${lib.getExe pkgs.llm-agents.codex} --no-daemon --profile ${profile} "$@"
        '';

      # Everything Codex needs per provider: the generated catalog, the profile
      # that points at it, and the wrapper that selects that profile.
      providerArtifacts = lib.mapAttrs (
        name: provider:
        let
          agentConfig = provider.agentConfig;
          profile = agentConfig.profile or "codex-${name}";
          defaultModel = provider.models.${agentConfig.defaultModel or provider.defaultModel};
          catalog =
            pkgs.runCommand "${profile}-models.json"
              {
                nativeBuildInputs = [ pkgs.jq ];
                models = builtins.toJSON {
                  models = lib.mapAttrsToList (_model: model: mkCatalogModel provider model) provider.models;
                };
                passAsFile = [ "models" ];
              }
              ''
                jq --rawfile instructions ${instructions} \
                  '.models |= map(. + {base_instructions: $instructions})' \
                  "$modelsPath" > "$out"
              '';
        in
        {
          inherit catalog profile;
          profileConfig = toml.generate "${profile}.config.toml" (
            {
              model = defaultModel.id;
              model_provider = name;
              model_catalog_json = toString catalog;
              # Experimental context management is for the official provider.
              features.context_management.experimental_mode = false;
              tui.status_line = [
                "model-with-reasoning"
                "project-name"
                "run-state"
                "context-used"
              ];
            }
            // lib.optionalAttrs (agentConfig.reasoningSummaries or false) {
              model_reasoning_summary = "auto";
            }
            // lib.optionalAttrs (defaultModel ? thinking) {
              model_reasoning_effort = defaultModel.thinking.default;
            }
            // lib.optionalAttrs (agentConfig.disableWebSearch or false) {
              web_search = "disabled";
            }
          );
          wrapper = mkCodexWrapper profile;
        }
      ) selected;

      codexConfig = toml.generate "codex-config.toml" {
        model = defaultModel;
        model_provider = "openai";
        approval_policy = "on-request";
        approvals_reviewer = "auto_review";
        sandbox_mode = "workspace-write";
        check_for_update_on_startup = false;
        analytics.enabled = false;
        model_providers = lib.mapAttrs (_name: provider: {
          name = provider.name;
          base_url = provider.endpoints.openai;
          wire_api = "responses";
          stream_idle_timeout_ms = 600000;
          request_max_retries = 6;
          auth.command = toString (
            pkgs.writeShellScript "read-${provider.secret}" ''
              [ -r "${provider.secretPath}" ] || exit 1
              value="$(<"${provider.secretPath}")"
              printf '%s' "$value"
            ''
          );
        }) selected;
        features.context_management.experimental_mode = true;
        tui = {
          status_line = [
            "model-with-reasoning"
            "project-name"
            "run-state"
            "context-used"
            "weekly-limit"
          ];
          status_line_use_colors = true;
          notifications = true;
        };
        projects.${config.home.homeDirectory}.trust_level = "trusted";
      };

      codex = pkgs.writeShellScriptBin "codex" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';

      profileInstallLines = lib.concatStrings (
        lib.mapAttrsToList (_name: artifacts: ''
          install -m 0644 ${artifacts.profileConfig} "$cfgDir/${artifacts.profile}.config.toml"
        '') providerArtifacts
      );
    in
    {
      home.packages = [
        codex
      ]
      # Codex's Linux sandbox warns unless bwrap is on PATH, falling back
      # to the copy bundled in the Codex package.
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.bubblewrap ]
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
