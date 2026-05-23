{
  flake.modules.homeManager."development/agents" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets)
        deepseek-api-key
        aliyun-codingplan-api-key
        volcengine-codingplan-api-key
        ;

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

      providers = {
        aliyun = {
          baseUrl = "https://coding.dashscope.aliyuncs.com/apps/anthropic";
          apiKeyPath = aliyun-codingplan-api-key.path;
          smallModel = "qwen3.5-plus";
          models = [
            {
              name = "qwen3-max";
              model = "qwen3-max-2026-01-23";
            }
            {
              name = "qwen3-6-plus";
              model = "qwen3.6-plus";
            }
            {
              name = "qwen3-5-plus";
              model = "qwen3.5-plus";
              modalities = {
                input = [
                  "text"
                  "image"
                ];
                output = [ "text" ];
              };
              thinking = {
                budgetTokens = 8192;
              };
            }
            {
              name = "qwen3-coder-next";
              model = "qwen3-coder-next";
            }
            {
              name = "qwen3-coder-plus";
              model = "qwen3-coder-plus";
            }
            {
              name = "kimi-k2-5";
              model = "kimi-k2.5";
              modalities = {
                input = [
                  "text"
                  "image"
                ];
                output = [ "text" ];
              };
              thinking = {
                budgetTokens = 8192;
              };
            }
            {
              name = "glm-5";
              model = "glm-5";
              thinking = {
                budgetTokens = 8192;
              };
            }
            {
              name = "glm-4-7";
              model = "glm-4.7";
              thinking = {
                budgetTokens = 8192;
              };
            }
            {
              name = "minimax-m2-5";
              model = "MiniMax-M2.5";
              thinking = {
                budgetTokens = 8192;
              };
            }
          ];
        };
        volcengine = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          apiKeyPath = volcengine-codingplan-api-key.path;
          smallModel = "kimi-k2.6";
          models = [
            {
              name = "kimi-k2-6";
              model = "kimi-k2.6";
            }
            {
              name = "glm-5-1";
              model = "glm-5.1";
            }
            {
              name = "minimax-m2-7";
              model = "minimax-m2.7";
            }
          ];
        };
        deepseek = {
          baseUrl = "https://api.deepseek.com/anthropic";
          apiKeyPath = deepseek-api-key.path;
          smallModel = "deepseek-v4-flash[1m]";
          models = [
            {
              name = "v4-flash";
              model = "deepseek-v4-flash[1m]";
            }
            {
              name = "v4-pro";
              model = "deepseek-v4-pro[1m]";
            }
          ];
        };
      };

      mkClaudecodeWrappers =
        providerName: provider:
        map (
          m:
          mkClaudecodeWrapper provider.baseUrl m.model provider.smallModel provider.apiKeyPath
            "cc-${providerName}-${m.name}"
        ) provider.models;

      mkOpencodeModels =
        provider:
        lib.listToAttrs (
          map (
            m:
            lib.nameValuePair m.model (
              {
                name = m.name;
              }
              // lib.optionalAttrs (m ? modalities) { modalities = m.modalities; }
              // lib.optionalAttrs (m ? thinking) {
                options.thinking = {
                  type = "enabled";
                  budgetTokens = m.thinking.budgetTokens;
                };
              }
            )
          ) provider.models
        );

      mkOpenCodeProviders = lib.mapAttrs (name: p: {
        npm = "@ai-sdk/anthropic";
        name = p.opencode.name or (builtins.replaceStrings [ "-" ] [ " " ] name);
        options.baseURL = "${p.baseUrl}/v1";
        models = mkOpencodeModels p;
      }) providers;

      mkOpenCodeInjectKeys = lib.concatMapStrings (
        name:
        let
          p = providers.${name};
        in
        ''
          if [ -r "${p.apiKeyPath}" ]; then
            ${pkgs.jq}/bin/jq \
              --arg key "$(cat "${p.apiKeyPath}")" \
              '.provider."${name}".options.apiKey = $key' \
              "${config.xdg.configHome}/opencode/opencode.json" > "${config.xdg.configHome}/opencode/opencode.json.tmp"
            mv "${config.xdg.configHome}/opencode/opencode.json.tmp" "${config.xdg.configHome}/opencode/opencode.json"
          fi
        ''
      ) (builtins.attrNames providers);

      claudecodeWrappers = lib.concatLists (lib.mapAttrsToList mkClaudecodeWrappers providers);

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
          opencode
          claude-code
          antigravity  # new antigravity cli
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

      xdg.configFile."opencode/opencode.json.template" = {
        text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          provider = mkOpenCodeProviders;
        };
      };

      home.activation.setupOpenCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.xdg.configHome}/opencode"
        cp -f "${config.xdg.configHome}/opencode/opencode.json.template" "${config.xdg.configHome}/opencode/opencode.json"
        ${mkOpenCodeInjectKeys}
      '';

      home.file.".hermes/config.yaml".source = pkgs.writeText "hermes-config.yaml" ''
        model:
          provider: "anthropic"
          base_url: "${providers.aliyun.baseUrl}"
          default: "${hermesDefaultModel}"

        auxiliary:
        ${mkHermesAuxYaml providers.aliyun.smallModel hermesAuxServices}
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
