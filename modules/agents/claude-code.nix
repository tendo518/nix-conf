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
          enable = false;
          baseUrl = "https://coding.dashscope.aliyuncs.com/apps/anthropic";
          apiKeyPath = aliyun-codingplan-api-key.path;
          smallModel = "qwen3_5_plus";
          models = {
            qwen3_max.model = "qwen3-max-2026-01-23";
            qwen3_6_plus.model = "qwen3.6-plus";
            kimi_k2_5.model = "kimi-k2.5";
            glm_5.model = "glm-5";
          };
        };
        volces = {
          enable = true;
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          apiKeyPath = volcengine-codingplan-api-key.path;
          smallModel = "ds_v4flash";
          models = {
            kimi_k2_6.model = "kimi-k2.6";
            kimi_k2_7_code.model = "kimi-k2.7-code";
            glm_5_2.model = "glm-5.2[1m]";
            minimax_m3.model = "minimax-m3";
            ds_v4pro.model = "deepseek-v4-pro[1m]";
            ds_v4flash.model = "deepseek-v4-flash[1m]";
          };
        };
        deepseek = {
          enable = true;
          baseUrl = "https://api.deepseek.com/anthropic";
          apiKeyPath = deepseek-api-key.path;
          smallModel = "v4_flash";
          models = {
            v4_flash = {
              model = "deepseek-v4-flash[1m]";
              effortLevel = "max";
            };
            v4_pro = {
              model = "deepseek-v4-pro[1m]";
              effortLevel = "max";
            };
          };
        };
      };

      # --- Claude Code Helpers ---
      mkClaudecodeWrapper =
        baseUrl: model: smallModel: apiKeyPath: name: effortLevel:
        pkgs.writeShellScriptBin name ''
          export ANTHROPIC_BASE_URL="${baseUrl}"
          export ANTHROPIC_MODEL="${model}"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="${model}"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="${model}"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="${smallModel}"
          export CLAUDE_CODE_SUBAGENT_MODEL="${smallModel}"
          ${lib.optionalString (effortLevel != "") "export CLAUDE_CODE_EFFORT_LEVEL=\"${effortLevel}\""}
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
            (m.effortLevel or "")
        ) provider.models;

      claudecodeWrappers = lib.concatLists (
        lib.mapAttrsToList mkClaudecodeWrappers (lib.filterAttrs (_: p: p.enable) providers)
      );

    in
    {
      home.packages =
        with pkgs.llm-agents;
        [
          claude-code
          # cc-switch-cli
          # ccusage
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
