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
        name: baseUrl: model: apiKeyPath:
        pkgs.writeShellScriptBin name ''
          export ANTHROPIC_BASE_URL="${baseUrl}"
          export ANTHROPIC_MODEL="${model}"
          export ANTHROPIC_SMALL_FAST_MODEL="${model}"
          export API_TIMEOUT_MS="600000"
          export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
          if [ -r "${apiKeyPath}" ]; then
            export ANTHROPIC_AUTH_TOKEN="$(cat "${apiKeyPath}")"
          fi
          exec ${lib.getExe pkgs.llm-agents.claude-code} "$@"
        '';

      aliyunBaseUrl = "https://coding.dashscope.aliyuncs.com/apps/anthropic";
      volcengineBaseUrl = "https://ark.cn-beijing.volces.com/api/coding";

      mkAliyunWrapper =
        name: model: mkClaudecodeWrapper name aliyunBaseUrl model aliyun-codingplan-api-key.path;
      mkVolcengineWrapper =
        name: model: mkClaudecodeWrapper name volcengineBaseUrl model volcengine-codingplan-api-key.path;
    in
    {
      home.packages = with pkgs.llm-agents; [
        codex
        gemini-cli
        opencode
        claude-code
        kilocode-cli
        hermes-agent

        cc-switch-cli
        ccstatusline
        ccusage

        # Aliyun wrappers
        (mkAliyunWrapper "claude-qwenmax" "qwen3-max-2026-01-23")
        (mkAliyunWrapper "claude-qwen" "qwen3.6-plus")
        (mkAliyunWrapper "claude-qwen35" "qwen3.5-plus")
        (mkAliyunWrapper "claude-kimi" "kimi-k2.5")
        (mkAliyunWrapper "claude-glm" "glm-5")
        (mkAliyunWrapper "claude-minimax" "MiniMax-M2.5")

        # Volcengine wrappers
        (mkVolcengineWrapper "claude-volcengine-kimi" "kimi-k2.6")
        (mkVolcengineWrapper "claude-volcengine-glm" "glm-5.1")
        (mkVolcengineWrapper "claude-volcengine-minimax" "minimax-m2.7")

        # Deepseek wrappers
        (mkClaudecodeWrapper "claude-ds-flash" "https://api.deepseek.com/anthropic" "deepseek-v4-flash"
          deepseek-api-key.path
        )
        (mkClaudecodeWrapper "claude-ds-pro" "https://api.deepseek.com/anthropic" "deepseek-v4-pro"
          deepseek-api-key.path
        )
      ];

      xdg.configFile."ccstatusline/settings.json" = {
        text = builtins.toJSON {
          format = "compact";
          showModel = true;
          showCost = true;
          showTime = true;
        };
      };

      xdg.configFile."opencode/opencode.json.template" = {
        text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          provider."bailian-coding-plan" = {
            npm = "@ai-sdk/anthropic";
            name = "Model Studio Coding Plan";
            options.baseURL = "https://coding.dashscope.aliyuncs.com/apps/anthropic/v1";
            models = {
              "qwen3.5-plus" = {
                name = "Qwen3.5 Plus";
                modalities.input = [
                  "text"
                  "image"
                ];
                modalities.output = [ "text" ];
                options.thinking = {
                  type = "enabled";
                  budgetTokens = 8192;
                };
              };
              "qwen3-max-2026-01-23".name = "Qwen3 Max 2026-01-23";
              "qwen3-coder-next".name = "Qwen3 Coder Next";
              "qwen3-coder-plus".name = "Qwen3 Coder Plus";
              "MiniMax-M2.5".options.thinking = {
                type = "enabled";
                budgetTokens = 8192;
              };
              "glm-5".options.thinking = {
                type = "enabled";
                budgetTokens = 8192;
              };
              "glm-4.7".options.thinking = {
                type = "enabled";
                budgetTokens = 8192;
              };
              "kimi-k2.5" = {
                name = "Kimi K2.5";
                modalities.input = [
                  "text"
                  "image"
                ];
                modalities.output = [ "text" ];
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
        if [ -r "${aliyun-codingplan-api-key.path}" ]; then
          mkdir -p "${config.xdg.configHome}/opencode"
          ${pkgs.jq}/bin/jq \
            --arg key "$(cat "${aliyun-codingplan-api-key.path}")" \
            '.provider."bailian-coding-plan".options.apiKey = $key' \
            "${config.xdg.configHome}/opencode/opencode.json.template" > "${config.xdg.configHome}/opencode/opencode.json"
        fi
      '';

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
        aliyun-codingplan-api-key.file = ../../secrets/aliyun-codingplan-api-key.age;
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
