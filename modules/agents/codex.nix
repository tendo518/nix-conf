{
  flake.modules.home."agents/codex" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_context.nix {
        inherit config lib;
        settings = (import ./_agents.nix).codex;
      };
      inherit (providers) selected;
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

      # Required catalog fields. Model facts do not imply API-specific controls.
      mkCatalogModel = model: {
        slug = model.id;
        display_name = model.name;
        description = model.description or model.name;
        default_reasoning_level = null;
        supported_reasoning_levels = [ ];
        input_modalities = lib.intersectLists [ "text" "image" ] model.modalities.input;
        context_window = model.limit.context;
        max_context_window = model.limit.context;
        shell_type = "shell_command";
        visibility = "list";
        supported_in_api = true;
        priority = 1;
        support_verbosity = false;
        default_verbosity = "low";
        apply_patch_tool_type = "freeform";
        web_search_tool_type = "text";
        truncation_policy = {
          mode = "tokens";
          limit = 10000;
        };
        experimental_supported_tools = [ ];
        supports_parallel_tool_calls = false;
        multi_agent_version = "v2";
        effective_context_window_percent = 95;
        comp_hash = "3000";
        reasoning_summary_format = "experimental";
        default_reasoning_summary = "none";
        supports_search_tool = false;
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
          providerId = agentConfig.providerId or name;
          profile = agentConfig.profile or "codex-${name}";
          inherit (provider) defaultModel;
          catalog =
            pkgs.runCommand "${profile}-models.json"
              {
                nativeBuildInputs = [ pkgs.jq ];
                models = builtins.toJSON {
                  models = lib.mapAttrsToList (_model: mkCatalogModel) provider.models;
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
          profileConfig = toml.generate "${profile}.config.toml" {
            model = defaultModel.id;
            model_provider = providerId;
            model_catalog_json = toString catalog;
            web_search = "disabled";
            # Experimental context management is for the official provider.
            features.context_management.experimental_mode = false;
            tui.status_line = [
              "model-with-reasoning"
              "project-name"
              "run-state"
              "context-used"
            ];
          };
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
        model_providers = lib.mapAttrs' (
          name: provider:
          lib.nameValuePair (provider.agentConfig.providerId or name) {
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
          }
        ) selected;
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

      age.secrets = providers.ageSecrets;
    };
}
