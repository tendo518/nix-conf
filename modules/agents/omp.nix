{
  flake.modules.home."agents/omp" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_context.nix {
        inherit config lib;
        settings = (import ./_agents.nix).omp;
      };
      inherit (providers) selected defaultProvider defaultModel;
      ompProviders = lib.mapAttrs (_name: provider: {
        baseUrl = provider.endpoints.openai;
        api = provider.agentConfig.api or "openai-completions";
        apiKey = ''!${pkgs.coreutils}/bin/cat "${provider.secretPath}"'';
        models = lib.mapAttrsToList (
          _key: model:
          {
            inherit (model) id name reasoning;
            contextWindow = model.limit.context;
            input = lib.intersectLists [ "text" "image" ] model.modalities.input;
          }
          // lib.optionalAttrs (model.limit ? output) {
            maxTokens = model.limit.output;
          }
        ) provider.models;
      }) selected;

      modelsYml = builtins.toJSON {
        providers = ompProviders;
      };

      configYml = builtins.toJSON {
        setupVersion = 1;
        modelRoles.default = "${defaultProvider}/${defaultModel.id}";
        startup = {
          checkUpdate = false;
          setupWizard = false;
          quiet = true;
        };
        marketplace.autoUpdate = "off";
        model.loopGuard.enabled = true;
        retry.maxRetries = 5;
        tools.approvalMode = "yolo";
        bash.gitGuard = true;
        providers = {
          streamFirstEventTimeoutSeconds = 120;
          streamIdleTimeoutSeconds = 300;
        };
        compaction = {
          enabled = true;
          thresholdPercent = 80;
          midTurnEnabled = true;
          asyncEnabled = true;
          dropUseless = true;
          supersedeReads = true;
        };
        lsp = {
          diagnosticsOnEdit = true;
          requestTimeout = 20;
        };
        edit.autoRepair.enabled = true;
        task = {
          enableLsp = true;
          maxConcurrency = 8;
          isolation = {
            enabled = true;
            apply = true;
            merge = "patch";
          };
          maxRecursionDepth = 2;
          showResolvedModelBadge = true;
        };
        web_search.enabled = true;
        github.enabled = true;
        fetch.enabled = true;
        skills = {
          enableClaudeUser = true;
          enablePiUser = true;
        };
        commands.enableClaudeUser = true;
        memory.backend = "off";
        tui.imeSafeCursor = true;
        terminal.showProgress = true;
        composer.tokenRate = true;
        display = {
          showTokenUsage = true;
          showTurnTime = true;
          cacheMissMarker = true;
          subagentLivePreview = true;
        };
        error.notify = "on";
        symbolPreset = "nerd";
        statusLine = {
          preset = "default";
          transparent = true;
        };
        images.blockImages = true;
        secrets.enabled = true;
      };
    in
    {
      home.packages = [ pkgs.llm-agents.omp ];

      home.file."./.omp/agent/models.yml" = {
        force = true;
        text = modelsYml;
      };
      home.file."./.omp/agent/config.yml" = {
        force = true;
        text = configYml;
      };

      age.secrets = providers.ageSecrets;
    };
}
