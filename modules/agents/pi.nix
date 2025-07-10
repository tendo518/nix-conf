{
  flake.modules.home."agents/pi" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # --- Credentials & Secrets ---
      inherit (config.age.secrets)
        volcengine-codingplan-api-key
        ;

      # pi resolves `!command` apiKey values at request time (sh -c, stdout is
      # trimmed), so the bare `pi` binary reads the agenix secret itself - same
      # approach as modules/agents/omp.nix.
      apiKeyCommand = path: "!${pkgs.coreutils}/bin/cat ${path}";

      providers = {
        # Volcengine Ark Coding Plan - Anthropic Messages endpoint (same base that
        # Claude Code uses in modules/agents/claude-code.nix; pi's Anthropic SDK
        # appends `/v1/messages`). Model names mirror omp.nix, including the
        # `[1m]` 1M-context suffix on glm/deepseek. Thinking is set only for the
        # deepseek models (low/high/max per DeepSeek's catalog); kimi/glm/minimax
        # omit it.
        volces = {
          name = "Volcengine Coding Plan";
          baseUrl = "https://ark.cn-beijing.volces.com/api/coding";
          api = "anthropic-messages";
          apiKey = apiKeyCommand volcengine-codingplan-api-key.path;
          models = [
            {
              id = "kimi-k2.6";
              name = "Kimi K2.6";
              contextWindow = 1048576;
            }
            {
              id = "kimi-k2.7-code";
              name = "Kimi K2.7 Code";
              contextWindow = 1048576;
            }
            {
              id = "glm-5.3";
              name = "GLM 5.3";
              contextWindow = 1048576;
            }
            {
              id = "minimax-m3";
              name = "MiniMax M3";
              contextWindow = 1000000;
            }
            {
              id = "deepseek-v4-pro";
              name = "DeepSeek V4 Pro";
              contextWindow = 1000000;
              reasoning = true;
              thinkingLevelMap = {
                minimal = null;
                low = "low";
                medium = null;
                high = "high";
                xhigh = null;
                max = "max";
              };
            }
            {
              id = "deepseek-v4-flash";
              name = "DeepSeek V4 Flash";
              contextWindow = 1000000;
              reasoning = true;
              thinkingLevelMap = {
                minimal = null;
                low = "low";
                medium = null;
                high = "high";
                xhigh = null;
                max = "max";
              };
            }
          ];
        };

        # Local self-hosted GPU - OpenAI-compatible chat/completions endpoint
        # (pi's OpenAI SDK appends `/chat/completions`). Router key is a plaintext
        # literal (no encryption requested). Deployment supports 240k context and
        # low/medium/high thinking effort.
        gpu = {
          name = "GPU";
          baseUrl = "http://172.18.36.44:8000/v1";
          api = "openai-completions";
          apiKey = "8b964310965445819bfd028144ba7cb34676c7f33c97c73966050fb59e903bd5";
          models = [
            {
              id = "qwen3.8-27b";
              name = "Qwen3.8 27B";
              contextWindow = 240000;
              reasoning = true;
              thinkingLevelMap = {
                minimal = null;
                low = "low";
                medium = "medium";
                high = "high";
                xhigh = null;
                max = null;
              };
            }
          ];
        };
      };

      # ~/.pi/agent/models.json - declares every provider and model. The volce
      # key is read by pi itself via the `!command` form; the gpu key is inline.
      modelsJson = builtins.toJSON {
        providers = lib.mapAttrs (_: p: {
          inherit (p)
            name
            baseUrl
            api
            apiKey
            ;
          inherit (p) models;
        }) providers;
      };

      # ~/.pi/agent/settings.json - startup model and quiet boot. Switch models
      # at runtime with /model or Ctrl+P - every model in models.json is
      # available.
      settingsJson = builtins.toJSON {
        defaultProvider = "volces";
        defaultModel = "glm-5.3";
        quietStartup = true;
      };
    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      home.file."./.pi/agent/models.json".force = true;
      home.file."./.pi/agent/models.json".text = modelsJson;
      home.file."./.pi/agent/settings.json".force = true;
      home.file."./.pi/agent/settings.json".text = settingsJson;

      age.secrets = {
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
