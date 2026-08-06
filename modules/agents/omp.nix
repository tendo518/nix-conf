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
        opencode-go-api-key
        volcengine-codingplan-api-key
        deepseek-api-key
        ;

      # OpenCode Go (docs: opencode.ai/docs/zh-cn/go) is the single provider:
      # a low-cost subscription covering every omp model. It serves its
      # models on three wire families, so the provider defaults to the OpenAI
      # chat-completions route and individual models override `api`/`baseUrl`
      # where needed:
      #   chat/completions (deepseek, kimi) -> https://opencode.ai/zen/go/v1
      #   /responses (gpt-5.6-luna)         -> https://opencode.ai/zen/go/v1
      #   /v1/messages (qwen3.8-max)        -> https://opencode.ai/zen/go
      # omp appends `/chat/completions`, `/responses`, or `/v1/messages`
      # respectively (oh-my-pi docs/models.md §"Practical examples").
      #
      # deepseek uses the OpenAI-compatible endpoint. The full compat block is
      # required - without the three critical fields (supportsToolChoice,
      # requiresReasoningContentForToolCalls,
      # requiresAssistantContentForToolCalls) DeepSeek V4 returns 400 errors
      # on tool calls in thinking mode. compat does not merge with built-in
      # entries, so the full set must be specified.
      #
      # contextWindow values are taken from omp's bundled model catalog
      # (packages/catalog/src/models.json) - the native provider entry for
      # each model: moonshot (kimi), deepseek (deepseek-v4), openai
      # (gpt-5.6-luna), qwen (qwen3.8-max).
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
        opencode-go = {
          baseUrl = "https://opencode.ai/zen/go/v1";
          api = "openai-completions";
          apiKeyEnv = "OPENCODE_GO_API_KEY";
          apiKeyPath = opencode-go-api-key.path;
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
            kimi_k3 = {
              model = "kimi-k3";
              name = "Kimi K3";
              contextWindow = 1048576;
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "high"
                    "max"
                  ];
                };
              };
            };
            gpt_5_6_luna = {
              model = "gpt-5.6-luna";
              name = "GPT-5.6 Luna";
              contextWindow = 1050000;
              api = "openai-responses";
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "medium"
                    "high"
                    "xhigh"
                    "max"
                  ];
                };
              };
            };
            qwen3_8_max = {
              model = "qwen3.8-max";
              name = "Qwen3.8 Max";
              contextWindow = 983616;
              api = "anthropic-messages";
              baseUrl = "https://opencode.ai/zen/go";
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "high"
                    "xhigh"
                  ];
                };
              };
            };
          };
        };

        # Volces coding plan - Anthropic Messages endpoint (same base that
        # Claude Code uses in modules/agents/claude-code.nix; omp appends
        # `/v1/messages`). Model names mirror claude-code.nix, including the
        # `[1m]` 1M-context suffix on glm/deepseek. Thinking is set only for the
        # deepseek models (low/high/max per DeepSeek's catalog); kimi/glm/minimax
        # omit it - add efforts there once confirmed.
        volces = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          api = "anthropic-messages";
          apiKeyEnv = "VOLCENGINE_API_KEY";
          apiKeyPath = volcengine-codingplan-api-key.path;
          models = {
            kimi_k2_6 = {
              model = "kimi-k2.6";
              name = "Kimi K2.6";
              contextWindow = 1048576;
            };
            kimi_k2_7_code = {
              model = "kimi-k2.7-code";
              name = "Kimi K2.7 Code";
              contextWindow = 1048576;
            };
            glm_5_2 = {
              model = "glm-5.2[1m]";
              name = "GLM 5.2";
              contextWindow = 1048576;
            };
            minimax_m3 = {
              model = "minimax-m3";
              name = "MiniMax M3";
              contextWindow = 1000000;
            };
            ds_v4pro = {
              model = "deepseek-v4-pro[1m]";
              name = "DeepSeek V4 Pro";
              contextWindow = 1000000;
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "high"
                    "max"
                  ];
                };
              };
            };
            ds_v4flash = {
              model = "deepseek-v4-flash[1m]";
              name = "DeepSeek V4 Flash";
              contextWindow = 1000000;
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "high"
                    "max"
                  ];
                };
              };
            };
          };
        };

        # DeepSeek direct - Anthropic Messages endpoint
        # (api.deepseek.com/anthropic, same as claude-code.nix). `[1m]` selects
        # 1M context. Thinking efforts low/high/max per DeepSeek's catalog.
        deepseek = {
          baseUrl = "https://api.deepseek.com/anthropic";
          api = "anthropic-messages";
          apiKeyEnv = "DEEPSEEK_API_KEY";
          apiKeyPath = deepseek-api-key.path;
          models = {
            ds_v4flash = {
              model = "deepseek-v4-flash[1m]";
              name = "DeepSeek V4 Flash";
              contextWindow = 1000000;
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "high"
                    "max"
                  ];
                };
              };
            };
            ds_v4pro = {
              model = "deepseek-v4-pro[1m]";
              name = "DeepSeek V4 Pro";
              contextWindow = 1000000;
              extra = {
                reasoning = true;
                thinking = {
                  mode = "effort";
                  efforts = [
                    "low"
                    "high"
                    "max"
                  ];
                };
              };
            };
          };
        };
      };

      # ~/.omp/agent/models.yml - JSON is valid YAML. Declares every provider
      # and model; omp reads each API key itself via `apiKeyCommand` (the `!`
      # prefix runs the command), so the bare `omp` binary needs no per-model
      # wrapper. Pick the model at runtime with `--model <fuzzy>` (e.g.
      # "deepseek", "gpt-5.6"), `/model`, or Ctrl+P.
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
            // (lib.optionalAttrs (m ? api) { inherit (m) api; })
            // (lib.optionalAttrs (m ? baseUrl) { inherit (m) baseUrl; })
            // (m.extra or { })
          ) p.models;
        }) providers;
      };

      # ~/.omp/agent/WATCHDOG.md - advisor-only review guidance (used when the
      # advisor is enabled via `--advisor` or `/advisor`).
      watchdogMd = ''
        # Watchdog

        Review priorities for the advisor:

        - Unhandled error paths - catches that swallow exceptions silently.
        - Missing input validation on public/API boundaries.
        - Changes that bypass existing abstractions or introduce parallel implementations.
        - Resource leaks - unclosed files, connections, or missing cleanup in error paths.
        - Race conditions in concurrent/async code.
        - Security: user input reaching eval/exec/sql without sanitization.
        - Dead code introduced by the change (orphaned imports, unreachable branches).
      '';

      # ~/.omp/agent/config.yml - global omp config (declarative).
      # `modelRoles.default` gives `omp` a startup model; the setup wizard is
      # skipped via setupVersion, so without this omp has no default. Switch
      # models at runtime with `--model`, `/model`, or Ctrl+P - every model in
      # models.yml is available. Other roles (smol/slow/plan/...) fall back to
      # omp's defaults; override per-launch with `--smol`, `--slow`, etc.
      configYml = builtins.toJSON {
        setupVersion = 1;
        modelRoles.default = "opencode-go/gpt-5.6-luna";
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
          maxConcurrency = 8; # avoid rate limits on third-party APIs
        };
        display.showTokenUsage = true; # per-turn token usage
        symbolPreset = "ascii"; # no Nerd Font dependency
        statusLine.preset = "default"; # match symbol preset
        images.blockImages = true; # GLM/DeepSeek are text-only coding models
        secrets.enabled = true; # obfuscate secrets before sending to API gateways
      };

    in
    {
      home.packages = [ pkgs.llm-agents.omp ];

      home.file."./.omp/agent/models.yml".force = true;
      home.file."./.omp/agent/models.yml".text = modelsYml;
      home.file."./.omp/agent/WATCHDOG.md".force = true;
      home.file."./.omp/agent/WATCHDOG.md".text = watchdogMd;
      home.file."./.omp/agent/config.yml".force = true;
      home.file."./.omp/agent/config.yml".text = configYml;

      age.secrets = {
        opencode-go-api-key.file = ../../secrets/opencode-go-api-key.age;
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
      };
    };
}
