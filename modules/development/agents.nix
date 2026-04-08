{
  flake.modules.homeManager."development/agents" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      deepseekApikeyPath = config.age.secrets.deepseek-api-key.path;
      aliyunApiKeyPath = config.age.secrets.aliyun-codingplan-api-key.path;

      # Create a generic wrapper script for claude-code that sets Anthropic env vars.
      # This keeps the original command intact for use with other API providers.
      mkClaudecodeWrapper =
        name: pkg: binName: baseUrl: modelName: apiKeyPath:
        pkgs.writeShellScriptBin name ''
          export ANTHROPIC_BASE_URL="${baseUrl}"
          export ANTHROPIC_MODEL="${modelName}"
          export ANTHROPIC_SMALL_FAST_MODEL="${modelName}"
          export API_TIMEOUT_MS="600000"
          export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
          if [ -r "${apiKeyPath}" ]; then
            export ANTHROPIC_AUTH_TOKEN="$(cat "${apiKeyPath}")"
          fi
          exec ${lib.getExe' pkg binName} "$@"
        '';
    in
    {
      home.packages = with pkgs; [
        gemini-cli
        claude-code-router
        opencode
        bun # opencode makes use of bun
        claude-code

        # Default claude wrapper using qwen
        (mkClaudecodeWrapper "claude-qwenmax" claude-code "claude"
          "https://coding.dashscope.aliyuncs.com/apps/anthropic"
          "qwen3-max-2026-01-23"
          aliyunApiKeyPath
        )
         (mkClaudecodeWrapper "claude-qwen" claude-code "claude"
          "https://coding.dashscope.aliyuncs.com/apps/anthropic"
          "qwen3.6-plus"
          aliyunApiKeyPath
        )
        (mkClaudecodeWrapper "claude-qwen35" claude-code "claude"
          "https://coding.dashscope.aliyuncs.com/apps/anthropic"
          "qwen3.5-plus"
          aliyunApiKeyPath
        )
        # Alternative model wrappers
        (mkClaudecodeWrapper "claude-ds" claude-code "claude"
          "https://api.deepseek.com/anthropic"
          "deepseek-reasoner"
          deepseekApikeyPath
        )
        (mkClaudecodeWrapper "claude-kimi" claude-code "claude"
          "https://coding.dashscope.aliyuncs.com/apps/anthropic"
          "kimi-k2.5"
          aliyunApiKeyPath
        )
        (mkClaudecodeWrapper "claude-glm" claude-code "claude"
          "https://coding.dashscope.aliyuncs.com/apps/anthropic"
          "glm-5"
          aliyunApiKeyPath
        )
        (mkClaudecodeWrapper "claude-minimax" claude-code "claude"
          "https://coding.dashscope.aliyuncs.com/apps/anthropic"
          "MiniMax-M2.5"
          aliyunApiKeyPath
        )
      ];

      # programs.claude-code is provided via wrappers above
      # programs.claude-code.enable = true;

      programs.opencode = {
        enable = true;
      };

      programs.codex = {
        enable = true;
      };

      programs.gemini-cli = {
        enable = true;
      };

      xdg.configFile."opencode/opencode.json.template" = {
        text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          provider."bailian-coding-plan" = {
            npm = "@ai-sdk/anthropic";
            name = "Model Studio Coding Plan";
            options = {
              baseURL = "https://coding.dashscope.aliyuncs.com/apps/anthropic/v1";
            };
            models = {
              "qwen3.5-plus" = {
                name = "Qwen3.5 Plus";
                modalities = {
                  input = [
                    "text"
                    "image"
                  ];
                  output = [ "text" ];
                };
                options.thinking = {
                  type = "enabled";
                  budgetTokens = 8192;
                };
              };
              "qwen3-max-2026-01-23".name = "Qwen3 Max 2026-01-23";
              "qwen3-coder-next".name = "Qwen3 Coder Next";
              "qwen3-coder-plus".name = "Qwen3 Coder Plus";
              "MiniMax-M2.5" = {
                name = "MiniMax M2.5";
                options.thinking = {
                  type = "enabled";
                  budgetTokens = 8192;
                };
              };
              "glm-5" = {
                name = "GLM-5";
                options.thinking = {
                  type = "enabled";
                  budgetTokens = 8192;
                };
              };
              "glm-4.7" = {
                name = "GLM-4.7";
                options.thinking = {
                  type = "enabled";
                  budgetTokens = 8192;
                };
              };
              "kimi-k2.5" = {
                name = "Kimi K2.5";
                modalities = {
                  input = [
                    "text"
                    "image"
                  ];
                  output = [ "text" ];
                };
                options.thinking = {
                  type = "enabled";
                  budgetTokens = 8192;
                };
              };
            };
          };
        };
      };

      home.activation.setupOpenCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -r "${aliyunApiKeyPath}" ]; then
          mkdir -p "${config.xdg.configHome}/opencode"
          ${pkgs.jq}/bin/jq \
            --arg key "$(cat "${aliyunApiKeyPath}")" \
            '.provider."bailian-coding-plan".options.apiKey = $key' \
            "${config.xdg.configHome}/opencode/opencode.json.template" > "${config.xdg.configHome}/opencode/opencode.json"
        fi
      '';

      # Agenix: decrypt the API key at activation time
      age.secrets.deepseek-api-key = {
        file = ../../secrets/deepseek-api-key.age;
      };
      age.secrets.aliyun-codingplan-api-key = {
        file = ../../secrets/aliyun-codingplan-api-key.age;
      };
    };
}
