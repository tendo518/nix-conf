{
  flake.modules.home."agents/workbuddy" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets)
        deepseek-api-key
        opencode-go-api-key
        volcengine-codingplan-api-key
        ;

      models = [
        # Volcengine Coding Plan (OpenAI-compatible chat completions).
        {
          id = "kimi-k2.6";
          name = "Kimi K2.6 (Volcengine)";
          vendor = "Volcengine";
          apiKey = "\${VOLCENGINE_API_KEY}";
          maxInputTokens = 1048576;
          maxOutputTokens = 131072;
          url = "https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }
        {
          id = "kimi-k2.7-code";
          name = "Kimi K2.7 Code (Volcengine)";
          vendor = "Volcengine";
          apiKey = "\${VOLCENGINE_API_KEY}";
          maxInputTokens = 1048576;
          maxOutputTokens = 131072;
          url = "https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }
        {
          id = "glm-5.2";
          name = "GLM 5.2 (Volcengine)";
          vendor = "Volcengine";
          apiKey = "\${VOLCENGINE_API_KEY}";
          maxInputTokens = 1048576;
          maxOutputTokens = 131072;
          url = "https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }
        {
          id = "minimax-m3";
          name = "MiniMax M3 (Volcengine)";
          vendor = "Volcengine";
          apiKey = "\${VOLCENGINE_API_KEY}";
          maxInputTokens = 1000000;
          maxOutputTokens = 131072;
          url = "https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }

        # OpenCode Go models served through its OpenAI-compatible chat API.
        {
          id = "kimi-k3";
          name = "Kimi K3 (OpenCode Go)";
          vendor = "OpenCode Go";
          apiKey = "\${OPENCODE_GO_API_KEY}";
          maxInputTokens = 1048576;
          maxOutputTokens = 131072;
          url = "https://opencode.ai/zen/go/v1/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }

        # DeepSeek's native OpenAI-compatible chat API.
        {
          id = "deepseek-v4-flash";
          name = "DeepSeek V4 Flash";
          vendor = "DeepSeek";
          apiKey = "\${DEEPSEEK_API_KEY}";
          maxInputTokens = 1000000;
          maxOutputTokens = 131072;
          url = "https://api.deepseek.com/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }
        {
          id = "deepseek-v4-pro";
          name = "DeepSeek V4 Pro";
          vendor = "DeepSeek";
          apiKey = "\${DEEPSEEK_API_KEY}";
          maxInputTokens = 1000000;
          maxOutputTokens = 131072;
          url = "https://api.deepseek.com/chat/completions";
          supportsToolCall = true;
          supportsReasoning = true;
        }
      ];

      modelsJson = pkgs.writeText "workbuddy-models.json" (
        builtins.toJSON {
          inherit models;
          availableModels = map (model: model.id) models;
        }
      );
    in
    {
      # WorkBuddy reads this user-level file; keep the generated file writable
      # so WorkBuddy can update its surrounding config if needed.
      home.activation.setupWorkbuddyModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.codebuddy/models.json"
        mkdir -p "$(dirname "$cfg")"
        rm -f "$cfg"
        install -m 0600 ${modelsJson} "$cfg"
      '';

      # WorkBuddy resolves ${ENV_VAR} references when the CLI starts.
      programs.fish.shellInit = lib.mkAfter ''
        if test -r "${volcengine-codingplan-api-key.path}"
          set -gx VOLCENGINE_API_KEY (cat "${volcengine-codingplan-api-key.path}")
        end
        if test -r "${opencode-go-api-key.path}"
          set -gx OPENCODE_GO_API_KEY (cat "${opencode-go-api-key.path}")
        end
        if test -r "${deepseek-api-key.path}"
          set -gx DEEPSEEK_API_KEY (cat "${deepseek-api-key.path}")
        end
      '';

      programs.zsh.initContent = lib.mkAfter ''
        if [ -r "${volcengine-codingplan-api-key.path}" ]; then
          export VOLCENGINE_API_KEY="$(cat "${volcengine-codingplan-api-key.path}")"
        fi
        if [ -r "${opencode-go-api-key.path}" ]; then
          export OPENCODE_GO_API_KEY="$(cat "${opencode-go-api-key.path}")"
        fi
        if [ -r "${deepseek-api-key.path}" ]; then
          export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
        fi
      '';

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
        opencode-go-api-key.file = ../../secrets/opencode-go-api-key.age;
        volcengine-codingplan-api-key.file = ../../secrets/volcengine-codingplan-api-key.age;
      };
    };
}
