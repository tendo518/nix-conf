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
      thinkingLevels = [
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
        "max"
      ];
      effortValues =
        model:
        lib.concatMap (option: option.values or [ ]) (
          lib.filter (option: option.type == "effort") (model.reasoning_options or [ ])
        );
      ompThinking =
        model:
        let
          efforts = effortValues model;
          supportsOff = builtins.elem "none" efforts;
          levels = lib.filter (level: builtins.elem level efforts) thinkingLevels;
        in
        {
          mode = "effort";
          efforts = levels;
          # Preserve the declared wire spelling. OMP otherwise applies its
          # generic family fallback (for example Qwen xhigh -> high).
          effortMap = lib.genAttrs levels (level: level);
        }
        // lib.optionalAttrs supportsOff {
          # OMP's off selector is separate from its effort ladder. Keep the
          # ladder limited to values the endpoint accepts, and allow an
          # explicit off request instead of normalizing it to the lowest tier.
          requiresEffort = false;
          suppressWhenOff = true;
        };
      ompProviders = lib.mapAttrs (_name: provider: {
        baseUrl = provider.endpoints.openai;
        api = provider.agentConfig.api or "openai-completions";
        apiKey = ''!${pkgs.coreutils}/bin/cat "${provider.secretPath}"'';
        compat = lib.optionalAttrs ((provider.agentConfig.api or "openai-completions") == "openai-completions") (
          {
            supportsReasoningEffort = true;
          }
          # OMP has no explicit DeepSeek enum value; its endpoint detector
          # supplies that dialect. Keep the shared connection fact for Pi/DSH.
          // lib.optionalAttrs (provider.thinkingFormat or "openai" != "deepseek") {
            thinkingFormat = provider.thinkingFormat or "openai";
          }
          // lib.optionalAttrs (provider.thinkingFormat or "openai" == "qwen") {
            qwenTemplateReasoningEffort = true;
          }
        );
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
          // lib.optionalAttrs (model ? reasoning_options) {
            thinking = ompThinking model;
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
