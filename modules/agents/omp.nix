{
  flake.modules.home."agents/omp" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      providers = import ./_providers.nix {
        inherit config lib;
        agent = "omp";
      };
      selected = providers.selectProviders;

      defaultProvider = providers.defaultProvider selected;
      defaultProviderConfig = selected.${defaultProvider};
      defaultModel =
        defaultProviderConfig.models.${
          defaultProviderConfig.agentConfig.defaultModel or defaultProviderConfig.defaultModel
        }.id;

      toOmpProvider = _name: provider: {
        baseUrl = provider.endpoints.openai;
        api = "openai-completions";
        apiKey = ''!${pkgs.coreutils}/bin/cat "${provider.secretPath}"'';
        models = lib.mapAttrsToList (
          _model: model:
          {
            id = model.id;
            name = model.displayName;
            inherit (model) contextWindow;
            input = model.input or [ "text" ];
          }
          // lib.optionalAttrs (model ? maxOutputTokens) {
            maxTokens = model.maxOutputTokens;
          }
          // lib.optionalAttrs (model ? thinking) {
            reasoning = true;
            thinking = {
              mode = "effort";
              efforts = model.thinking.efforts;
              defaultLevel = model.thinking.default;
            };
          }
        ) provider.models;
      };

      ompProviders = lib.mapAttrs toOmpProvider selected;

      modelsYml = builtins.toJSON {
        providers = ompProviders;
      };

      configYml = builtins.toJSON {
        setupVersion = 1;
        modelRoles.default = "${defaultProvider}/${defaultModel}";
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

      age.secrets = providers.ageSecrets selected;
    };
}
