{
  flake.modules.home."agents/claude-code" =
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

      providers = {
        aliyun = {
          baseUrl = "https://coding.dashscope.aliyuncs.com/apps/anthropic";
          apiKeyPath = aliyun-codingplan-api-key.path;
          smallModel = "qwen3-5-plus";
          models = {
            qwen3-max.model = "qwen3-max-2026-01-23";
            qwen3-6-plus.model = "qwen3.6-plus";
            qwen3-5-plus.model = "qwen3.5-plus";
            qwen3-coder-next.model = "qwen3-coder-next";
            qwen3-coder-plus.model = "qwen3-coder-plus";
            kimi-k2-5.model = "kimi-k2.5";
            glm-5.model = "glm-5";
            glm-4-7.model = "glm-4.7";
            minimax-m2-5.model = "MiniMax-M2.5";
          };
        };
        volces = {
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          apiKeyPath = volcengine-codingplan-api-key.path;
          smallModel = "ds-v4flash";
          models = {
            kimi-k2-6.model = "kimi-k2.6";
            glm-5-1.model = "glm-5.1";
            minimax-m3.model = "minimax-m3";
            ds-v4pro.model = "deepseek-v4-pro";
            ds-v4flash.model = "deepseek-v4-flash";
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

    in
    {
      home.packages =
        with pkgs.llm-agents;
        [
          claude-code
          cc-switch-cli
          ccusage
        ]
        ++ claudecodeWrappers;

      home.activation.setupClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.claude"
        cp ${
          pkgs.writeText "claude-settings.json" (
            builtins.toJSON {
              statusLine = {
                type = "command";
                command = "${lib.getExe pkgs.llm-agents.ccstatusline}";
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
