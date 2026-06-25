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

      # Same Anthropic-compatible endpoints Claude Code uses (ANTHROPIC_BASE_URL).
      # omp's `anthropic-messages` api appends `/v1/messages` to `baseUrl`, matching
      # those gateways exactly. `apiKey` is env-var-name-or-literal per omp's docs,
      # so each wrapper exports the named var from the age secret and omp reads it.
      # `authHeader: true` injects `Authorization: Bearer <key>` — what Claude Code
      # sends via ANTHROPIC_AUTH_TOKEN — so these endpoints accept it.
      #
      # contextWindow values are taken from omp's bundled model catalog
      # (packages/catalog/src/models.json) — the native provider entry for each
      # model: moonshot (kimi), zhipu-coding-plan (glm), minimax (MiniMax),
      # deepseek (deepseek-v4). The [1m] suffix on the deepseek-api models is
      # DeepSeek's 1M-context variant.
      providers = {
        volces = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
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
          baseUrl = "https://api.deepseek.com/anthropic";
          apiKeyEnv = "DEEPSEEK_API_KEY";
          apiKeyPath = deepseek-api-key.path;
          models = {
            v4_flash = {
              model = "deepseek-v4-flash[1m]";
              contextWindow = 1000000;
            };
            v4_pro = {
              model = "deepseek-v4-pro[1m]";
              contextWindow = 1000000;
            };
          };
        };
      };

      # --- Single-model wrappers ---
      # Each wrapper pins ALL model roles to the same model and disables the
      # advisor, so there are no subagents or multi-model interactions —
      # just a clean single-model session. Uses --config overlay so it works
      # regardless of what the user's ~/.omp/agent/config.yml contains.
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
            }
          );
        in
        pkgs.writeShellScriptBin "omp-${providerName}-${name}" ''
          if [ -r "${provider.apiKeyPath}" ]; then
            export ${provider.apiKeyEnv}="$(cat "${provider.apiKeyPath}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.omp} --config "${overlay}" "$@"
        '';

      mkOmpWrappers =
        providerName: provider: lib.mapAttrsToList (mkOmpWrapper providerName provider) provider.models;

      ompWrappers = lib.concatLists (lib.mapAttrsToList mkOmpWrappers providers);

      # ~/.omp/agent/models.yml — JSON is valid YAML.
      modelsYml = builtins.toJSON {
        providers = lib.mapAttrs (_name: p: {
          baseUrl = p.baseUrl;
          api = "anthropic-messages";
          apiKey = p.apiKeyEnv;
          authHeader = true;
          models = lib.mapAttrsToList (_n: m: {
            id = m.model;
            name = m.model;
            contextWindow = m.contextWindow;
          }) p.models;
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
      #   omp-volces / omp-deepseek   — full family-specific composition
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
        volces-ds = {
          # All roles on volces
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
          default = "deepseek/deepseek-v4-pro[1m]";
          smol = "deepseek/deepseek-v4-flash[1m]";
          slow = "deepseek/deepseek-v4-pro[1m]";
          plan = "deepseek/deepseek-v4-pro[1m]";
          advisor = "deepseek/deepseek-v4-pro[1m]";
          task = "deepseek/deepseek-v4-flash[1m]";
          commit = "deepseek/deepseek-v4-flash[1m]";
          title = "deepseek/deepseek-v4-flash[1m]";
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
          exec ${lib.getExe pkgs.llm-agents.omp} --config "${overlay}" "$@"
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
