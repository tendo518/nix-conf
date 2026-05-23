{
  flake.modules.homeManager."development/agents" =
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
        aliyun-codingplan-api-key
        volcengine-codingplan-api-key
        ;

      # --- Shared Providers Metadata ---
      # Common capabilities configuration
      thinkingOnly = {
        thinking = { budgetTokens = 8192; };
      };

      multimodalThinking = {
        modalities = {
          input = [ "text" "image" ];
          output = [ "text" ];
        };
        thinking = { budgetTokens = 8192; };
      };

      providers = {
        aliyun = {
          baseUrl = "https://coding.dashscope.aliyuncs.com/apps/anthropic";
          apiKeyPath = aliyun-codingplan-api-key.path;
          smallModel = "qwen3-5-plus";
          models = {
            qwen3-max.model = "qwen3-max-2026-01-23";
            qwen3-6-plus.model = "qwen3.6-plus";
            qwen3-5-plus = { model = "qwen3.5-plus"; } // multimodalThinking;
            qwen3-coder-next.model = "qwen3-coder-next";
            qwen3-coder-plus.model = "qwen3-coder-plus";
            kimi-k2-5 = { model = "kimi-k2.5"; } // multimodalThinking;
            glm-5 = { model = "glm-5"; } // thinkingOnly;
            glm-4-7 = { model = "glm-4.7"; } // thinkingOnly;
            minimax-m2-5 = { model = "MiniMax-M2.5"; } // thinkingOnly;
          };
        };
        volcengine = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          apiKeyPath = volcengine-codingplan-api-key.path;
          smallModel = "minimax-m2-7";
          models = {
            kimi-k2-6.model = "kimi-k2.6";
            glm-5-1.model = "glm-5.1";
            minimax-m2-7.model = "minimax-m2.7";
          };
        };
        deepseek = {
          baseUrl = "https://api.deepseek.com/anthropic";
          apiKeyPath = deepseek-api-key.path;
          smallModel = "v4-flash";
          models = {
            v4-flash.model = "deepseek-v4-flash[1m]";
            v4-pro.model = "deepseek-v4-pro[1m]";
          };
        };
      };

      # --- Claude Code Helpers ---
      mkClaudecodeWrapper =
        baseUrl: model: smallModel: apiKeyPath: name:
        pkgs.writeShellScriptBin name ''
          export ANTHROPIC_BASE_URL="${baseUrl}"
          export ANTHROPIC_MODEL="${model}"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="${model}"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="${model}"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="${smallModel}"
          export CLAUDE_CODE_SUBAGENT_MODEL="${smallModel}"
          export CLAUDE_CODE_EFFORT_LEVEL="max"
          export API_TIMEOUT_MS="600000"
          export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
          if [ -r "${apiKeyPath}" ]; then
            export ANTHROPIC_AUTH_TOKEN="$(cat "${apiKeyPath}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.claude-code} "$@"
        '';

      mkClaudecodeWrappers =
        providerName: provider:
        let
          smallModelId = provider.models.${provider.smallModel}.model;
        in
        lib.mapAttrsToList (
          name: m:
          mkClaudecodeWrapper provider.baseUrl m.model smallModelId provider.apiKeyPath
            "cc-${providerName}-${name}"
        ) provider.models;

      claudecodeWrappers = lib.concatLists (lib.mapAttrsToList mkClaudecodeWrappers providers);

      # --- Pi Helpers ---
      mkPiModels =
        provider:
        lib.mapAttrsToList (
          name: m:
          {
            id = m.model;
            name = name;
          }
        ) provider.models;

      mkPiProviders = lib.mapAttrs (name: p: {
        baseUrl = p.baseUrl;
        api = "anthropic-messages";
        apiKey = "$ALIYUN_API_KEY";
        models = mkPiModels p;
      }) {
        inherit (providers) aliyun;
      };

      mkPiInjectKeys = lib.concatMapStrings (
        name:
        let
          p = providers.${name};
        in
        ''
          if [ -r "${p.apiKeyPath}" ]; then
            ${pkgs.jq}/bin/jq \
              --arg key "$(cat "${p.apiKeyPath}")" \
              '.${name} = { type: "api_key", key: $key }' \
              "$HOME/.pi/agent/auth.json" > "$HOME/.pi/agent/auth.json.tmp"
            mv "$HOME/.pi/agent/auth.json.tmp" "$HOME/.pi/agent/auth.json"
          fi
        ''
      ) [ "aliyun" "deepseek" ];

      mkDeepseekModel = { id, name, cost }: {
        inherit id name cost;
        contextWindow = 1000000;
        maxTokens = 384000;
        input = [ "text" ];
        reasoning = true;
        compat = {
          requiresReasoningContentOnAssistantMessages = true;
          thinkingFormat = "deepseek";
          reasoningEffortMap = {
            minimal = "high";
            low = "high";
            medium = "high";
            high = "high";
            xhigh = "max";
          };
        };
      };

      # --- Hermes Helpers ---
      mkHermesAuxYaml =
        model: services:
        lib.concatStrings (
          map (s: ''
            ${s}:
              provider: "anthropic"
              model: "${model}"
          '') services
        );

      hermesDefaultModel = "glm-5";
      hermesAuxServices = [
        "compression"
        "title_generation"
        "session_search"
        "skills_hub"
        "web_extract"
        "mcp"
      ];
    in
    {
      home.packages =
        with pkgs.llm-agents;
        [
          codex
          # gemini-cli  # orphan pkg
          claude-code
          antigravity  # new antigravity cli
          pi
          kilocode-cli
          hermes-agent

          cc-switch-cli
          ccstatusline
          ccusage
          qoder-cli
        ]
        ++ claudecodeWrappers;

      xdg.configFile."ccstatusline/settings.json" = {
        text = builtins.toJSON {
          version = 3;
          lines = [
            [
              {
                id = "model";
                type = "model";
                color = "cyan";
              }
              {
                id = "sep1";
                type = "separator";
              }
              {
                id = "ctx";
                type = "context-length";
                color = "brightBlack";
              }
              {
                id = "sep2";
                type = "separator";
              }
              {
                id = "branch";
                type = "git-branch";
                color = "magenta";
              }
              {
                id = "sep3";
                type = "separator";
              }
              {
                id = "changes";
                type = "git-changes";
                color = "yellow";
              }
              {
                id = "sep4";
                type = "separator";
              }
              {
                id = "think";
                type = "thinking-effort";
                color = "yellow";
              }
              {
                id = "flex";
                type = "flex-separator";
              }
              {
                id = "cached";
                type = "tokens-cached";
              }
              {
                id = "sep5";
                type = "separator";
              }
              {
                id = "total";
                type = "tokens-total";
              }
              {
                id = "sep6";
                type = "separator";
              }
              {
                id = "speed";
                type = "output-speed";
              }
            ]
            [ ]
            [ ]
          ];
          flexMode = "full";
          compactThreshold = 60;
          colorLevel = 3;
          inheritSeparatorColors = true;
          globalBold = true;
          defaultPadding = "";
        };
      };

      home.file.".pi/agent/models.json".text = builtins.toJSON {
        providers = mkPiProviders // {
          deepseek = {
            baseUrl = "https://api.deepseek.com";
            api = "openai-completions";
            apiKey = "$DEEPSEEK_API_KEY";
            models = [
              (mkDeepseekModel {
                id = "deepseek-v4-pro";
                name = "DeepSeek V4 Pro";
                cost = {
                  input = 1.74;
                  output = 3.48;
                  cacheRead = 0.145;
                  cacheWrite = 0;
                };
              })
              (mkDeepseekModel {
                id = "deepseek-v4-flash";
                name = "DeepSeek V4 Flash";
                cost = {
                  input = 0.14;
                  output = 0.28;
                  cacheRead = 0.028;
                  cacheWrite = 0;
                };
              })
            ];
          };
        };
      };

      home.activation.setupPiConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.pi/agent"
        if [ ! -f "$HOME/.pi/agent/auth.json" ]; then
          echo "{}" > "$HOME/.pi/agent/auth.json"
        fi
        chmod 600 "$HOME/.pi/agent/auth.json"
        ${mkPiInjectKeys}
      '';

      home.file.".hermes/config.yaml".source = pkgs.writeText "hermes-config.yaml" ''
        model:
          provider: "anthropic"
          base_url: "${providers.aliyun.baseUrl}"
          default: "${hermesDefaultModel}"

        auxiliary:
        ${mkHermesAuxYaml providers.aliyun.models.${providers.aliyun.smallModel}.model hermesAuxServices}
          curator:
            provider: "anthropic"
            model: "${hermesDefaultModel}"
      '';

      home.activation.setupHermesEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -r "${providers.aliyun.apiKeyPath}" ]; then
          mkdir -p "$HOME/.hermes"
          echo "ANTHROPIC_API_KEY=$(cat "${providers.aliyun.apiKeyPath}")" > "$HOME/.hermes/.env"
          echo "ANTHROPIC_BASE_URL=${providers.aliyun.baseUrl}" >> "$HOME/.hermes/.env"
          chmod 600 "$HOME/.hermes/.env"
        fi
      '';

      home.activation.setupClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.claude"
        cp ${
          pkgs.writeText "claude-settings.json" (
            builtins.toJSON {
              statusLine = {
                type = "command";
                command = "bunx -y ccstatusline@latest";
                padding = 0;
              };
              enabledPlugins."pyright-lsp@claude-plugins-official" = true;
              skipWebFetchPreflight = true;
              theme = "auto";
            }
          )
        } "$HOME/.claude/settings.json"
        chmod u+w "$HOME/.claude/settings.json"
      '';

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
        aliyun-codingplan-api-key.file = ../../secrets/aliyun-codingplan-api-key.age;
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
