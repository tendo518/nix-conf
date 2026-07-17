{
  flake.modules.home."agents/omp" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # --- Credentials & Secrets ---
      inherit (config.age.secrets)
        deepseek-api-key
        volcengine-codingplan-api-key
        ;

      # volces uses the Anthropic-compatible coding endpoint with omp's
      # `anthropic-messages` api (appends `/v1/messages` to baseUrl).
      # `apiKey` can be a command when prefixed with `!`. Read age secrets at
      # runtime so omp never falls back to sending the env-var name itself as
      # the bearer token when launched outside a wrapper.
      # `authHeader: true` injects `Authorization: Bearer <key>`.
      #
      # deepseek uses the OpenAI-compatible endpoint per DeepSeek's official
      # omp integration guide (api-docs.deepseek.com/.../oh_my_pi). The full
      # compat block is required - without the three critical fields
      # (supportsToolChoice, requiresReasoningContentForToolCalls,
      # requiresAssistantContentForToolCalls) DeepSeek V4 returns 400 errors
      # on tool calls in thinking mode. compat does not merge with built-in
      # entries, so the full set must be specified.
      #
      # contextWindow values are taken from omp's bundled model catalog
      # (packages/catalog/src/models.json) - the native provider entry for each
      # model: moonshot (kimi), zhipu-coding-plan (glm), minimax (MiniMax),
      # deepseek (deepseek-v4).
      apiKeyCommand = path: "!${pkgs.coreutils}/bin/cat ${path}";
      deepseekCompat = {
        reasoning = true;
        thinking = {
          minLevel = "high";
          maxLevel = "xhigh";
          mode = "effort";
        };
        input = [ "text" ];
        maxTokens = 384000;
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = true;
          maxTokensField = "max_tokens";
          reasoningEffortMap = {
            high = "high";
            xhigh = "max";
          };
          supportsToolChoice = false;
          requiresReasoningContentForToolCalls = true;
          requiresAssistantContentForToolCalls = true;
          extraBody = {
            thinking.type = "enabled";
          };
        };
      };
      providers = {
        volces = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          api = "anthropic-messages";
          apiKeyEnv = "VOLCENGINE_API_KEY";
          apiKeyPath = volcengine-codingplan-api-key.path;
          models = {
            kimi_k2_6 = {
              model = "kimi-k2.6";
              contextWindow = 256000;
            };
            kimi_k2_7_code = {
              model = "kimi-k2.7-code";
              contextWindow = 256000;
            };
            glm_5_2 = {
              model = "glm-5.2";
              contextWindow = 1024000;
            };
            minimax_m3 = {
              model = "minimax-m3";
              contextWindow = 512000;
            };
            ds_v4pro = {
              model = "deepseek-v4-pro";
              contextWindow = 1024000;
            };
            ds_v4flash = {
              model = "deepseek-v4-flash";
              contextWindow = 1024000;
            };
          };
        };
        deepseek = {
          baseUrl = "https://api.deepseek.com";
          api = "openai-completions";
          apiKeyEnv = "DEEPSEEK_API_KEY";
          apiKeyPath = deepseek-api-key.path;
          models = {
            ds_v4flash = {
              model = "deepseek-v4-flash";
              name = "DeepSeek V4 Flash";
              contextWindow = 1000000;
              extra = deepseekCompat;
            };
            ds_v4pro = {
              model = "deepseek-v4-pro";
              name = "DeepSeek V4 Pro";
              contextWindow = 1000000;
              extra = deepseekCompat;
            };
          };
        };
      };

      # --- Single-model wrappers ---
      # Each wrapper pins ALL model roles to the same model and disables the
      # advisor, so there are no subagents or multi-model interactions —
      # just a clean single-model session. Uses --config overlay so it works
      # regardless of what the user's ~/.omp/agent/config.yml contains.

      # `/resume` and startup `--resume`/`--continue` both restore the
      # session's last model. A wrapper should still stay pinned to its
      # provider/model, even though models.yml can now read all configured age
      # secrets itself. Two levers suppress cross-provider restore:
      #  - `disabledProviders` overlay gates getAvailable() *before* the auth
      #    check, so interactive `/resume` (switchSession) can't find the
      #    cross-provider model and keeps the wrapper's pinned model.
      #  - `--model` sets hasExplicitModel, so startup `--resume`/`--continue`
      #    (which uses hasConfiguredAuth, ignoring disabledProviders) skips the
      #    restore entirely.
      # Same-provider/different-model resumes still restore but share the
      # exported key, so they don't fail.
      disabledProvidersFor =
        roleValues:
        let
          used = lib.unique (map (v: lib.head (lib.splitString "/" v)) roleValues);
        in
        lib.subtractLists used (lib.attrNames providers);
      mkOmpWrapper =
        providerName: provider: name: m:
        let
          model = "${providerName}/${m.model}";
          overlay = pkgs.writeText "omp-${providerName}-${name}.yml" (
            builtins.toJSON {
              modelRoles = {
                default = model;
                smol = model;
                slow = model;
                plan = model;
                task = model;
                commit = model;
                title = model;
              };
              advisor.enabled = false;
              disabledProviders = disabledProvidersFor [ model ];
            }
          );
        in
        pkgs.writeShellScriptBin "omp-${providerName}-${name}" ''
          if [ -r "${provider.apiKeyPath}" ]; then
            export ${provider.apiKeyEnv}="$(cat "${provider.apiKeyPath}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.omp} --config "${overlay}" --model "${model}" "$@"
        '';

      mkOmpWrappers =
        providerName: provider: lib.mapAttrsToList (mkOmpWrapper providerName provider) provider.models;

      ompWrappers = lib.concatLists (lib.mapAttrsToList mkOmpWrappers providers);

      # ~/.omp/agent/models.yml — JSON is valid YAML.
      modelsYml = builtins.toJSON {
        providers = lib.mapAttrs (_name: p: {
          baseUrl = p.baseUrl;
          api = p.api;
          apiKey = apiKeyCommand p.apiKeyPath;
          authHeader = true;
          models = lib.mapAttrsToList (
            _n: m:
            {
              id = m.model;
              name = m.name or m.model;
              contextWindow = m.contextWindow;
            }
            // (m.extra or { })
          ) p.models;
        }) providers;
      };

      # ~/.omp/agent/WATCHDOG.md — advisor-only review guidance.
      watchdogMd = ''
        # Watchdog

        Review priorities for the advisor:

        - Unhandled error paths — catches that swallow exceptions silently.
        - Missing input validation on public/API boundaries.
        - Changes that bypass existing abstractions or introduce parallel implementations.
        - Resource leaks — unclosed files, connections, or missing cleanup in error paths.
        - Race conditions in concurrent/async code.
        - Security: user input reaching eval/exec/sql without sanitization.
        - Dead code introduced by the change (orphaned imports, unreachable branches).
      '';

      # --- Two complete multi-agent compositions ---
      # Each preset sets the full model role stack for one provider family,
      # plus advisor config (enabled with bounded catch-up). Uses --config
      # overlay (omp docs/settings.md §"One-shot overlays") so it layers on
      # top of whatever the user's ~/.omp/agent/config.yml contains without
      # clobbering setup state.
      #
      # Two levels of control:
      #   omp-volces / omp-volces-deepseek / omp-deepseek   — multi-agent compositions
      #   omp-volces-glm_5_2 etc.     — single-model, no subagents
      compositions = {
        volces = {
          # All roles on volces
          default = "volces/glm-5.2";
          smol = "volces/deepseek-v4-flash";
          slow = "volces/glm-5.2";
          plan = "volces/glm-5.2";
          advisor = "volces/glm-5.2";
          task = "volces/deepseek-v4-flash";
          commit = "volces/deepseek-v4-flash";
          title = "volces/deepseek-v4-flash";
        };
        volces-deepseek = {
          # All deepseek models on volces
          default = "volces/deepseek-v4-pro";
          smol = "volces/deepseek-v4-flash";
          slow = "volces/deepseek-v4-pro";
          plan = "volces/deepseek-v4-pro";
          advisor = "volces/deepseek-v4-pro";
          task = "volces/deepseek-v4-flash";
          commit = "volces/deepseek-v4-flash";
          title = "volces/deepseek-v4-flash";
        };
        deepseek = {
          # All roles on deepseek API
          default = "deepseek/deepseek-v4-pro";
          smol = "deepseek/deepseek-v4-flash";
          slow = "deepseek/deepseek-v4-pro";
          plan = "deepseek/deepseek-v4-pro";
          advisor = "deepseek/deepseek-v4-pro";
          task = "deepseek/deepseek-v4-flash";
          commit = "deepseek/deepseek-v4-flash";
          title = "deepseek/deepseek-v4-flash";
        };
      };

      mkCompositionWrapper =
        name: roles:
        let
          overlay = pkgs.writeText "omp-${name}-overlay.yml" (
            builtins.toJSON {
              modelRoles = roles;
              advisor = {
                enabled = true;
                syncBacklog = "3";
                immuneTurns = 3;
              };
              disabledProviders = disabledProvidersFor (builtins.attrValues roles);
            }
          );
        in
        pkgs.writeShellScriptBin "omp-${name}" ''
          if [ -r "${volcengine-codingplan-api-key.path}" ]; then
            export VOLCENGINE_API_KEY="$(cat "${volcengine-codingplan-api-key.path}")"
          fi
          if [ -r "${deepseek-api-key.path}" ]; then
            export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.omp} --config "${overlay}" --model "${roles.default}" "$@"
        '';

      compositionWrappers = lib.mapAttrsToList mkCompositionWrapper compositions;

      # ~/.omp/agent/config.yml — global omp config (declarative).
      # setupVersion: 1 marks setup as complete so omp skips the wizard.
      configYml = builtins.toJSON {
        setupVersion = 1;
        startup = {
          checkUpdate = false; # Nix manages omp version
          setupWizard = false; # skip onboarding
          quiet = true; # skip welcome screen
        };
        marketplace.autoUpdate = "off"; # disable plugin update checks
        model.loopGuard.enabled = true; # loop detection for DeepSeek
        retry.maxRetries = 5; # fail faster on API errors
        task = {
          enableLsp = true; # allow subagents to use LSP
          maxConcurrency = 8; # avoid rate limits on third-party APIs (was 32)
        };
        display.showTokenUsage = true; # per-turn token usage
        symbolPreset = "ascii"; # no Nerd Font dependency
        statusLine.preset = "default"; # match symbol preset
        images.blockImages = true; # GLM/DeepSeek are text-only coding models
        secrets.enabled = true; # obfuscate secrets before sending to API gateways
      };

    in
    {
      home.packages = [ pkgs.llm-agents.omp ] ++ ompWrappers ++ compositionWrappers;

      home.file."./.omp/agent/models.yml".force = true;
      home.file."./.omp/agent/models.yml".text = modelsYml;
      home.file."./.omp/agent/WATCHDOG.md".force = true;
      home.file."./.omp/agent/WATCHDOG.md".text = watchdogMd;
      home.file."./.omp/agent/config.yml".force = true;
      home.file."./.omp/agent/config.yml".text = configYml;

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
